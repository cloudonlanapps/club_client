import 'package:cl_club_members/src/providers/group_list.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupsMasterProvider, writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/member_write_messages.dart';

/// Two-step dialog for adding a user to a group.
///
/// Step 1: Group selection grid — shows eligible manual groups with search.
/// Step 2: Confirmation — shows selected group name + confirm/cancel.
///
/// Cancel on step 2 returns to step 1. Cancel on step 1 closes the dialog.
/// Mirrors the server's add-member contract
/// (`services/group.py::add_members_bulk` + `is_eligible_for_semi_auto`):
///
/// - Manual groups: server does not criteria-check on add, so the dialog
///   does not either.
/// - Semi-auto groups: staff (admin / coach) are exempt; everyone else
///   must satisfy the group's DOB+gender criteria.
/// - Auto groups: never reach this helper — they are filtered earlier by
///   `allowsManualMembership`.
///
/// A user missing the attribute a group constrains (no DOB, no gender) is
/// excluded so the server doesn't reject the add with `notEligible`.
bool userEligibleForGroup({
  required Group group,
  required DateTime? dateOfBirthUtc,
  required Gender? gender,
  required UserRoles roles,
}) {
  if (group.kind == GroupKind.manual) return true;
  if (roles.isAdmin || roles.isCoach) return true;
  if (group.gender != null && gender != group.gender) {
    return false;
  }
  if (group.dobOnOrAfterUtc != null) {
    if (dateOfBirthUtc == null ||
        dateOfBirthUtc.isBefore(group.dobOnOrAfterUtc!)) {
      return false;
    }
  }
  if (group.dobOnOrBeforeUtc != null) {
    if (dateOfBirthUtc == null ||
        dateOfBirthUtc.isAfter(group.dobOnOrBeforeUtc!)) {
      return false;
    }
  }
  return true;
}

class AddToGroupDialog extends ConsumerStatefulWidget {
  const AddToGroupDialog({
    required this.username,
    required this.currentGroupIds,
    required this.roles,
    this.dateOfBirthUtc,
    this.gender,
    super.key,
  });

  final String username;

  /// IDs of groups the user already belongs to (excluded from selection).
  final Set<int> currentGroupIds;

  /// Target user's DOB, used to hide groups whose DOB window the user falls
  /// outside of. Null means DOB is unknown — DOB-constrained groups are
  /// hidden so the server doesn't reject the add with `notEligible`.
  final DateTime? dateOfBirthUtc;

  /// Target user's gender, used to hide gender-constrained groups that
  /// don't match. Null means gender is unknown — gender-constrained groups
  /// are hidden.
  final Gender? gender;

  /// Target user's roles. Staff (admin / coach) bypass criteria for
  /// semi-auto groups, mirroring the server's `_user_is_staff` exemption.
  final UserRoles roles;

  /// Show the dialog and return true if the user was added to a group.
  static Future<bool> show(
    BuildContext context, {
    required String username,
    required Set<int> currentGroupIds,
    required UserRoles roles,
    DateTime? dateOfBirthUtc,
    Gender? gender,
  }) async {
    final result = await showShadDialog<bool>(
      context: context,
      builder: (context) => AddToGroupDialog(
        username: username,
        currentGroupIds: currentGroupIds,
        roles: roles,
        dateOfBirthUtc: dateOfBirthUtc,
        gender: gender,
      ),
    );
    return result ?? false;
  }

  @override
  ConsumerState<AddToGroupDialog> createState() => AddToGroupDialogState();
}

class AddToGroupDialogState extends ConsumerState<AddToGroupDialog> {
  Group? selectedGroup;
  String searchTerm = '';
  bool isSubmitting = false;
  String? errorMessage;

  Future<void> handleAdd() async {
    if (selectedGroup == null) return;

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      await ref
          .read(clGroupsMasterProvider.notifier)
          .addMember(
            selectedGroup!.id,
            widget.username,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = _messageFor(e, widget.username);
        isSubmitting = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = writeFailureMessage(
          e,
          fallback: MemberWriteMessages.addToGroupFailed,
        );
        isSubmitting = false;
      });
    }
  }

  String _messageFor(ServerException e, String username) {
    switch (e.code) {
      case SdkErrorCode.notEligible:
        return "$username doesn't meet this group's criteria.";
      case SdkErrorCode.userNotFound:
        return "$username can't be added to this group.";
      case SdkErrorCode.autoGroupNotJoinable:
      case SdkErrorCode.autoGroupModificationNotAllowed:
        return 'This is an auto group — members are added automatically.';
      default:
        return 'Could not add to group: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedGroup != null) {
      return buildConfirmStep(context);
    }
    return buildGridStep(context);
  }

  Widget buildGridStep(BuildContext context) {
    final theme = ShadTheme.of(context);
    final listAsync = ref.watch(groupListProvider);

    return ShadDialog(
      title: const Text('Add to Group'),
      description: Text('Select a group for ${widget.username}.'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          ShadInput(
            placeholder: const Text('Search groups…'),
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (value) => setState(() => searchTerm = value),
          ),
          const SizedBox(height: 12),
          listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Could not load groups: $e', style: theme.textTheme.muted),
            data: (groups) {
              final eligible = groups
                  .where(
                    (g) =>
                        g.isActive &&
                        g.allowsManualMembership &&
                        !widget.currentGroupIds.contains(g.id),
                  )
                  .where(
                    (g) => userEligibleForGroup(
                      group: g,
                      dateOfBirthUtc: widget.dateOfBirthUtc,
                      gender: widget.gender,
                      roles: widget.roles,
                    ),
                  )
                  .where((g) => _matchesSearch(g, searchTerm))
                  .toList();

              if (eligible.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No eligible groups found.',
                    style: theme.textTheme.muted,
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: eligible
                        .map((group) => buildGroupTile(context, group))
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildConfirmStep(BuildContext context) {
    final theme = ShadTheme.of(context);
    final group = selectedGroup!;

    return ShadDialog(
      title: const Text('Add to Group'),
      description: Text(
        'Add ${widget.username} to "${group.name}"?',
      ),
      actions: [
        ShadButton.outline(
          onPressed: isSubmitting
              ? null
              : () => setState(() {
                  selectedGroup = null;
                  errorMessage = null;
                }),
          child: const Text('Back'),
        ),
        ShadButton(
          onPressed: isSubmitting ? null : handleAdd,
          child: Text(isSubmitting ? 'Adding…' : 'Add'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            group.name,
            style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
          ),
          if (group.description != null && group.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(group.description!, style: theme.textTheme.muted),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: theme.textTheme.muted.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildGroupTile(BuildContext context, Group group) {
    final theme = ShadTheme.of(context);

    return GestureDetector(
      onTap: () => setState(() => selectedGroup = group),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            group.name,
            style: theme.textTheme.small,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  bool _matchesSearch(Group group, String term) {
    if (term.isEmpty) return true;
    final lower = term.toLowerCase();
    return group.name.toLowerCase().contains(lower) ||
        (group.description?.toLowerCase().contains(lower) ?? false);
  }
}
