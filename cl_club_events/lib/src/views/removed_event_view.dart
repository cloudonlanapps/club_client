import 'package:cl_remote_store/cl_remote_store.dart'
    show clNotificationsMasterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/event_write_messages.dart';
import '../utils/event_write_error_message.dart';

/// Friendly fallback shown by event-detail surfaces when the linked event
/// no longer exists on the server.
class RemovedEventView extends ConsumerStatefulWidget {
  const RemovedEventView({
    required this.eventId,
    required this.onDismissed,
    this.sourceNotificationId,
    super.key,
  });

  final int eventId;
  final int? sourceNotificationId;

  /// Invoked after the stale notification is cleared. The host owns
  /// navigation away from this placeholder.
  final VoidCallback onDismissed;

  @override
  ConsumerState<RemovedEventView> createState() => RemovedEventViewState();
}

class RemovedEventViewState extends ConsumerState<RemovedEventView> {
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
            eventWriteErrorMessage(
              e,
              fallback: dismissNotificationFailedMessage,
            ),
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
          const Icon(Icons.event_busy, size: 48),
          const SizedBox(height: 16),
          const Text('This event has been removed.'),
          const SizedBox(height: 8),
          Text(
            'Event #${widget.eventId} no longer exists on the server.',
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
