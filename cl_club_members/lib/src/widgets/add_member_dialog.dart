import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEligibleUsersProvider,
        clGroupMembersProvider,
        clGroupsMasterProvider,
        clUsersMasterProvider,
        writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PickerUser, showUserSelectionDialog;

import '../utils/member_write_messages.dart';

/// Wires the shared multi-select user picker (from ui_lib) to the group's
/// eligible-users provider and `addMembersBulk`. The picker handles the
/// selection step; this helper performs the bulk add and surfaces the
/// per-user outcome (added / already-members / not-found / not-eligible)
/// as a follow-up dialog.
class AddMemberDialog {
  const AddMemberDialog._();

  /// Returns true if at least one member was added.
  static Future<bool> show(
    BuildContext context, {
    required int groupId,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final eligible = await container.read(
      clEligibleUsersProvider(groupId).future,
    );
    final userMaster = await container.read(clUsersMasterProvider.future);
    if (!context.mounted) return false;

    final picked = await showUserSelectionDialog(
      context,
      title: 'Add Members',
      description:
          "Select one or more users. Only users who satisfy the group's "
          'criteria are shown.',
      confirmLabel: 'Add',
      emptyText: 'No eligible users for this group.',
      users: [
        for (final u in eligible)
          PickerUser(
            username: u.username,
            displayName: _displayName(u),
            firstName: u.firstName,
            lastName: u.lastName,
            nickname: u.nickname,
            isAdmin: userMaster[u.username]?.roles.isAdmin ?? false,
            isCoach: userMaster[u.username]?.roles.isCoach ?? false,
          ),
      ],
    );
    if (picked == null || picked.isEmpty || !context.mounted) return false;

    final BulkMembersResult outcome;
    try {
      outcome = await container
          .read(clGroupsMasterProvider.notifier)
          .addMembersBulk(groupId, picked);
      container
        ..invalidate(clGroupMembersProvider(groupId))
        ..invalidate(clEligibleUsersProvider(groupId));
    } on ServerException catch (e) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Could not add members: ${e.message}'),
          ),
        );
      }
      return false;
    } on Object catch (e) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text(
              writeFailureMessage(
                e,
                fallback: MemberWriteMessages.addMembersFailed,
              ),
            ),
          ),
        );
      }
      return false;
    }

    if (!context.mounted) return outcome.added.isNotEmpty;
    await _showOutcome(context, outcome);
    return outcome.added.isNotEmpty;
  }

  static String _displayName(EligibleUser u) {
    final first = u.firstName?.trim() ?? '';
    final last = u.lastName?.trim() ?? '';
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;
    if ((u.nickname ?? '').trim().isNotEmpty) return u.nickname!.trim();
    return u.username;
  }

  static Future<void> _showOutcome(
    BuildContext context,
    BulkMembersResult outcome,
  ) {
    return showShadDialog<void>(
      context: context,
      builder: (_) => AddMemberResultDialog(outcome: outcome),
    );
  }
}

class AddMemberResultDialog extends StatelessWidget {
  const AddMemberResultDialog({required this.outcome, super.key});

  final BulkMembersResult outcome;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadDialog(
      title: const Text('Add Members'),
      description: Text(
        outcome.added.isEmpty
            ? 'No members were added.'
            : '${outcome.added.length} member'
                  "${outcome.added.length == 1 ? '' : 's'} added.",
      ),
      actions: [
        ShadButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          if (outcome.added.isNotEmpty)
            ResultGroup(theme: theme, label: 'Added', usernames: outcome.added),
          if (outcome.alreadyMembers.isNotEmpty)
            ResultGroup(
              theme: theme,
              label: 'Already members',
              usernames: outcome.alreadyMembers,
            ),
          if (outcome.notEligible.isNotEmpty)
            ResultGroup(
              theme: theme,
              label: 'Not eligible',
              usernames: outcome.notEligible,
            ),
          if (outcome.notFound.isNotEmpty)
            ResultGroup(
              theme: theme,
              label: 'Not found',
              usernames: outcome.notFound,
            ),
        ],
      ),
    );
  }
}

class ResultGroup extends StatelessWidget {
  const ResultGroup({
    required this.theme,
    required this.label,
    required this.usernames,
    super.key,
  });

  final ShadThemeData theme;
  final String label;
  final List<String> usernames;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.small),
          const SizedBox(height: 4),
          Text(
            usernames.map((u) => '@$u').join(', '),
            style: theme.textTheme.p,
          ),
        ],
      ),
    );
  }
}
