import 'package:cl_club_forms/cl_club_forms.dart' show CampScheduleData;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart' show DateUtils;
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import '../utils/camp_rrule_validator.dart';
import '../utils/session_inputs.dart';

/// SDK ↔ `CampScheduleForm` adapter for the camp-event **schedule**
/// (reschedule) section — the one place that bridges the form's
/// [CampScheduleData] to the `cl_remote_store` reschedule / update calls.
/// Mirrors `camp_event_form_helpers.dart` (which owns the *metadata* sections).
///
/// The form is SDK-free in `ui_lib`; this helper owns the translation both
/// ways: [buildCampScheduleInitialValues] (SDK → form, the inverse of the
/// create flow's assembly) and [CampScheduleFormSubmit.updateSchedule]
/// (form → SDK).

final RruleUtil _rruleUtil = RruleUtil();

/// `COUNT=n` from an rrule, or `null` when absent. (The SDK's `rruleCount`
/// helper isn't exported, so we read it the same way here.)
int? _rruleCount(String rrule) {
  final match = RegExp(r'COUNT=(\d+)').firstMatch(rrule);
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// Builds the [CampScheduleData] that seeds `CampScheduleForm` from an existing
/// camp [event]. This is the exact inverse of the create flow's camp assembly
/// (`event_create_form_helpers.dart`), so opening the editor on an unedited
/// event round-trips to the same value — `isDirty` stays false and an
/// unmodified Save is a no-op.
CampScheduleData buildCampScheduleInitialValues(Event event) {
  final startLocal = event.startTimeUtc.toLocal();
  final startDate = DateTime(startLocal.year, startLocal.month, startLocal.day);
  final sessionStartTime = ShadTimeOfDay(
    hour: startLocal.hour,
    minute: startLocal.minute,
    second: 0,
  );
  final durationMinutes = event.endTimeUtc
      .difference(event.startTimeUtc)
      .inMinutes;

  // rrule is `FREQ=DAILY;COUNT=<total>` plus optional EXDATE rest days. The
  // EXDATEs were written as each rest day's local midnight converted to UTC
  // (the forward path's `_formatExdateUtc`), so convert back to the same
  // local date-only the exclusion calendar compares against.
  final (rrule, exdates) = _rruleUtil.parseRruleWithExdates(event.rrule ?? '');
  final totalDays = _rruleCount(rrule) ?? 1;
  final excludedDates = <DateTime>{
    for (final d in exdates) DateUtils.dateOnly(d.toLocal()),
  };
  final trainingDays = (totalDays - excludedDates.length).clamp(1, totalDays);

  // The named-session split, walked from the daily start time to match
  // `SessionSplitField.buildSessions` (HH:MM, names verbatim). A single
  // session is the trivial "no split" case the form represents as empty.
  return CampScheduleData(
    startDate: startDate,
    trainingDays: trainingDays,
    sessionStartTime: sessionStartTime,
    durationMinutes: durationMinutes,
    excludedDates: excludedDates,
    sessions: sessionInputsFromEventSessions(event.sessions, sessionStartTime),
  );
}

/// A short, user-facing reason the camp's schedule can't be rescheduled right
/// now, or `null` when it can. Mirrors the server's reschedule guards so we
/// never offer an edit the server will reject:
///
/// - a cancelled series is terminal (`isEventSeriesCancelled`);
/// - the series must not have started — the server rejects once the first
///   occurrence is in the past (or any attendance exists). We approximate with
///   the series anchor [Event.startTimeUtc]; if attendance pushes the server to
///   reject anyway, the caller surfaces a friendly error.
///
/// Drives the read-only lock hint shown to an admin who can't edit. Role gating
/// (admin) stays with the caller.
String? campRescheduleLockReason(Event event, {DateTime? now}) {
  if (isEventSeriesCancelled(event)) {
    return 'This series has been cancelled, so its schedule can no longer be '
        'edited.';
  }
  final nowUtc = (now ?? DateTime.now()).toUtc();
  if (!event.startTimeUtc.isAfter(nowUtc)) return campStartedMessage;
  return null;
}

/// Why a started camp's dates are fixed, and what can still change: its
/// timetable (club_core#85).
const String campStartedMessage =
    'This camp has started, so its dates can no longer be changed. Its '
    'timetable can still be corrected.';

/// Whether [event] is a camp that has started and is not cancelled: its
/// dates are fixed, and only its timetable can be corrected.
bool isCampTimetableOnly(Event event, {DateTime? now}) =>
    event.type == EventType.camp &&
    !isEventSeriesCancelled(event) &&
    !event.startTimeUtc.isAfter((now ?? DateTime.now()).toUtc());

/// Whether [event]'s schedule may be rescheduled right now — the inverse of a
/// non-null [campRescheduleLockReason].
bool canRescheduleCamp(Event event, {DateTime? now}) =>
    campRescheduleLockReason(event, now: now) == null;

/// Schedule fields assembled from a [CampScheduleData], ready for the SDK.
typedef CampScheduleFields = ({
  DateTime startUtc,
  DateTime endUtc,
  String rrule,
  List<EventSession> sessions,
});

/// Assembles a [CampScheduleData] into SDK schedule fields — the same shape the
/// create flow sends to `createEvent`.
CampScheduleFields assembleCampSchedule(CampScheduleData data) {
  final start = DateTime(
    data.startDate!.year,
    data.startDate!.month,
    data.startDate!.day,
    data.sessionStartTime!.hour,
    data.sessionStartTime!.minute,
  );
  final end = start.add(Duration(minutes: data.durationMinutes));
  final totalDays = data.trainingDays + data.excludedDates.length;
  final rrule = _rruleUtil.buildRruleWithExdates(
    'FREQ=DAILY;COUNT=$totalDays',
    data.excludedDates.toList()..sort(),
  );
  final rruleError = CampRruleValidator.validate(rrule);
  if (rruleError != null) throw ArgumentError(rruleError);
  return (
    startUtc: start.toUtc(),
    endUtc: end.toUtc(),
    rrule: rrule,
    sessions: eventSessionsFromSessionInputs(data.sessions),
  );
}

/// Bridges `CampScheduleForm` to the SDK reschedule call for a camp event.
class CampScheduleFormSubmit {
  const CampScheduleFormSubmit._();

  /// Applies an edited camp [data] to [event] via the master [notifier].
  ///
  /// When only the session split changed (window, rrule unchanged), the split
  /// is a timetable **correction**: it goes through `updateEvent(sessions:)`,
  /// which the server allows at any time, including after the camp has
  /// started (club_core#85).
  ///
  /// When the window changed, `sessions` is part of the schedule (server
  /// #248), so the whole change — start / end / rrule **and** the session
  /// split — lands in a single atomic `rescheduleEvent` call, allowed only
  /// before the camp starts. The server validates the supplied split against
  /// the new window and replaces the stored timetable in the same
  /// transaction. Either way an empty split clears the timetable.
  ///
  /// [resetOverrides] is forwarded to the reschedule: pass `true` (after the
  /// caller confirms with the admin) to discard per-occurrence edits and
  /// proceed.
  ///
  /// Sends [event]'s `version` (#68), so a camp changed since it was loaded
  /// is refused with `StaleVersionException`.
  ///
  /// Returns the latest [Event]. Throws on the server guards
  /// (`EVENT_ALREADY_STARTED`, `OCCURRENCE_OVERRIDES_PRESENT`,
  /// `INVALID_SESSIONS_TOTAL`, `STALE_VERSION`, …); the caller surfaces a friendly message /
  /// override-reset confirmation.
  static Future<Event> updateSchedule({
    required Event event,
    required CampScheduleData data,
    required ClEventsMasterNotifier notifier,
    bool resetOverrides = false,
  }) async {
    final next = assembleCampSchedule(data);
    final current = event.sessions ?? const <EventSession>[];
    final newSessions = next.sessions;

    final windowChanged =
        next.startUtc != event.startTimeUtc ||
        next.endUtc != event.endTimeUtc ||
        next.rrule != (event.rrule ?? '');
    final sessionsChanged = !listEquals(newSessions, current);

    if (!windowChanged && !sessionsChanged) {
      // Defensive: `isDirty` already prevents an unmodified Save from getting
      // here, but never issue a no-op reschedule.
      return event;
    }
    if (!windowChanged) {
      return notifier.updateEvent(
        event.id,
        version: event.version,
        sessions: () => newSessions.isEmpty ? null : newSessions,
      );
    }

    return notifier.rescheduleEvent(
      event.id,
      version: event.version,
      startTimeUtc: next.startUtc,
      endTimeUtc: next.endUtc,
      rrule: next.rrule,
      sessions: () => newSessions.isEmpty ? null : newSessions,
      resetOverrides: resetOverrides,
    );
  }
}
