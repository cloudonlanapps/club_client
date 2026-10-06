import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/club_event_types.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/events_master_lifecycle.dart';
import 'package:cl_remote_store/src/providers/events_master_occurrences.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:cl_remote_store/src/utils/fetch_for_event_types.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for the club's events (staff view).
///
/// Holds the canonical `Map<int, Event>` of the event types the club runs
/// ([clubEventTypesProvider]; camps alone unless configured). For an admin
/// the map also holds the archived (soft-deleted) events of those types
/// (club_client#36); listings filter on `Event.isActive`. All event
/// mutations and their occurrence mutations go through this notifier.
/// Occurrence mutations bump `occurrencesVersion` on
/// [clResourceVersionProvider].
final AsyncNotifierProvider<ClEventsMasterNotifier, Map<int, Event>>
clEventsMasterProvider =
    AsyncNotifierProvider<ClEventsMasterNotifier, Map<int, Event>>(
      ClEventsMasterNotifier.new,
    );

/// Notifier managing event state and mutations.
class ClEventsMasterNotifier extends AsyncNotifier<Map<int, Event>>
    with ClEventsOccurrenceMutations, ClEventsLifecycleMutations {
  @override
  Future<Map<int, Event>> build() async {
    ref.watch(clManualRefreshProvider);
    final types = ref.watch(clubEventTypesProvider);
    final client = await ref.watch(secureClientProvider.future);
    // Watched (not read) so the build re-runs when the role lands, as in
    // `ClGroupsMasterNotifier`.
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
    final items = await fetchForEventTypes(
      types,
      (type) => fetchAllPages(
        ({required offset, required limit}) => client.events.listEvents(
          offset: offset,
          limit: limit,
          eventType: type,
        ),
      ),
    );
    // `GET /events/deleted` is admin-only and takes no type, so the club's
    // types are picked here. Everyone else gets the live events alone.
    final archived = isAdmin
        ? await fetchAllPages(client.events.listDeletedEvents)
        : const <Event>[];
    return {
      for (final e in items) e.id: e,
      for (final e in archived)
        if (types.contains(e.type)) e.id: e,
    };
  }

  // -- Event Reads ------------------------------------------------------------

  /// Fetch a single event by ID from the server.
  ///
  /// Use this when the event isn't yet in the master map (e.g., a member
  /// who hasn't loaded the full event list). The result is also written
  /// back into the master so subsequent reads are cached.
  Future<Event> getEvent(int eventId) async {
    final client = await ref.read(secureClientProvider.future);
    final event = await client.events.getEvent(eventId);
    replaceLocally(event);
    return event;
  }

  /// Camp-only enrollment pre-flight. Reports overlapping occurrences
  /// for each listed user. The server rejects non-camp events with
  /// `EVENT_TYPE_NOT_SUPPORTED`.
  Future<UserConflictReport> checkUserConflicts(
    int eventId, {
    required List<String> usernames,
  }) async {
    final client = await ref.read(secureClientProvider.future);
    return client.events.checkUserConflicts(
      eventId,
      usernames: usernames,
    );
  }

  // -- Event CRUD -------------------------------------------------------------

  /// Create a new event.
  Future<Event> createEvent({
    required String title,
    required String description,
    required EventType type,
    required Visibility visibility,
    required int venueId,
    required DateTime startTimeUtc,
    required DateTime endTimeUtc,
    String? organizerName,
    List<String>? coachNames,
    String? rrule,
    Gender? gender,
    Age? minAge,
    Age? maxAge,
    bool? strictAge,
    bool isFeatured = false,
    List<String>? galleryUris,
    List<EventSession>? sessions,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final created = await client.events.createEvent(
        title: title,
        description: description,
        type: type,
        visibility: visibility,
        venueId: venueId,
        startTimeUtc: startTimeUtc,
        endTimeUtc: endTimeUtc,
        organizerName: organizerName,
        coachNames: coachNames,
        rrule: rrule,
        gender: gender,
        minAge: minAge,
        maxAge: maxAge,
        strictAge: strictAge,
        isFeatured: isFeatured,
        galleryUris: galleryUris,
        sessions: sessions,
      );

      replaceLocally(created);
      bumpOccurrencesVersion();
      return created;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// The event version an edit should send (#25): [version] when the caller
  /// supplies the one it loaded, else the version held in the master map,
  /// else the server's current one.
  Future<int> currentVersionOf(int eventId, int? version) async {
    if (version != null) return version;
    final cached = state.value?[eventId];
    if (cached != null) return cached.version;
    return (await getEvent(eventId)).version;
  }

  /// Update a camp's or one-off's metadata.
  ///
  /// [sessions] corrects the timetable in place at any time, including after
  /// the event has started (club_core#85): a getter returning `null` clears
  /// it, an omitted getter leaves it alone. The window (venue, start, end,
  /// rrule) moves through [rescheduleEvent].
  ///
  /// [minAge], [maxAge] and [strictAge] are the age band: a getter
  /// returning `null` clears that bound, an omitted one leaves it alone, and
  /// [strictAge] left `null` is unchanged. The server works out the window
  /// of birth dates and reports it on the event.
  ///
  /// A stale [version] reloads the event before it is rethrown
  /// ([reloadOnStale]).
  Future<Event> updateEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    String? organizerName,
    List<String>? Function()? coachNames,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final sent = await currentVersionOf(eventId, version);
      final updated = await reloadOnStale(
        eventId,
        () => client.events.updateEvent(
          eventId,
          version: sent,
          title: title,
          description: description,
          visibility: visibility,
          organizerName: organizerName,
          coachNames: coachNames,
          gender: gender,
          minAge: minAge,
          maxAge: maxAge,
          strictAge: strictAge,
          isFeatured: isFeatured,
          galleryUris: galleryUris,
          sessions: sessions,
        ),
      );

      replaceLocally(updated);
      bumpOccurrencesVersion();
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Runs [change] to event [eventId]; when the server refuses it as stale
  /// ([StaleVersionException]), reloads the event and its occurrences before
  /// rethrowing, so the caller can say who changed it and when.
  Future<Event> reloadOnStale(
    int eventId,
    Future<Event> Function() change,
  ) async {
    try {
      return await change();
    } on StaleVersionException {
      await getEvent(eventId);
      bumpOccurrencesVersion();
      rethrow;
    }
  }

  /// Move a camp or one-off event's schedule in place.
  ///
  /// At least one of [startTimeUtc], [endTimeUtc], [rrule], [venueId],
  /// [sessions] must be supplied. Pass [sessions] to replace the per-occurrence
  /// timetable atomically (a getter returning `null` clears it; omitting it
  /// leaves it untouched). Pass [resetOverrides] to clear conflicting
  /// occurrence overrides.
  ///
  /// [version] is the event version the caller loaded (club_core#68). A stale
  /// one is refused with [StaleVersionException]; the event and its
  /// occurrences are then reloaded before it is rethrown.
  Future<Event> rescheduleEvent(
    int eventId, {
    int? version,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    String? rrule,
    int? venueId,
    List<EventSession>? Function()? sessions,
    bool resetOverrides = false,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final sent = await currentVersionOf(eventId, version);
      final updated = await reloadOnStale(
        eventId,
        () => client.events.rescheduleEvent(
          eventId,
          version: sent,
          startTimeUtc: startTimeUtc,
          endTimeUtc: endTimeUtc,
          rrule: rrule,
          venueId: venueId,
          sessions: sessions,
          resetOverrides: resetOverrides,
        ),
      );

      replaceLocally(updated);
      bumpOccurrencesVersion();
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }

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
    Gender? Function()? gender,
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
          gender: gender,
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
        ),
      );

      replaceLocally(newEvent);
      bumpOccurrencesVersion();
      return newEvent;
    }, refetch: refetchAfterUncertainWrite);
  }

  // -- Local State Helpers ----------------------------------------------------

  /// Replace or add an event in the master map.
  @override
  void replaceLocally(Event event) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData({...current, event.id: event});
  }

  /// Remove an event from the master map.
  @override
  void removeLocally(int eventId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(Map.of(current)..remove(eventId));
  }

  /// After a write that may have landed ([refetchIfWriteUncertain]): reload
  /// the events and every occurrence feed from the server.
  @override
  void refetchAfterUncertainWrite() {
    ref.invalidateSelf();
    bumpOccurrencesVersion();
  }

  @override
  void bumpOccurrencesVersion() {
    final current = ref.read(clResourceVersionProvider);
    ref.read(clResourceVersionProvider.notifier).state = current.copyWith(
      occurrencesVersion: current.occurrencesVersion + 1,
    );
  }
}
