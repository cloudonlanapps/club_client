import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The dialog one credit form shows in (club_core#101): its [title], the
/// [form], Cancel and a submit button. `CreditActionForm` drives the form
/// and holds the in-flight state; this is the chrome around it.
///
/// Only Add credit from a picker's "+" chip opens this way (club_client#41);
/// inside the credit view the forms show in place, in a `CreditActionPanel`.
class CreditActionDialog extends StatelessWidget {
  const CreditActionDialog({
    required this.title,
    required this.form,
    required this.saving,
    required this.onSubmit,
    this.submitLabel = defaultSubmitLabel,
    super.key,
  });

  /// The submit button's text unless the host gives another.
  static const String defaultSubmitLabel = 'Save';

  /// The submit button's text while the action is in flight.
  static const String savingLabel = 'Saving…';

  /// The dialog's heading.
  final String title;

  /// The credit form.
  final Widget form;

  /// Whether the action is in flight: both buttons are then off, and the
  /// submit button reads [savingLabel].
  final bool saving;

  /// Validates the form and runs the action.
  final VoidCallback onSubmit;

  /// The submit button's text.
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: Text(title),
      actions: [
        ShadButton.outline(
          onPressed: saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: saving ? null : onSubmit,
          child: Text(saving ? savingLabel : submitLabel),
        ),
      ],
      child: SingleChildScrollView(child: form),
    );
  }
}
