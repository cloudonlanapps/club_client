import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/credit_action_runner.dart';

/// Hosts one credit form in a dialog (club_core#101): Cancel and a submit
/// button, the in-flight state, and a toast when the server refuses. The
/// form stays pure UI: [validate] reads it through its key, and [onSubmit]
/// makes the call. Pops `true` once the action succeeds.
///
/// Only Add credit from a picker's "+" chip opens this way (club_client#41);
/// inside the credit view the forms show in place, in a `CreditActionPanel`.
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
    final done = await runCreditAction(context, () => widget.onSubmit(values));
    if (!mounted) return;
    setState(() => saving = false);
    if (done) Navigator.of(context).pop(true);
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
