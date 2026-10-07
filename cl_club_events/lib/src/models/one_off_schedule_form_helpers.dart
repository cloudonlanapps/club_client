import 'package:cl_club_forms/cl_club_forms.dart'
    show
        OneOffScheduleData,
        OneOffScheduleFormFields,
        OneOffScheduleValue,
        SessionInput;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import '../utils/session_inputs.dart';

/// SDK ↔ `OneOffScheduleForm` adapter for a one-off's **schedule**
/// (reschedule) section: [buildOneOffScheduleInitialValues] (SDK → form) and
/// [OneOffScheduleFormSubmit.updateSchedule] (form → SDK).

/// How far ahead of its start a one-off must be for the server to move it.
const Duration oneOffRescheduleLeadTime = Duration(minutes: 30);

/// Why a started one-off's date and times are fixed, and what can still
/// change: its timetable.
const String oneOffStartedMessage =
    'This event has started, so its date and times can no longer be '
    'changed. Its timetable can still be corrected.';

/// Why a one-off about to start can no longer be moved.
const String oneOffStartsSoonMessage =
    'This event starts in under 30 minutes, so its date and times can no '
    'longer be changed. Its timetable can still be corrected.';

/// Why a called-off one-off cannot be moved.
const String oneOffCalledOffMessage =
    'This event is called off, so its date and times cannot be changed. '
    'Its timetable can still be corrected.';

/// The [OneOffScheduleValue] that seeds `OneOffScheduleForm` from [event]:
/// its local date, start time and duration, its venue and its sessions. An
/// unedited form gives the same value back, so its Save is a no-op.
OneOffScheduleValue buildOneOffScheduleInitialValues(Event event) {
  final startLocal = event.startTimeUtc.toLocal();
  final startTime = ShadTimeOfDay(
    hour: startLocal.hour,
    minute: startLocal.minute,
    second: 0,
  );
  return OneOffScheduleValue(
    schedule: OneOffScheduleData(
      date: DateTime(startLocal.year, startLocal.month, startLocal.day),
      startTime: startTime,
      durationMinutes: event.endTimeUtc
          .difference(event.startTimeUtc)
          .inMinutes,
    ),
    venueId: event.venueId,
    sessions: sessionInputsFromEventSessions(event.sessions, startTime),
  );
}

/// Why the one-off [event] cannot be moved right now, or `null` when it
/// can. Mirrors the server's guards: a called-off one-off ([calledOff]) is
/// refused until it is put back on, and the move must be asked for at least
/// [oneOffRescheduleLeadTime] before the start.
String? oneOffRescheduleLockReason(
  Event event, {
  bool calledOff = false,
  DateTime? now,
}) {
  final nowUtc = (now ?? DateTime.now()).toUtc();
  if (!event.startTimeUtc.isAfter(nowUtc)) return oneOffStartedMessage;
  if (calledOff) return oneOffCalledOffMessage;
  if (event.startTimeUtc.isBefore(nowUtc.add(oneOffRescheduleLeadTime))) {
    return oneOffStartsSoonMessage;
  }
  return null;
}

/// The schedule `OneOffScheduleForm.validate()` returned as [values]: when
/// the one-off takes place, where, and its split.
OneOffScheduleValue oneOffScheduleValueOf(Map<String, dynamic> values) =>
    OneOffScheduleValue(
      schedule:
          values[OneOffScheduleFormFields.scheduleId] as OneOffScheduleData,
      venueId: values[OneOffScheduleFormFields.venueId] as int?,
      sessions: List<SessionInput>.of(
        values[OneOffScheduleFormFields.sessionsId] as List<SessionInput>,
      ),
    );

/// Bridges `OneOffScheduleForm` to the master's reschedule call.
class OneOffScheduleFormSubmit {
  const OneOffScheduleFormSubmit._();

  /// Moves the one-off [event] to [value] via the master [notifier], in one
  /// `rescheduleEvent` call carrying only what changed among the start, the
  /// end, the venue and the sessions, and [event]'s `version`. A one-off
  /// does not recur, so no `rrule` is ever sent. An empty split clears the
  /// timetable.
  ///
  /// Returns [event] untouched, with no call, when nothing changed.
  ///
  /// Throws `StaleVersionException` when the event changed since it was
  /// loaded (the master reloads it first), and `ServerException` on the
  /// server's guards (`EVENT_ALREADY_STARTED`, `POSTPONE_ONLY`,
  /// `RESCHEDULE_LEAD_TIME_VIOLATED`, `BEYOND_SCHEDULING_HORIZON`,
  /// `INVALID_SESSIONS_TOTAL`, `OCCURRENCE_OVERRIDES_PRESENT`, …).
  static Future<Event> updateSchedule({
    required Event event,
    required OneOffScheduleValue value,
    required ClEventsMasterNotifier notifier,
  }) async {
    final schedule = value.schedule;
    final start = DateTime(
      schedule.date!.year,
      schedule.date!.month,
      schedule.date!.day,
      schedule.startTime!.hour,
      schedule.startTime!.minute,
    ).toUtc();
    final end = start.add(Duration(minutes: schedule.durationMinutes));
    final sessions = eventSessionsFromSessionInputs(value.sessions);

    final windowChanged =
        start != event.startTimeUtc || end != event.endTimeUtc;
    final venueChanged =
        value.venueId != null && value.venueId != event.venueId;
    final sessionsChanged = !listEquals(
      sessions,
      event.sessions ?? const <EventSession>[],
    );
    if (!windowChanged && !venueChanged && !sessionsChanged) return event;

    return notifier.rescheduleEvent(
      event.id,
      version: event.version,
      startTimeUtc: windowChanged ? start : null,
      endTimeUtc: windowChanged ? end : null,
      venueId: venueChanged ? value.venueId : null,
      sessions: sessionsChanged
          ? () => sessions.isEmpty ? null : sessions
          : null,
    );
  }
}
