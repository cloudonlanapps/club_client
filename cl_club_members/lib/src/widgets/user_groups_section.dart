import 'package:cl_club_members/src/utils/admin_user_actions.dart';
import 'package:cl_club_members/src/widgets/add_to_group_dialog.dart';
import 'package:cl_club_members/src/widgets/cards/group_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupsMasterProvider, clUserGroupsProvider, clUserPrivateProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, ActionItem;

/// Displays group memberships for a given user.
///
/// Admin can add to manual groups and remove from manual groups.
class UserGroupsSection extends ConsumerStatefulWidget {
  const UserGroupsSection({
    required this.username,
    this.showCard = true,
    this.onGroupTap,
    super.key,
  });

  final String username;
  final bool showCard;

  /// Called when tapping a group name. If null, names are not tappable.
  final void Function(Group group)? onGroupTap;

  @override
  ConsumerState<UserGroupsSection> createState() => UserGroupsSectionState();
}

class UserGroupsSectionState extends ConsumerState<UserGroupsSection> {
  bool isSubmitting = false;

  Future<void> removeFromGroup(Group group) async {
    setState(() => isSubmitting = true);
    try {
      await ref
          .read(clGroupsMasterProvider.notifier)
          .removeMember(
            group.id,
            widget.username,
          );
      ref.invalidate(clUserGroupsProvider(widget.username));
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast(description: Text('Removed from "${group.name}".')),
      );
    } on Object catch (_) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not remove from group.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> handleAddToGroup(
    Set<int> currentGroupIds,
    UserPrivate targetUser,
  ) async {
    final added = await AddToGroupDialog.show(
      context,
      username: widget.username,
      currentGroupIds: currentGroupIds,
      dateOfBirthUtc: targetUser.dateOfBirthUtc,
      gender: targetUser.gender,
      roles: targetUser.roles,
    );
    if (added) {
      ref.invalidate(clUserGroupsProvider(widget.username));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final auth = ref.watch(authStateProvider).valueOrNull;
    final isAdmin = auth?.isAdmin ?? false;
    final targetUser = ref
        .watch(clUserPrivateProvider(widget.username))
        .valueOrNull;
    final canAdd = isAdmin && targetUser != null && canMutateUser(targetUser);
    final groupsAsync = ref.watch(clUserGroupsProvider(widget.username));

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Groups', style: theme.textTheme.h4)),
            if (canAdd)
              groupsAsync.whenOrNull(
                    data: (groups) => ActionButton(
                      label: '+ Add to Group',
                      enabled: !isSubmitting,
                      onPressed: () => handleAddToGroup(
                        groups.map((g) => g.id).toSet(),
                        targetUser,
                      ),
                    ),
                  ) ??
                  const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Groups this user belongs to.',
          style: theme.textTheme.muted,
        ),
        const SizedBox(height: 12),
        groupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            'Could not load groups: $e',
            style: theme.textTheme.muted,
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return Text(
                'Not a member of any group.',
                style: theme.textTheme.muted,
              );
            }
            return Column(
              children: groups.map((group) {
                final canRemove = isAdmin && group.allowsManualMembership;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GroupCard(
                    groupId: group.id,
                    onTap: widget.onGroupTap != null
                        ? () => widget.onGroupTap!(group)
                        : null,
                    trailing: canRemove
                        ? [
                            ActionItem(
                              label: 'Remove',
                              onPressed: isSubmitting
                                  ? null
                                  : () => removeFromGroup(group),
                            ),
                          ]
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );

    if (!widget.showCard) return content;
    return ShadCard(padding: const EdgeInsets.all(20), child: content);
  }
}
