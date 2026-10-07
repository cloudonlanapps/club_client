import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';

/// The heading of the group forms' eligibility block: its title and a line
/// on what the mode means, or on why it cannot be changed.
class GroupMembershipHeading extends StatelessWidget {
  const GroupMembershipHeading({required this.criteriaLocked, super.key});

  /// Whether the mode is locked because the group already has members.
  final bool criteriaLocked;

  /// The block's title.
  static const String title = 'Membership';

  /// The line under the title while the mode can be chosen.
  static const String modeHint =
      'Manual: add members by hand. Semi-auto / Auto: members are '
      'matched from the criteria below.';

  /// The line under the title while the mode is locked.
  static const String lockedHint =
      'Mode cannot be changed — the group already has members.';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.labelGap,
      children: [
        Text(title, style: theme.textTheme.h4),
        Text(
          criteriaLocked ? lockedHint : modeHint,
          style: theme.textTheme.muted,
        ),
      ],
    );
  }
}
