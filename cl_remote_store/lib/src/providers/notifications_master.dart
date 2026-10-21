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

  /// Mark a single notification as read. Optimistic; on failure only this
  /// notification goes back to unread, in the state as it is then
  /// (club_client#235), and the feed reloads when the write may have landed
  /// (club_core#138).
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
      _restore({id: existing});
      if (writeMayHaveLanded(e)) ref.invalidateSelf();
      rethrow;
    }
  }

  /// Mark every loaded notification as read. Optimistic; on failure only
  /// the notifications this call marked go back to unread, in the state as
  /// it is then (club_client#235).
  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final marked = <int, AppNotification>{
      for (final entry in current.entries)
        if (!entry.value.isRead) entry.key: entry.value,
    };
    state = AsyncData({
      ...current,
      for (final entry in marked.entries)
        entry.key: entry.value.copyWith(isRead: true),
    });
    try {
      final client = await ref.read(secureClientProvider.future);
      await client.notifications.markAllRead();
    } catch (e) {
      _restore(marked);
      if (writeMayHaveLanded(e)) ref.invalidateSelf();
      rethrow;
    }
  }

  /// Soft-delete a notification. Optimistic; on failure the notification
  /// is put back into the state as it is then (club_client#235).
  Future<void> deleteNotification(int id) async {
    final current = state.valueOrNull;
    final existing = current?[id];
    if (current == null || existing == null) return;
    state = AsyncData({...current}..remove(id));
    try {
      final client = await ref.read(secureClientProvider.future);
      await client.notifications.deleteNotification(id);
    } catch (e) {
      _restore({id: existing}, putBack: true);
      if (writeMayHaveLanded(e)) ref.invalidateSelf();
      rethrow;
    }
  }

  /// Undoes a failed optimistic write: puts [entries] back as they were
  /// before it, over the state as it is now, so changes that completed
  /// while the write was in flight stay. An entry no longer in the state
  /// (deleted meanwhile) stays out, unless [putBack] restores a deletion.
  void _restore(
    Map<int, AppNotification> entries, {
    bool putBack = false,
  }) {
    final now = state.valueOrNull;
    if (now == null) return;
    state = AsyncData({
      ...now,
      for (final entry in entries.entries)
        if (putBack || now.containsKey(entry.key)) entry.key: entry.value,
    });
  }
}
