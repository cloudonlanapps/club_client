import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The programme verbs of `ClEventsMasterNotifier` (club_core#16): a
/// correction for the programme's whole life, and a split of its timetable
/// from a session onward.
///
/// Each sends the event's `version`; a stale one reloads the event before it
/// is rethrown, and a failure that may have reached the server reloads the
/// events (club_core#138).
mixin ClEventsProgrammeMutations on AsyncNotifier<Map<int, Event>> {
  /// Replace or add an event in the master map.
  void replaceLocally(Event event);

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

  /// Correct a programme's identity, eligibility and presentation for its
  /// whole life (club_core#16). Staffing moves through
  /// [updateEventForAllFuture].
  ///
  /// [sessions] corrects one schedule's timetable in place, at any time and
  /// with no split (club_core#85): the schedule [scheduleId] names, or the
  /// latest when it is omitted. A stale [version] reloads the event before
  /// it is rethrown ([reloadOnStale]).
  Future<Event> correctionOnEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    List<Gender> Function()? genders,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
    int? scheduleId,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final sent = await currentVersionOf(eventId, version);
      final updated = await reloadOnStale(
        eventId,
        () => client.events.correctionOnEvent(
          eventId,
          version: sent,
          title: title,
          description: description,
          visibility: visibility,
          genders: genders,
          minAge: minAge,
          maxAge: maxAge,
          strictAge: strictAge,
          isFeatured: isFeatured,
          galleryUris: galleryUris,
          sessions: sessions,
          scheduleId: scheduleId,
        ),
      );

      replaceLocally(updated);
      if (sessions != null) bumpOccurrencesVersion();
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Split a programme's timetable at [effectiveDateTimeUtc]
  /// (club_core#16): the same event returns with its new current schedule.
  /// A stale [version] reloads the event before it is rethrown
  /// ([reloadOnStale]).
  ///
  /// A clash of the new schedule or staff with another event's venue,
  /// organizer or coach is refused with `ScheduleConflictException` and
  /// nothing is written; the same call with [acceptConflicts] `true` writes
  /// it anyway (club_server#72).
  Future<Event> updateEventForAllFuture(
    int eventId, {
    required DateTime effectiveDateTimeUtc,
    int? version,
    int? venueId,
    String? organizerName,
    List<String>? Function()? coachNames,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    String? rrule,
    List<EventSession>? Function()? sessions,
    bool acceptConflicts = false,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final sent = await currentVersionOf(eventId, version);
      final newEvent = await reloadOnStale(
        eventId,
        () => client.events.updateEventForAllFuture(
          eventId,
          version: sent,
          effectiveDateTimeUtc: effectiveDateTimeUtc,
          venueId: venueId,
          organizerName: organizerName,
          coachNames: coachNames,
          startTimeUtc: startTimeUtc,
          endTimeUtc: endTimeUtc,
          rrule: rrule,
          sessions: sessions,
          acceptConflicts: acceptConflicts,
        ),
      );

      replaceLocally(newEvent);
      bumpOccurrencesVersion();
      return newEvent;
    }, refetch: refetchAfterUncertainWrite);
  }
}
