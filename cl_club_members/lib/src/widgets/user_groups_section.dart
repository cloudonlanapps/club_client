import 'package:cl_club_members/src/utils/admin_user_actions.dart';
import 'package:cl_club_members/src/widgets/add_to_group_dialog.dart';
import 'package:cl_club_members/src/widgets/user_groups_list.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clGroupsMasterProvider,
        clUserGroupsProvider,
        clUserIneligibleGroupIdsProvider,
        clUserPrivateProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

/// Displays group memberships for a given user.
///
/// Admin can add to manual groups and remove from manual groups.
///
/// For staff, a group the server reports the user as no longer meeting the
/// criteria of is marked in its row, such rows come first, and the section
/// says how many there are (club_client#43).
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
    // A group's member list, which carries the flag, is a staff read.
    final isStaff = auth?.isCoachOrAdmin ?? false;
    final ineligibleIds = isStaff
        ? ref
                  .watch(clUserIneligibleGroupIdsProvider(widget.username))
                  .valueOrNull ??
              const <int>{}
        : const <int>{};

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
            return UserGroupsList(
              groups: groups,
              ineligibleIds: ineligibleIds,
              onGroupTap: widget.onGroupTap,
              canRemove: isAdmin,
              removeEnabled: !isSubmitting,
              onRemove: removeFromGroup,
            );
          },
        ),
      ],
    );

    if (!widget.showCard) return content;
    return ShadCard(padding: const EdgeInsets.all(20), child: content);
  }
}
