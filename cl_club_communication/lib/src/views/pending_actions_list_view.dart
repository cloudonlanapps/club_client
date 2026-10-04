import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorView, TitleRow;

import '../utils/notification_deep_link.dart';
import '../widgets/notification_row.dart';
import '../widgets/pending_action_trailing.dart';

/// Full-list pending actions view at `/memberzone/pending-actions`.
class PendingActionsListView extends ConsumerWidget {
  const PendingActionsListView({
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final async = ref.watch(clPendingActionsMasterProvider);

    return Column(
      children: [
        TitleRow(title: 'Pending actions', onBack: onBack),
        const Divider(height: 1),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(
              title: 'Could not load pending actions',
              errorCode: '$e',
              onHome: onHome,
              onRetry: () =>
                  ref.read(clPendingActionsMasterProvider.notifier).refresh(),
            ),
            data: (map) {
              if (map.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(clPendingActionsMasterProvider.notifier)
                      .refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                          child: Text(
                            'Nothing pending.',
                            style: theme.textTheme.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final sorted = map.values.toList()
                ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(clPendingActionsMasterProvider.notifier).refresh(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = sorted[index];
                    return NotificationRow(
                      notification: n,
                      onTap: () {
                        final link = resolveDeepLink(
                          n,
                          currentUsername: currentUser.username,
                        );
                        if (link != null) onDeepLink(link);
                      },
                      trailing: PendingActionTrailing(
                        notification: n,
                        currentUsername: currentUser.username,
                        onOpen: onDeepLink,
                      ),
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
