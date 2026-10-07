import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The two actions under the create-group form: Cancel and Create group.
/// Both are off while the create is in flight.
class GroupCreateActions extends StatelessWidget {
  const GroupCreateActions({
    required this.isSubmitting,
    required this.onCancel,
    required this.onCreate,
    super.key,
  });

  /// Whether the create is in flight.
  final bool isSubmitting;

  /// Leaves the view, asking first when the form was changed.
  final VoidCallback onCancel;

  /// Validates the form and creates the group.
  final VoidCallback onCreate;

  /// Gap between the two buttons.
  static const double buttonGap = 12;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: buttonGap,
      children: [
        ShadButton.outline(
          onPressed: isSubmitting ? null : onCancel,
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: isSubmitting ? null : onCreate,
          child: Text(isSubmitting ? 'Creating…' : 'Create group'),
        ),
      ],
    );
  }
}
