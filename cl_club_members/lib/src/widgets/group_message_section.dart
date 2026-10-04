import 'package:cl_remote_store/cl_remote_store.dart'
    show clBroadcastsMasterProvider, writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart' show ServerException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show BroadcastComposeResult, BroadcastComposer;

import '../utils/member_write_messages.dart';

/// Admin-only section for sending a free-text broadcast to a single group's
/// members. Reuses the shared [BroadcastComposer]; the audience is narrowed to
/// this group via `clBroadcastsMasterProvider.sendToGroup` (issue #737).
///
/// The host (`GroupProfileView`) decides whether to render this — it is only
/// mounted for admins / super-admins on an active group.
class GroupMessageSection extends ConsumerWidget {
  const GroupMessageSection({
    required this.groupId,
    required this.groupName,
    super.key,
  });

  final int groupId;
  final String groupName;

  Future<bool> _send(
    WidgetRef ref,
    BuildContext context,
    BroadcastComposeResult result,
  ) async {
    try {
      await ref
          .read(clBroadcastsMasterProvider.notifier)
          .sendToGroup(
            groupId,
            result.text,
            email: result.sendEmail,
            emailSubject: result.emailSubject ?? 'Message for $groupName',
          );
      if (!context.mounted) return true;
      ShadToaster.of(context).show(
        ShadToast(
          description: Text(
            result.sendEmail ? 'Message sent (with email).' : 'Message sent.',
          ),
        ),
      );
      return true;
    } on ServerException catch (e) {
      if (!context.mounted) return false;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text('Could not send: ${e.message}'),
        ),
      );
      return false;
    } on Object catch (e) {
      if (!context.mounted) return false;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(
              e,
              fallback: MemberWriteMessages.sendMessageFailed,
            ),
          ),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.megaphone,
                size: 18,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text('Message this group', style: theme.textTheme.h4),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Send an announcement to the members of "$groupName". '
            'Tick "Send email" to also deliver it by email.',
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 16),
          BroadcastComposer(
            placeholder: 'Type a message for this group…',
            onSend: (result) => _send(ref, context, result),
          ),
        ],
      ),
    );
  }
}
