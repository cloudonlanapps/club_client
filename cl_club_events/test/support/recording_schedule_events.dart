import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';

/// One `rescheduleEvent` call, as the Schedule block's adapters send it.
class RescheduleCall {
  RescheduleCall({
    required this.version,
    required this.startTimeUtc,
    required this.endTimeUtc,
    required this.rrule,
    required this.venueId,
    required this.sessionsSent,
    required this.sessions,
  });

  final int? version;
  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;
  final String? rrule;
  final int? venueId;

  /// Whether the call carried a sessions getter at all.
  final bool sessionsSent;

  /// What the getter returned (`null` clears the timetable).
  final List<EventSession>? sessions;
}

/// One `updateEventForAllFuture` call.
class FutureUpdateCall {
  FutureUpdateCall({
    required this.version,
    required this.effectiveDateTimeUtc,
    required this.startTimeUtc,
    required this.endTimeUtc,
    required this.rrule,
    required this.venueId,
    required this.sessionsSent,
    required this.sessions,
  });

  final int? version;
  final DateTime effectiveDateTimeUtc;
  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;
  final String? rrule;
  final int? venueId;
  final bool sessionsSent;
  final List<EventSession>? sessions;
}

/// An events master that records the schedule changes sent to it, or
/// refuses them with [error]. It never reaches a server.
class RecordingScheduleEvents extends ClEventsMasterNotifier {
  RecordingScheduleEvents(this.event);

  final Event event;
  final List<RescheduleCall> reschedules = [];
  final List<FutureUpdateCall> futureUpdates = [];

  /// The end-date calls, e.g. `terminate(<cutoff>, reason)`.
  final List<String> endDateCalls = [];

  /// Timetable corrections, e.g. `update(v4, 2)`.
  final List<String> corrections = [];

  /// When set, every change throws this instead of applying.
  Exception? error;

  @override
  Future<Map<int, Event>> build() async => {event.id: event};

  @override
  Future<Event> rescheduleEvent(
    int eventId, {
    int? version,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    String? rrule,
    int? venueId,
    List<EventSession>? Function()? sessions,
    bool resetOverrides = false,
  }) async {
    reschedules.add(
      RescheduleCall(
        version: version,
        startTimeUtc: startTimeUtc,
        endTimeUtc: endTimeUtc,
        rrule: rrule,
        venueId: venueId,
        sessionsSent: sessions != null,
        sessions: sessions?.call(),
      ),
    );
    if (error != null) throw error!;
    return event;
  }

  @override
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
  }) async {
    futureUpdates.add(
      FutureUpdateCall(
        version: version,
        effectiveDateTimeUtc: effectiveDateTimeUtc,
        startTimeUtc: startTimeUtc,
        endTimeUtc: endTimeUtc,
        rrule: rrule,
        venueId: venueId,
        sessionsSent: sessions != null,
        sessions: sessions?.call(),
      ),
    );
    if (error != null) throw error!;
    return event;
  }

  @override
  Future<Event> terminate(
    int eventId, {
    required String reason,
    required DateTime cutoffTimeUtc,
  }) async {
    endDateCalls.add('terminate($cutoffTimeUtc, $reason)');
    if (error != null) throw error!;
    return event;
  }

  @override
  Future<Event> extend(
    int eventId, {
    required DateTime cutoffTimeUtc,
    String? reason,
  }) async {
    endDateCalls.add('extend($cutoffTimeUtc, $reason)');
    if (error != null) throw error!;
    return event;
  }

  @override
  Future<Event> extendIndefinitely(int eventId, {String? reason}) async {
    endDateCalls.add('extendIndefinitely($reason)');
    if (error != null) throw error!;
    return event;
  }

  @override
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
  }) async {
    corrections.add('update(v$version, ${sessions?.call()?.length})');
    if (error != null) throw error!;
    return event;
  }
}
