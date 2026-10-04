import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorView, TitleRow;

import '../models/notification_filter.dart';
import '../providers/notification_filter.dart';
import '../providers/unified_notifications.dart';
import '../utils/notification_deep_link.dart';
import '../utils/notification_filter_apply.dart';
import '../utils/notification_writes.dart';
import '../widgets/notification_filter_bar.dart';
import '../widgets/notification_row.dart';
import '../widgets/pending_action_trailing.dart';

/// Full-list notifications view at `/memberzone/notifications`.
class NotificationsListView extends ConsumerWidget {
  const NotificationsListView({
    required this.currentUser,
    required this.onDeepLink,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final void Function(NotificationDeepLink link) onDeepLink;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  Future<void> _refreshAll(WidgetRef ref) async {
    await Future.wait([
      ref.read(clNotificationsMasterProvider.notifier).refresh(),
      ref.read(clPendingActionsMasterProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final async = ref.watch(unifiedNotificationsProvider);
    final filter = ref.watch(notificationFilterProvider);

    return Column(
      children: [
        TitleRow(title: 'Notifications', onBack: onBack),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              const Expanded(child: NotificationFilterBar()),
              ShadButton.ghost(
                onPressed: () => markAllReadReporting(context, ref),
                child: const Text('Mark all read'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(
              title: 'Could not load notifications',
              errorCode: '$e',
              onHome: onHome,
              onRetry: () => _refreshAll(ref),
            ),
            data: (unified) {
              // Drop notifications that were originally pending actions
              // but whose action is now resolved (no longer in
              // `unresolvedIds`). These render with no trailing button,
              // so they're informational dead weight — match the
              // button's vanish-on-resolve behaviour at the row level.
              final filteredById = <int, AppNotification>{
                for (final entry in unified.byId.entries)
                  if (entry.value.pendingActionType == null ||
                      unified.unresolvedIds.contains(entry.key))
                    entry.key: entry.value,
              };
              final visible = applyNotificationFilter(filteredById, filter);
              if (visible.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => _refreshAll(ref),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                          child: Text(
                            _emptyMessage(
                              filter,
                              mapIsEmpty: unified.byId.isEmpty,
                            ),
                            style: theme.textTheme.muted,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => _refreshAll(ref),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = visible[index];
                    final isUnresolvedPendingAction =
                        n.pendingActionType != null &&
                        unified.unresolvedIds.contains(n.id);
                    return NotificationRow(
                      notification: n,
                      trailing: isUnresolvedPendingAction
                          ? PendingActionTrailing(
                              notification: n,
                              currentUsername: currentUser.username,
                              onOpen: onDeepLink,
                            )
                          : null,
                      onTap: () => markReadThenOpen(context, ref, n.id, () {
                        final link = resolveDeepLink(
                          n,
                          currentUsername: currentUser.username,
                        );
                        if (link != null) onDeepLink(link);
                      }),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _emptyMessage(NotificationFilter filter, {required bool mapIsEmpty}) {
  if (mapIsEmpty) return 'No notifications.';
  return 'No notifications match the current filters.';
}
