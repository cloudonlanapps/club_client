import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The lifecycle mutations of `ClEventsMasterNotifier`: cancel and undo a
/// camp series, call off (drop) and reinstate a one-off, soft-delete,
/// restore and hard-delete an event.
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

  /// Call off a one-off (`POST …/drop`, club_client#40): its single
  /// occurrence is cancelled, with [reason].
  ///
  /// [version] is the version of that occurrence as last loaded, which is
  /// what the server asks for. A stale one is refused with
  /// [StaleVersionException]; the occurrence feeds are then reloaded before
  /// it is rethrown.
  Future<Event> drop(
    int eventId, {
    required int version,
    required String reason,
  }) {
    return changeOneOffOccurrence(
      (client) => client.events.drop(eventId, version: version, reason: reason),
    );
  }

  /// Reinstate a called-off one-off (`POST …/reinstate`, club_client#40),
  /// restoring its occurrence. [version] is the occurrence's, as for [drop].
  Future<Event> reinstate(int eventId, {required int version}) {
    return changeOneOffOccurrence(
      (client) => client.events.reinstate(eventId, version: version),
    );
  }

  /// Runs [change], a write to a one-off's single occurrence that answers
  /// with the event; stores the event and reloads the occurrence feeds, also
  /// when the write is refused as stale.
  Future<Event> changeOneOffOccurrence(
    Future<Event> Function(SecureClient client) change,
  ) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      try {
        final updated = await change(client);
        replaceLocally(updated);
        bumpOccurrencesVersion();
        return updated;
      } on StaleVersionException {
        bumpOccurrencesVersion();
        rethrow;
      }
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
