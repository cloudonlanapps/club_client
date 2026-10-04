import 'package:cl_remote_store/cl_remote_store.dart' show writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart' show ServerException;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/credit_action_error.dart';

/// Hosts one credit form in a dialog (club_core#101): Cancel and a submit
/// button, the in-flight state, and a toast when the server refuses. The
/// form stays pure UI: [validate] reads it through its key, and [onSubmit]
/// makes the call. Pops `true` once the action succeeds.
class CreditActionDialog extends StatefulWidget {
  const CreditActionDialog({
    required this.title,
    required this.form,
    required this.validate,
    required this.onSubmit,
    this.submitLabel = 'Save',
    super.key,
  });

  final String title;
  final Widget form;
  final Map<String, dynamic>? Function() validate;
  final Future<void> Function(Map<String, dynamic> values) onSubmit;
  final String submitLabel;

  @override
  State<CreditActionDialog> createState() => CreditActionDialogState();
}

class CreditActionDialogState extends State<CreditActionDialog> {
  bool saving = false;

  Future<void> submit() async {
    final values = widget.validate();
    if (values == null) return;
    setState(() => saving = true);
    try {
      await widget.onSubmit(values);
      if (mounted) Navigator.of(context).pop(true);
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text(creditActionErrorMessage(e))),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(e, fallback: creditActionSaveFailedMessage),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: Text(widget.title),
      actions: [
        ShadButton.outline(
          onPressed: saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: saving ? null : submit,
          child: Text(widget.submitLabel),
        ),
      ],
      child: SingleChildScrollView(child: widget.form),
    );
  }
}
