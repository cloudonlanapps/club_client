import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';

/// The heading of the group forms' eligibility block: its title and a line
/// on what the mode means.
class GroupMembershipHeading extends StatelessWidget {
  const GroupMembershipHeading({super.key});

  /// The block's title.
  static const String title = 'Membership';

  /// The line under the title.
  static const String modeHint =
      'Manual: add members by hand. Semi-auto / Auto: members are '
      'matched from the criteria below.';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.labelGap,
      children: [
        Text(title, style: theme.textTheme.h4),
        Text(modeHint, style: theme.textTheme.muted),
      ],
    );
  }
}
