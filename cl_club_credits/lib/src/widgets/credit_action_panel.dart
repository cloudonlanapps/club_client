import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One credit form shown in place, inside the credit view (club_client#41):
/// its [title], the [form], then Cancel and a submit button. Nothing is
/// pushed over the view. `CreditActionForm` drives the form and holds the
/// in-flight state; this is the chrome around it.
class CreditActionPanel extends StatelessWidget {
  const CreditActionPanel({
    required this.title,
    required this.form,
    required this.saving,
    required this.onSubmit,
    required this.onClose,
    this.submitLabel = defaultSubmitLabel,
    super.key,
  });

  /// The submit button's text unless the host gives another.
  static const String defaultSubmitLabel = 'Save';

  /// The submit button's text while the action is in flight.
  static const String savingLabel = 'Saving…';

  /// Gap between the heading, the form and the buttons.
  static const double sectionGap = 16;

  /// Gap between the two buttons.
  static const double buttonGap = 8;

  /// The panel's heading.
  final String title;

  /// The credit form.
  final Widget form;

  /// Whether the action is in flight: both buttons are then off, and the
  /// submit button reads [savingLabel].
  final bool saving;

  /// Validates the form and runs the action.
  final VoidCallback onSubmit;

  /// Closes the panel, on Cancel.
  final VoidCallback onClose;

  /// The submit button's text.
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: sectionGap,
      children: [
        Text(title, style: ShadTheme.of(context).textTheme.large),
        form,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: buttonGap,
          children: [
            ShadButton.outline(
              onPressed: saving ? null : onClose,
              child: const Text('Cancel'),
            ),
            ShadButton(
              onPressed: saving ? null : onSubmit,
              child: Text(saving ? savingLabel : submitLabel),
            ),
          ],
        ),
      ],
    );
  }
}
