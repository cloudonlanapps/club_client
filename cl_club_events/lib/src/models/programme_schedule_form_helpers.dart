import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ProgrammeScheduleAdjustFormFields,
        ProgrammeScheduleAdjustValue,
        ProgrammeScheduleData;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import '../utils/programme_end_date.dart';
import '../utils/programme_schedule_sessions.dart';
import '../utils/session_inputs.dart';

/// SDK ↔ form adapter for the actions of a programme's Schedule block:
/// **Adjust Schedule** ([buildProgrammeScheduleAdjustInitialValues],
/// [programmeAdjustFromOptions],
/// [ProgrammeScheduleFormSubmit.adjustSchedule]) and **Adjust end date**
/// ([ProgrammeScheduleFormSubmit.adjustEndDate]).

/// How many upcoming sessions the From picker offers.
const int programmeAdjustFromOptionCount = 12;

/// How far ahead the From picker looks for upcoming sessions.
const Duration programmeAdjustFromLookAhead = Duration(days: 26 * 7);

/// The session starts an adjusted schedule may begin at: the upcoming ones
/// of [event]'s current schedule, at least [programmeChangeLeadTime] ahead
/// of [now] and before the programme's end date, soonest first. The server
/// accepts no other effective time.
List<DateTime> programmeAdjustFromOptions(
  Event event, {
  List<EventSchedule>? schedules,
  DateTime? now,
}) {
  final earliest = (now ?? DateTime.now()).toUtc().add(programmeChangeLeadTime);
  final horizon = earliest.add(programmeAdjustFromLookAhead);
  final until = event.untilTimeUtc;
  return programmeSessionStarts(
    event,
    fromUtc: earliest,
    toUtc: until != null && until.isBefore(horizon) ? until : horizon,
    schedules: schedules,
    limit: programmeAdjustFromOptionCount,
  );
}

/// The [ProgrammeScheduleData] of [event]'s current schedule: its local
/// weekdays, start time, duration and sessions. `startDate` is the day the
/// schedule's first session falls on; an adjustment does not edit it.
ProgrammeScheduleData buildProgrammeScheduleInitialValues(Event event) {
  final startLocal = event.startTimeUtc.toLocal();
  final startTime = ShadTimeOfDay(
    hour: startLocal.hour,
    minute: startLocal.minute,
    second: 0,
  );
  return ProgrammeScheduleData(
    weekdays: programmeLocalWeekdays(event),
    startDate: DateTime(startLocal.year, startLocal.month, startLocal.day),
    sessionStartTime: startTime,
    totalDurationMinutes: event.endTimeUtc
        .difference(event.startTimeUtc)
        .inMinutes,
    sessions: sessionInputsFromEventSessions(event.sessions, startTime),
  );
}

/// The value that seeds `ProgrammeScheduleAdjustForm`: [event]'s current
/// schedule and venue, starting from the first of [fromOptions].
ProgrammeScheduleAdjustValue buildProgrammeScheduleAdjustInitialValues(
  Event event, {
  required List<DateTime> fromOptions,
}) => ProgrammeScheduleAdjustValue(
  from: fromOptions.isEmpty ? null : fromOptions.first,
  schedule: buildProgrammeScheduleInitialValues(event),
  venueId: event.venueId,
);

/// The adjustment `ProgrammeScheduleAdjustForm.validate()` returned as
/// [values]: the From session, the new terms and the venue.
ProgrammeScheduleAdjustValue programmeScheduleAdjustValueOf(
  Map<String, dynamic> values,
) => ProgrammeScheduleAdjustValue(
  from: values[ProgrammeScheduleAdjustFormFields.fromId] as DateTime?,
  schedule:
      values[ProgrammeScheduleAdjustFormFields.scheduleId]
          as ProgrammeScheduleData,
  venueId: values[ProgrammeScheduleAdjustFormFields.venueId] as int?,
);

/// Bridges the programme Schedule block's forms to the master's calls.
class ProgrammeScheduleFormSubmit {
  const ProgrammeScheduleFormSubmit._();

