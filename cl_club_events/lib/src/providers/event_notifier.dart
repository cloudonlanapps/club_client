import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Family provider for event notifier.
/// Key is event ID - watches the master and extracts the event reactively.
final AutoDisposeAsyncNotifierProviderFamily<EventNotifier, Event, int>
eventNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<EventNotifier, Event, int>(EventNotifier.new);

/// AsyncNotifier that manages a single event by ID.
///
/// Watches [clEventsMasterProvider] for reactive updates. Mutation methods
/// delegate to the master notifier — the master updates its state, which
/// triggers this provider to rebuild automatically.
class EventNotifier extends AutoDisposeFamilyAsyncNotifier<Event, int> {
  /// Event ID is available via [arg] property from Riverpod family notifier.
  int get eventId => arg;

  @override
  Future<Event> build(int eventId) async {
    final master = await ref.watch(clEventsMasterProvider.future);
    final event = master[eventId];
    if (event != null) return event;
    // Not in master map — fetch via the master notifier so SDK access
    // stays in cl_remote_store.
    return ref.read(clEventsMasterProvider.notifier).getEvent(eventId);
  }

  /// Correction for cosmetic changes (typos, clarifications, visibility).
  ///
  /// Changes apply to ALL occurrences (past and future).
  /// For semantic changes (time/venue/organizer), use
  /// updateEventForAllFuture().
  Future<Event> updateEvent({
    String? title,
    String? description,
    Visibility? visibility,
  }) async {
    return ref
        .read(clEventsMasterProvider.notifier)
        .correctionOnEvent(
          eventId,
          title: title,
          description: description,
          visibility: visibility,
        );
  }

  /// Split the programme's timetable at [effectiveDateTimeUtc]
  /// (club_core#16). The event keeps its id; the response carries its new
  /// current schedule.
  Future<Event> updateEventForAllFuture({
    required DateTime effectiveDateTimeUtc,
    int? venueId,
    String? organizerName,
    List<String>? Function()? coachNames,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    String? rrule,
    List<EventSession>? Function()? sessions,
  }) async {
    return ref
        .read(clEventsMasterProvider.notifier)
        .updateEventForAllFuture(
          eventId,
          effectiveDateTimeUtc: effectiveDateTimeUtc,
          venueId: venueId,
          organizerName: organizerName,
          coachNames: coachNames,
          startTimeUtc: startTimeUtc,
          endTimeUtc: endTimeUtc,
          rrule: rrule,
          sessions: sessions,
        );
  }

  /// Cancel the event series from [effectiveDateTimeUtc] onward.
  ///
  /// The server requires the effective time; for camps it must be a real
  /// occurrence start.
  Future<Event> cancelEvent({
    required String reason,
    required DateTime effectiveDateTimeUtc,
  }) async {
    return ref
        .read(clEventsMasterProvider.notifier)
        .cancelSeries(
          eventId,
          reason: reason,
          effectiveDateTimeUtc: effectiveDateTimeUtc,
        );
  }
}
