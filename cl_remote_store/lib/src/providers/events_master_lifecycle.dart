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

  /// The event version an edit should send: [version] when the caller
  /// supplies the one it loaded, else the one the master holds.
  Future<int> currentVersionOf(int eventId, int? version);

  /// Runs [change] to event [eventId]; a stale version reloads the event
  /// and its occurrences before it is rethrown.
  Future<Event> reloadOnStale(int eventId, Future<Event> Function() change);

  /// Cancel all future occurrences of an event from [effectiveDateTimeUtc].
  ///
  /// [effectiveDateTimeUtc] is required by the server. For camps it must be a
  /// real occurrence start, in the future, and at least 30 minutes away.
  ///
  /// [version] is the event version the caller loaded (club_client#123). A
  /// stale one is refused with [StaleVersionException]; the event and its
  /// occurrences are then reloaded before it is rethrown ([reloadOnStale]).
  Future<Event> cancelSeries(
    int eventId, {
    required String reason,
    required DateTime effectiveDateTimeUtc,
    int? version,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final sent = await currentVersionOf(eventId, version);
      final updated = await reloadOnStale(
        eventId,
        () => client.events.cancelSeries(
          eventId,
          version: sent,
          reason: reason,
          effectiveDateTimeUtc: effectiveDateTimeUtc,
        ),
      );

      replaceLocally(updated);
      bumpOccurrencesVersion();
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Reverse a series cancellation, clearing the event's until-time.
  /// [version] is the event's, as for [cancelSeries].
  Future<Event> undoCancelSeries(int eventId, {int? version}) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final sent = await currentVersionOf(eventId, version);
      final updated = await reloadOnStale(
        eventId,
        () => client.events.undoCancelSeries(eventId, version: sent),
      );

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
