import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;
import 'package:ui_lib/ui_lib.dart'
    show EventTimetableValue, TimetableScheduleOption;

import '../utils/session_inputs.dart';

/// SDK ↔ `EventTimetableForm` adapter for the timetable **correction**
/// section (club_core#85): how each occurrence is split into named sessions,
/// corrected in place at any time without moving a date.
///
/// SDK → form: [buildEventTimetableSchedules] (a camp's or one-off's single
/// schedule, or a programme's schedules). Form → SDK:
/// [EventTimetableFormSubmit.updateTimetable].

/// The local time of day [startUtc] falls at, as the form's start time.
ShadTimeOfDay timetableStartOf(DateTime startUtc) {
  final local = startUtc.toLocal();
  return ShadTimeOfDay(hour: local.hour, minute: local.minute, second: 0);
}

/// The one schedule of a camp or one-off, read off the [event] itself.
TimetableScheduleOption buildEventTimetableSchedule(Event event) {
  final start = timetableStartOf(event.startTimeUtc);
  return TimetableScheduleOption(
    label: 'Every occurrence',
    startTime: start,
    totalMinutes: event.endTimeUtc.difference(event.startTimeUtc).inMinutes,
    sessions: sessionInputsFromEventSessions(event.sessions, start),
  );
}

/// How a programme's [schedule] is named in the picker: its date range, or
/// "from … (current)" while it is still running.
String timetableScheduleLabel(EventSchedule schedule) {
  final from = formatDate(schedule.effectiveFromUtc.toLocal());
  final until = schedule.effectiveUntilUtc;
  if (until == null) return 'From $from (current)';
  return 'From $from until ${formatDate(until.toLocal())}';
}

/// A programme's [schedule] as a form option, carrying its id.
TimetableScheduleOption buildProgrammeTimetableSchedule(
  EventSchedule schedule,
) {
  final start = timetableStartOf(schedule.startTimeUtc);
  return TimetableScheduleOption(
    id: schedule.id,
    label: timetableScheduleLabel(schedule),
    startTime: start,
    totalMinutes: schedule.endTimeUtc
        .difference(schedule.startTimeUtc)
        .inMinutes,
    sessions: sessionInputsFromEventSessions(schedule.sessions, start),
  );
}

/// The schedules whose timetable may be corrected, oldest first: a
/// programme's [schedules] when they are known, else the [event]'s own
/// (current) schedule.
List<TimetableScheduleOption> buildEventTimetableSchedules(
  Event event, {
  List<EventSchedule>? schedules,
}) {
  if (event.type == EventType.programme &&
      schedules != null &&
      schedules.isNotEmpty) {
    return [for (final s in schedules) buildProgrammeTimetableSchedule(s)];
  }
  return [buildEventTimetableSchedule(event)];
}

/// Bridges `EventTimetableForm` to the master's timetable corrections.
class EventTimetableFormSubmit {
  const EventTimetableFormSubmit._();

  /// Corrects [event]'s timetable to [value] via the master [notifier]: a
  /// programme's through `correctionOnEvent(sessions:, scheduleId:)`, a
  /// camp's or one-off's through `updateEvent(sessions:)`. Both are allowed
  /// at any time, including after the event has started, and move no date.
  /// An empty split clears the timetable.
  ///
  /// Sends [event]'s `version`, so an event changed since it was loaded is
  /// refused with `StaleVersionException` (the master reloads it first).
  /// Throws `ServerException` `INVALID_SESSIONS_TOTAL` when the split does
  /// not add up to the occurrence length, and `SCHEDULE_NOT_FOUND` when the
  /// schedule is no longer the event's.
  static Future<Event> updateTimetable({
    required Event event,
    required EventTimetableValue value,
    required ClEventsMasterNotifier notifier,
  }) {
    final sessions = eventSessionsFromSessionInputs(value.sessions);
    List<EventSession>? getter() => sessions.isEmpty ? null : sessions;
    if (event.type == EventType.programme) {
      return notifier.correctionOnEvent(
        event.id,
        version: event.version,
        sessions: getter,
        scheduleId: value.scheduleId,
      );
    }
    return notifier.updateEvent(
      event.id,
      version: event.version,
      sessions: getter,
    );
  }
}
