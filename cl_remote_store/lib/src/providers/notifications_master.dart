import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for the logged-in user's notifications feed.
///
/// Holds `Map<int, AppNotification>` keyed by notification id. The first
/// build fetches the most recent page via `getNotifications`; `loadMore`
/// appends older pages. `markRead`, `markAllRead`, and `deleteNotification`
/// update local state optimistically and call the server in the background.
final AsyncNotifierProvider<
  ClNotificationsMasterNotifier,
  Map<int, AppNotification>
>
clNotificationsMasterProvider =
    AsyncNotifierProvider<
      ClNotificationsMasterNotifier,
      Map<int, AppNotification>
    >(ClNotificationsMasterNotifier.new);

/// Number of currently-loaded notifications that are unread. Returns 0 while
/// the master is loading or has errored — surfaces (sidebar badge, top-bar
/// bell dot) just hide their indicator in that case.
final Provider<int> unreadNotificationCountProvider = Provider<int>((ref) {
  final master = ref.watch(clNotificationsMasterProvider);
  final map = master.valueOrNull;
  if (map == null) return 0;
  var n = 0;
  for (final entry in map.values) {
    if (!entry.isRead) n++;
  }
  return n;
});

class ClNotificationsMasterNotifier
    extends AsyncNotifier<Map<int, AppNotification>> {
  @override
  Future<Map<int, AppNotification>> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return {};
    ref.watch(clManualRefreshProvider);
    final client = await ref.watch(secureClientProvider.future);
    final items = await fetchAllPages(client.notifications.getNotifications);
    return {for (final n in items) n.id: n};
  }

  /// Re-fetch every page from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Mark a single notification as read. Optimistic; reverts on failure,
  /// and reloads when the write may have landed (club_core#138).
  Future<void> markRead(int id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final existing = current[id];
    if (existing == null || existing.isRead) return;
    state = AsyncData({
      ...current,
      id: existing.copyWith(isRead: true),
    });
    try {
      final client = await ref.read(secureClientProvider.future);
      await client.notifications.markRead(id);
    } catch (e) {
      state = AsyncData({...current});
      if (writeMayHaveLanded(e)) ref.invalidateSelf();
      rethrow;
    }
  }

  /// Mark every loaded notification as read. Optimistic; reverts on failure.
  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = <int, AppNotification>{
      for (final entry in current.entries)
        entry.key: entry.value.copyWith(isRead: true),
    };
    state = AsyncData(updated);
    try {
      final client = await ref.read(secureClientProvider.future);
      await client.notifications.markAllRead();
    } catch (e) {
      state = AsyncData({...current});
      if (writeMayHaveLanded(e)) ref.invalidateSelf();
      rethrow;
    }
  }

  /// Soft-delete a notification. Optimistic; reverts on failure.
  Future<void> deleteNotification(int id) async {
    final current = state.valueOrNull;
    if (current == null || !current.containsKey(id)) return;
    final next = {...current}..remove(id);
    state = AsyncData(next);
    try {
      final client = await ref.read(secureClientProvider.future);
      await client.notifications.deleteNotification(id);
    } catch (e) {
      state = AsyncData(current);
      if (writeMayHaveLanded(e)) ref.invalidateSelf();
      rethrow;
    }
  }
}
