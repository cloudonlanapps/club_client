import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupMembersProvider, clGroupsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'group_member_row.dart';

/// Displays the member list for a group.
///
/// For manual or semi-auto groups + admin: shows a remove button per member.
/// For auto groups: read-only with explanatory text.
///
/// A semi-auto member the server reports as no longer eligible is marked in
/// its row ([GroupMemberRow]), and the list says how many there are.
///
/// When [maxHeight] is set, the list is bounded and scrolls internally.
/// When [onOpenAll] is provided, an "open full list" icon is shown next to
/// the heading.
class GroupMemberList extends ConsumerWidget {
  const GroupMemberList({
    required this.groupId,
    required this.kind,
    this.isAdmin = false,
    this.onMemberTap,
    this.maxHeight,
    this.onOpenAll,
    this.searchTerm,
    super.key,
  });

  final int groupId;
  final GroupKind kind;
  final bool isAdmin;
  final void Function(GroupMember member)? onMemberTap;
  final double? maxHeight;
  final VoidCallback? onOpenAll;

  /// Optional case-insensitive substring filter applied to each member's
  /// display name and username. When null or empty, no filtering happens.
  final String? searchTerm;

  /// How many of the group's members no longer meet its criteria, as the
  /// line above the list reads.
  static String ineligibleCountText(int count) => count == 1
      ? '1 member no longer eligible'
      : '$count members no longer eligible';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final membersAsync = ref.watch(clGroupMembersProvider(groupId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Members', style: theme.textTheme.h4),
            const SizedBox(width: 8),
            if (onOpenAll != null)
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  onPressed: onOpenAll,
                  icon: Icon(
                    LucideIcons.squareArrowOutUpRight,
                    size: 14,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  tooltip: 'Open full list',
                  iconSize: 14,
                  padding: EdgeInsets.zero,
                ),
              ),
            const Spacer(),
            if (kind == GroupKind.auto)
              Text(
                'Computed automatically',
                style: theme.textTheme.muted,
              ),
          ],
        ),
        const SizedBox(height: 8),
        membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            'Could not load members: $e',
            style: theme.textTheme.muted,
          ),
          data: (members) {
            if (members.isEmpty) {
              return Text('No members.', style: theme.textTheme.muted);
            }
            final term = searchTerm?.trim().toLowerCase() ?? '';
            final filtered = term.isEmpty
                ? members
                : members
                      .where(
                        (m) =>
                            m.displayName.toLowerCase().contains(term) ||
                            m.membername.toLowerCase().contains(term),
                      )
                      .toList();
            if (filtered.isEmpty) {
              return Text(
                'No members match your search.',
                style: theme.textTheme.muted,
              );
            }
            final ineligibleCount = members.where((m) => !m.eligible).length;
            final rows = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final member in filtered)
                  GroupMemberRow(
                    member: member,
                    onTap: onMemberTap != null
                        ? () => onMemberTap!(member)
                        : null,
                    onRemove: isAdmin && kind != GroupKind.auto
                        ? () => removeMember(context, ref, member.membername)
                        : null,
                  ),
              ],
            );
            final list = ineligibleCount == 0
                ? rows
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Text(
                        ineligibleCountText(ineligibleCount),
                        style: theme.textTheme.muted,
                      ),
                      rows,
                    ],
                  );
            if (maxHeight == null) return list;
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight!),
              child: SingleChildScrollView(child: list),
            );
          },
        ),
      ],
    );
  }

  Future<void> removeMember(
    BuildContext context,
    WidgetRef ref,
    String username,
  ) async {
    try {
      await ref
          .read(clGroupsMasterProvider.notifier)
          .removeMember(
            groupId,
            username,
          );
      ref.invalidate(clGroupMembersProvider(groupId));
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast(description: Text('Removed $username from group.')),
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not remove member.'),
        ),
      );
    }
  }
}
