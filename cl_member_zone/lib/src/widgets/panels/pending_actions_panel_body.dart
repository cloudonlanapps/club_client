import 'package:cl_club_communication/cl_club_communication.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorView;

import 'dashboard_event_nav.dart';

/// Pending Actions panel body — renders up to [_panelLimit] most recent
/// actionable notifications, with a right-aligned "See more" ghost button
/// to the full list. Per-row action buttons live on the list screen; the
/// panel itself is a glance summary.
class PendingActionsPanelBody extends ConsumerWidget {
  const PendingActionsPanelBody({super.key});

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
    final async = ref.watch(clPendingActionsMasterProvider);

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
          title: 'Could not load pending actions',
          errorCode: '$e',
          onHome: nav.onHome,
          onRetry: () =>
              ref.read(clPendingActionsMasterProvider.notifier).refresh(),
        ),
        data: (map) {
          if (map.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'Nothing pending',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ShadButton.ghost(
                    onPressed: nav.onSeeMorePendingActions,
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
                      onTap: () {
                        final link = resolveDeepLink(
                          n,
                          currentUsername: user.username,
                        );
                        if (link != null) {
                          nav.onNotificationDeepLink(link);
                        } else {
                          nav.onSeeMorePendingActions();
                        }
                      },
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ShadButton.ghost(
                  onPressed: nav.onSeeMorePendingActions,
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