  /// Gives the programme [event] the terms of [value] from the session
  /// starting at `value.from` onward, via the master [notifier]: one
  /// `updateEventForAllFuture` call with that effective time, [event]'s
  /// `version` and only the terms that changed among the venue, the start
  /// and end, the weekly rule and the sessions. Sessions before it keep the
  /// present schedule.
  ///
  /// The rule sent is weekly and names its days, nothing else. A new start
  /// time is anchored on the From session's day.
  ///
  /// Returns [event] untouched, with no call, when no term changed.
  ///
  /// Throws `StaleVersionException` when the event changed since it was
  /// loaded (the master reloads it first), and `ServerException` on the
  /// server's guards: a clash with another programme (`TIME_CONFLICT`),
  /// `EFFECTIVE_TIME_NOT_SESSION_BOUNDARY`, `CUTOFF_TOO_SOON`,
  /// `INVALID_SESSIONS_TOTAL`, ….
  static Future<Event> adjustSchedule({
    required Event event,
    required ProgrammeScheduleAdjustValue value,
    required ClEventsMasterNotifier notifier,
  }) async {
    final next = value.schedule;
    final from = value.from!.toUtc();
    final time = next.sessionStartTime!;
    final startLocal = event.startTimeUtc.toLocal();
    final timeChanged =
        time.hour != startLocal.hour || time.minute != startLocal.minute;
    final durationChanged =
        next.totalDurationMinutes !=
        event.endTimeUtc.difference(event.startTimeUtc).inMinutes;
    final windowChanged = timeChanged || durationChanged;

    final fromLocal = from.toLocal();
    final start = timeChanged
        ? DateTime(
            fromLocal.year,
            fromLocal.month,
            fromLocal.day,
            time.hour,
            time.minute,
          ).toUtc()
        : event.startTimeUtc;
    final end = start.add(Duration(minutes: next.totalDurationMinutes));

    // The rule names its days in UTC; the form speaks local weekdays.
    final ruleWeekdays = shiftWeekdays(next.weekdays, -localDayShiftOf(start));
    final ruleChanged = !setEquals(
      ruleWeekdays,
      programmeRuleWeekdays(event.rrule),
    );
    final venueChanged =
        value.venueId != null && value.venueId != event.venueId;
    final sessions = eventSessionsFromSessionInputs(next.sessions);
    final sessionsChanged = !listEquals(
      sessions,
      event.sessions ?? const <EventSession>[],
    );
    if (!windowChanged && !ruleChanged && !venueChanged && !sessionsChanged) {
      return event;
    }

    return notifier.updateEventForAllFuture(
      event.id,
      effectiveDateTimeUtc: from,
      version: event.version,
      venueId: venueChanged ? value.venueId : null,
      startTimeUtc: windowChanged ? start : null,
      endTimeUtc: windowChanged ? end : null,
      rrule: ruleChanged ? programmeRruleFor(ruleWeekdays) : null,
      sessions: sessionsChanged
          ? () => sessions.isEmpty ? null : sessions
          : null,
    );
  }

  /// Sets, moves or clears the end date of the programme [event] via the
  /// master [notifier].
  ///
  /// [lastDay] is the last local day the programme runs on; the cutoff sent
  /// is the first session start of the current schedule after the end of
  /// that day ([programmeEndCutoff]), from which sessions no longer occur.
  /// A programme with no end is given one with `terminate`, which needs
  /// [reason]; one whose end is ahead has it moved with `extend`, where a
  /// blank [reason] is left out. A `null` [lastDay] removes the end with
  /// `extendIndefinitely`.
  ///
  /// Returns [event] untouched, with no call, when the cutoff is the one it
  /// has. Throws [SdkError] before any call when the schedule has no
  /// session after [lastDay], and `ServerException` on the server's guards
  /// (`EFFECTIVE_TIME_NOT_SESSION_BOUNDARY`, `CUTOFF_TOO_SOON`, and
  /// `INVALID_STATE` once the end has passed).
  static Future<Event> adjustEndDate({
    required Event event,
    required DateTime? lastDay,
    required String reason,
    required ClEventsMasterNotifier notifier,
    List<EventSchedule>? schedules,
  }) async {
    final why = reason.trim();
    if (lastDay == null) {
      return notifier.extendIndefinitely(
        event.id,
        reason: why.isEmpty ? null : why,
      );
    }
    final cutoff = programmeEndCutoff(event, lastDay, schedules: schedules);
    if (cutoff == null) {
      throw const SdkError(
        programmeEndDateNoSessionMessage,
        code: SdkErrorCode.effectiveTimeNotSessionBoundary,
      );
    }
    final current = event.untilTimeUtc;
    if (current == null) {
      return notifier.terminate(event.id, reason: why, cutoffTimeUtc: cutoff);
    }
    if (current.isAtSameMomentAs(cutoff)) return event;
    return notifier.extend(
      event.id,
      cutoffTimeUtc: cutoff,
      reason: why.isEmpty ? null : why,
    );
  }
}
