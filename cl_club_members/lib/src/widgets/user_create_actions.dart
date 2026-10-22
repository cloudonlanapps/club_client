import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The actions under the create-user form: Cancel and Create user.
class UserCreateActions extends StatelessWidget {
  const UserCreateActions({
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
    super.key,
  });

  /// Label of the action that leaves without creating.
  static const String cancelLabel = 'Cancel';

  /// Label of the action that creates the user.
  static const String submitLabel = 'Create user';

  /// Label of the create action while it runs.
  static const String submittingLabel = 'Creating…';

  /// Between the two actions.
  static const double gap = 12;

  /// Whether the creation is in flight; turns both actions off.
  final bool isSubmitting;

  /// Leaves the view, asking first when the form holds changes.
  final VoidCallback onCancel;

  /// Validates the form and creates the user.
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: gap,
      children: [
        ShadButton.outline(
          onPressed: isSubmitting ? null : onCancel,
          child: const Text(cancelLabel),
        ),
        ShadButton(
          onPressed: isSubmitting ? null : onSubmit,
          child: Text(isSubmitting ? submittingLabel : submitLabel),
        ),
      ],
    );
  }
}
