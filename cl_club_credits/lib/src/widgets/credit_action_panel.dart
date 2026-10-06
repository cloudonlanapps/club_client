import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/credit_action_runner.dart';

/// Hosts one credit form in place, inside the credit view (club_client#41):
/// its [title], the form, then Cancel and a submit button, with the
/// in-flight state and a toast when the server refuses. Nothing is pushed
/// over the view. The form stays pure UI: [validate] reads it through its
/// key, and [onSubmit] makes the call. [onClose] runs on Cancel and once
/// the action succeeded.
class CreditActionPanel extends StatefulWidget {
  const CreditActionPanel({
    required this.title,
    required this.form,
    required this.validate,
    required this.onSubmit,
    required this.onClose,
    this.submitLabel = 'Save',
    super.key,
  });

  final String title;
  final Widget form;
  final Map<String, dynamic>? Function() validate;
  final Future<void> Function(Map<String, dynamic> values) onSubmit;
  final VoidCallback onClose;
  final String submitLabel;

  @override
  State<CreditActionPanel> createState() => CreditActionPanelState();
}

class CreditActionPanelState extends State<CreditActionPanel> {
  bool saving = false;

  Future<void> submit() async {
    final values = widget.validate();
    if (values == null) return;
    setState(() => saving = true);
    final done = await runCreditAction(context, () => widget.onSubmit(values));
    if (!mounted) return;
    setState(() => saving = false);
    if (done) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Text(widget.title, style: ShadTheme.of(context).textTheme.large),
        widget.form,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            ShadButton.outline(
              onPressed: saving ? null : widget.onClose,
              child: const Text('Cancel'),
            ),
            ShadButton(
              onPressed: saving ? null : submit,
              child: Text(widget.submitLabel),
            ),
          ],
        ),
      ],
    );
  }
}
