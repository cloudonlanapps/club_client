import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/notification_filter.dart';
import '../providers/notification_filter.dart';
import '../utils/notification_filter_labels.dart';

/// Filter bar rendered above the notification list on the full screen.
///
/// Two controls — read state (All / Unread) and a three-bucket type
/// classification (Info / Action Pending / Broadcast, plus All) — backed by
/// [notificationFilterProvider]. Filters are applied client-side over the
/// already-loaded master state; no server round-trip.
class NotificationFilterBar extends ConsumerWidget {
  const NotificationFilterBar({super.key});

  Widget readSegmentButton({
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    if (selected) {
      return ShadButton(
        size: ShadButtonSize.sm,
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: onPressed,
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final filter = ref.watch(notificationFilterProvider);
    final notifier = ref.read(notificationFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              readSegmentButton(
                label: 'All',
                selected: filter.read == NotificationReadFilter.all,
                onPressed: () => notifier.setRead(NotificationReadFilter.all),
              ),
              const SizedBox(width: 4),
              readSegmentButton(
                label: 'Unread',
                selected: filter.read == NotificationReadFilter.unread,
                onPressed: () =>
                    notifier.setRead(NotificationReadFilter.unread),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type', style: theme.textTheme.muted),
              const SizedBox(width: 8),
              ShadSelect<NotificationTypeFilter>(
                initialValue: filter.type,
                options: const [
                  ShadOption(
                    value: NotificationTypeFilter.all,
                    child: Text('All'),
                  ),
                  ShadOption(
                    value: NotificationTypeFilter.info,
                    child: Text('Info'),
                  ),
                  ShadOption(
                    value: NotificationTypeFilter.actionPending,
                    child: Text('Action Pending'),
                  ),
                  ShadOption(
                    value: NotificationTypeFilter.broadcast,
                    child: Text('Broadcast'),
                  ),
                ],
                selectedOptionBuilder: (context, value) {
                  return Text(notificationTypeLabel(value));
                },
                onChanged: (value) {
                  if (value != null) notifier.setType(value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
