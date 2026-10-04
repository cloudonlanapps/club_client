import 'package:cl_remote_store/cl_remote_store.dart'
    show clNotificationsMasterProvider, writeFailureMessage;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/member_write_messages.dart';

/// Friendly fallback shown by the group profile when the linked group no
/// longer exists on the server.
class RemovedGroupView extends ConsumerStatefulWidget {
  const RemovedGroupView({
    required this.groupId,
    required this.onDismissed,
    this.sourceNotificationId,
    super.key,
  });

  final int groupId;
  final int? sourceNotificationId;

  /// Invoked after the stale notification is cleared. The host owns
  /// navigation away from this placeholder.
  final VoidCallback onDismissed;

  @override
  ConsumerState<RemovedGroupView> createState() => RemovedGroupViewState();
}

class RemovedGroupViewState extends ConsumerState<RemovedGroupView> {
  bool deleting = false;

  Future<void> deleteNotification() async {
    final id = widget.sourceNotificationId;
    if (id == null) return;
    setState(() => deleting = true);
    try {
      await ref
          .read(clNotificationsMasterProvider.notifier)
          .deleteNotification(id);
      if (!mounted) return;
      widget.onDismissed();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => deleting = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(e, fallback: MemberWriteMessages.dismissFailed),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNotif = widget.sourceNotificationId != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_off, size: 48),
          const SizedBox(height: 16),
          const Text('This group has been removed.'),
          const SizedBox(height: 8),
          Text(
            'Group #${widget.groupId} no longer exists on the server.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (hasNotif) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: deleting ? null : deleteNotification,
              icon: deleting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(
                deleting ? 'Deleting…' : 'Delete notification',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
