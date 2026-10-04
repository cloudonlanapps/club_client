import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for the logged-in user's pending-action feed.
///
/// Wraps `client.notifications.listPendingActions`. The server already
/// auto-dismisses entries once the linked domain row reaches a terminal
/// state, so the local map only needs to be updated on explicit user
/// action; `dismissLocally` is the helper widgets call after a successful
/// approve / reject / accept / decline.
final AsyncNotifierProvider<
  ClPendingActionsMasterNotifier,
  Map<int, AppNotification>
>
clPendingActionsMasterProvider =
    AsyncNotifierProvider<
      ClPendingActionsMasterNotifier,
      Map<int, AppNotification>
    >(ClPendingActionsMasterNotifier.new);

class ClPendingActionsMasterNotifier
    extends AsyncNotifier<Map<int, AppNotification>> {
  @override
  Future<Map<int, AppNotification>> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return {};
    ref.watch(clManualRefreshProvider);
    final client = await ref.watch(secureClientProvider.future);
    final items = await fetchAllPages(
      client.notifications.listPendingActions,
    );
    return {for (final n in items) n.id: n};
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Drop a notification from local state after the underlying domain
  /// action has been resolved elsewhere. The server auto-dismisses on its
  /// own — this just keeps the UI snappy without waiting for a refetch.
  void dismissLocally(int notificationId) {
    final current = state.valueOrNull;
    if (current == null || !current.containsKey(notificationId)) return;
    final next = {...current}..remove(notificationId);
    state = AsyncData(next);
  }
}
