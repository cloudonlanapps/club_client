import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The basic marketing write of `ClEventsMasterNotifier` (club_client#1):
/// the short description, stamp, highlights and includes an event's card
/// and page show (club_server#409).
///
/// A getter returning `null` clears that field; an omitted one leaves it
/// alone. A programme's go through `correctionOnEvent`, a camp's or
/// one-off's through `updateEvent`: the server refuses the other verb for
/// each type. The event's `version` is sent; a stale one reloads the event
/// before it is rethrown, and a failure that may have reached the server
/// reloads the events (club_core#138).
mixin ClEventsBasicMarketingMutations on AsyncNotifier<Map<int, Event>> {
  /// Replace or add an event in the master map.
  void replaceLocally(Event event);

  /// Reload the events and occurrence feeds after an uncertain write.
  void refetchAfterUncertainWrite();

  /// The event version an edit should send: [version] when the caller
  /// supplies the one it loaded, else the one the master holds.
  Future<int> currentVersionOf(int eventId, int? version);

  /// Runs [change] to event [eventId]; a stale version reloads the event
  /// and its occurrences before it is rethrown.
  Future<Event> reloadOnStale(int eventId, Future<Event> Function() change);

  /// Writes the basic marketing fields of [event].
  Future<Event> updateBasicMarketing(
    Event event, {
    int? version,
    String? Function()? shortDescription,
    String? Function()? stamp,
    List<String>? Function()? highlights,
    List<String>? Function()? includes,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final sent = await currentVersionOf(event.id, version);
      final updated = await reloadOnStale(
        event.id,
        () => event.type == EventType.programme
            ? client.events.correctionOnEvent(
                event.id,
                version: sent,
                shortDescription: shortDescription,
                stamp: stamp,
                highlights: highlights,
                includes: includes,
              )
            : client.events.updateEvent(
                event.id,
                version: sent,
                shortDescription: shortDescription,
                stamp: stamp,
                highlights: highlights,
                includes: includes,
              ),
      );
      replaceLocally(updated);
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }
}
