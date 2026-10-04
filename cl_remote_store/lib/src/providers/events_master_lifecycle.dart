import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The lifecycle mutations of `ClEventsMasterNotifier`: cancel and undo a
/// series, soft-delete, restore and hard-delete an event.
///
/// Each reloads the events and occurrence feeds when it fails in a way that
/// may have reached the server (club_core#138).
mixin ClEventsLifecycleMutations on AsyncNotifier<Map<int, Event>> {
  /// Replace or add an event in the master map.
  void replaceLocally(Event event);

  /// Remove an event from the master map.
  void removeLocally(int eventId);

  /// Bump the occurrences version counter, so every occurrence feed reloads.
  void bumpOccurrencesVersion();

  /// Reload the events and occurrence feeds after an uncertain write.
  void refetchAfterUncertainWrite();

  /// Cancel all future occurrences of an event from [effectiveDateTimeUtc].
  ///
  /// [effectiveDateTimeUtc] is required by the server. For camps it must be a
  /// real occurrence start, in the future, and at least 30 minutes away.
  Future<Event> cancelSeries(
    int eventId, {
    required String reason,
    required DateTime effectiveDateTimeUtc,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.events.cancelSeries(
        eventId,
        reason: reason,
        effectiveDateTimeUtc: effectiveDateTimeUtc,
      );

      replaceLocally(updated);
      bumpOccurrencesVersion();
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Reverse a series cancellation, clearing the event's until-time.
  Future<Event> undoCancelSeries(int eventId) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.events.undoCancelSeries(eventId);

      replaceLocally(updated);
      bumpOccurrencesVersion();
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Soft-delete an event.
  ///
  /// The server echoes the soft-deleted event (with `deletedAtUtc` set), so
  /// the local map is updated from that response rather than blindly
  /// dropping the id. A blind removal would hide whether the server actually
  /// persisted the delete; keeping the inactive event in the map means
  /// derived list views (which filter on `isActive`) reflect true server
  /// state.
  Future<void> deleteEvent(int eventId) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final deleted = await client.events.deleteEvent(eventId);
      replaceLocally(deleted);
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Restore a soft-deleted event.
  Future<Event> restoreEvent(int eventId) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final restored = await client.events.restoreEvent(eventId);
      replaceLocally(restored);
      return restored;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Permanently delete an event (super admin only).
  Future<void> hardDeleteEvent(int eventId) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.events.hardDeleteEvent(eventId);
      removeLocally(eventId);
    }, refetch: refetchAfterUncertainWrite);
  }
}
