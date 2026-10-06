import 'package:cl_club_members/src/widgets/cards/group_card.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem;

/// The rows of a user's Groups section: one [GroupCard] per group.
///
/// A group named in [ineligibleIds] (the server reports the user as no
/// longer meeting its criteria) is marked in its row, such rows come first,
/// and a line above the list says how many there are (club_client#43).
class UserGroupsList extends StatelessWidget {
  const UserGroupsList({
    required this.groups,
    this.ineligibleIds = const {},
    this.onGroupTap,
    this.canRemove = false,
    this.removeEnabled = true,
    this.onRemove,
    super.key,
  });

  /// The groups the user belongs to, in the server's order.
  final List<Group> groups;

  /// Ids of the groups the user no longer matches.
  final Set<int> ineligibleIds;

  /// Called when a row is tapped. `null` leaves the rows inert.
  final void Function(Group group)? onGroupTap;

  /// Whether the viewer may remove the user from a group. The action shows
  /// only on a group that takes manual removal.
  final bool canRemove;

  /// False greys the Remove actions out while a removal is in flight.
  final bool removeEnabled;

  /// Removes the user from a group.
  final void Function(Group group)? onRemove;

  /// Label of a row's Remove action.
  static const String removeLabel = 'Remove';

  /// Space under each row and under the count line.
  static const double rowGap = 8;

  /// How many of the user's groups the user no longer matches, as the line
  /// above the list reads.
  static String ineligibleCountText(int count) => count == 1
      ? '1 group no longer matches this member'
      : '$count groups no longer match this member';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    // Ineligible first; each half keeps the server's order.
    final ordered = [
      ...groups.where((g) => ineligibleIds.contains(g.id)),
      ...groups.where((g) => !ineligibleIds.contains(g.id)),
    ];
    final ineligibleCount = groups
        .where((g) => ineligibleIds.contains(g.id))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ineligibleCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: rowGap),
            child: Text(
              ineligibleCountText(ineligibleCount),
              style: theme.textTheme.small,
            ),
          ),
        for (final group in ordered)
          Padding(
            padding: const EdgeInsets.only(bottom: rowGap),
            child: GroupCard(
              key: ValueKey(group.id),
              groupId: group.id,
              memberEligible: !ineligibleIds.contains(group.id),
              onTap: onGroupTap != null ? () => onGroupTap!(group) : null,
              trailing: canRemove && group.allowsManualMembership
                  ? [
                      ActionItem(
                        label: removeLabel,
                        onPressed: removeEnabled && onRemove != null
                            ? () => onRemove!(group)
                            : null,
                      ),
                    ]
                  : null,
            ),
          ),
      ],
    );
  }
}
