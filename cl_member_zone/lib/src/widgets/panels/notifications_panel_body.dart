import 'package:cl_club_communication/cl_club_communication.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorView;

import 'dashboard_event_nav.dart';

/// Notifications panel body — renders up to [_panelLimit] most recent
/// notifications for the logged-in user, with a right-aligned "See more"
/// ghost button that opens the full list screen.
class NotificationsPanelBody extends ConsumerWidget {
  const NotificationsPanelBody({super.key});

  static const int _panelLimit = 5;
  static const double _bodyHeight = 296;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const SizedBox(
        height: _bodyHeight,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final nav = DashboardEventNav.of(context);
    final async = ref.watch(unifiedNotificationsProvider);

    return SizedBox(
      height: _bodyHeight,
      child: async.when(
        loading: () => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => ErrorView(
          title: 'Could not load notifications',
          errorCode: '$e',
          onHome: nav.onHome,
          onRetry: () =>
              ref.read(clNotificationsMasterProvider.notifier).refresh(),
        ),
        data: (unified) {
          // Drop notifications whose pending action has been resolved
          // server-side — they'd render without a trailing action and
          // are just informational clutter. Mirrors the same filter in
          // `notifications_list_view.dart`.
          final map = <int, AppNotification>{
            for (final entry in unified.byId.entries)
              if (entry.value.pendingActionType == null ||
                  unified.unresolvedIds.contains(entry.key))
                entry.key: entry.value,
          };
          if (map.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'No notifications',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ShadButton.ghost(
                    onPressed: nav.onSeeMoreNotifications,
                    child: const Text('See more'),
                  ),
                ),
              ],
            );
          }

          final sorted = map.values.toList()
            ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
          final visible = sorted.take(_panelLimit).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = visible[index];
                    return NotificationRow(
                      notification: n,
                      onTap: () => markReadThenOpen(context, ref, n.id, () {
                        final link = resolveDeepLink(
                          n,
                          currentUsername: user.username,
                        );
                        if (link != null) {
                          nav.onNotificationDeepLink(link);
                        }
                      }),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ShadButton.ghost(
                  onPressed: nav.onSeeMoreNotifications,
                  child: const Text('See more'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
