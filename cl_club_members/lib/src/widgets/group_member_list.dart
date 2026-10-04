import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupMembersProvider, clGroupsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

/// Displays the member list for a group.
///
/// For manual or semi-auto groups + admin: shows a remove button per member.
/// For auto groups: read-only with explanatory text.
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
            final list = Column(
              mainAxisSize: MainAxisSize.min,
              children: filtered.map((member) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onMemberTap != null
                              ? () => onMemberTap!(member)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  member.displayName,
                                  style: theme.textTheme.p,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@${member.membername}',
                                  style: theme.textTheme.muted.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isAdmin && kind != GroupKind.auto)
                        ActionButton(
                          label: 'Remove',
                          onPressed: () =>
                              removeMember(context, ref, member.membername),
                        ),
                    ],
                  ),
                );
              }).toList(),
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
