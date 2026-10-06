import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show DateFormat;

import 'programme_schedule_sessions.dart';

/// A programme's end date, as its Schedule block reads and sets it.
///
/// The server keeps the end as a **cutoff** (`Event.untilTimeUtc`): a
/// session start of the current schedule from which sessions no longer
/// occur. The admin thinks in days: the last day the programme runs. These
/// helpers turn one into the other.

/// Why a programme whose end has passed offers no end-date change.
const String programmeEndedMessage =
    'This programme has ended; create a new programme';

/// Shown when the chosen day leaves the schedule no session to end before.
const String programmeEndDateNoSessionMessage =
    'The schedule has no session after that day to end before. Pick another '
    'day.';

/// Shown in the Schedule block of a programme that has no end.
const String programmeNoEndDateLine = 'No end date';

/// How far around a day or a cutoff the nearest session is looked for: two
/// weeks, twice the period of a weekly rule.
const Duration programmeEndSearchSpan = Duration(days: 14);

/// How a last session is written, e.g. `Sat 14 Nov 2026`.
final DateFormat programmeEndDayFormat = DateFormat('EEE d MMM y');

/// Whether [event]'s end has passed: nothing about its end can change any
/// more.
bool programmeHasEnded(Event event, {DateTime? now}) {
  final until = event.untilTimeUtc;
  if (until == null) return false;
  return !until.isAfter((now ?? DateTime.now()).toUtc());
}

/// The cutoff that makes the local day [lastDay] the last one [event] runs
/// on: the first session start of its current schedule after the end of
/// that day. `null` when the schedule has no session after it.
DateTime? programmeEndCutoff(
  Event event,
  DateTime lastDay, {
  List<EventSchedule>? schedules,
}) {
  final nextDay = DateTime(lastDay.year, lastDay.month, lastDay.day + 1);
  final starts = programmeSessionStarts(
    event,
    fromUtc: nextDay.toUtc(),
    toUtc: nextDay.toUtc().add(programmeEndSearchSpan),
    schedules: schedules,
    limit: 1,
  );
  return starts.isEmpty ? null : starts.first;
}

/// The last session start of [event]'s current schedule before
/// [cutoffUtc]: the last session a programme ending there holds. `null`
/// when the schedule has none before it.
DateTime? programmeLastSessionBefore(
  Event event,
  DateTime cutoffUtc, {
  List<EventSchedule>? schedules,
}) {
  final starts = programmeSessionStarts(
    event,
    fromUtc: cutoffUtc.subtract(programmeEndSearchSpan),
    toUtc: cutoffUtc,
    schedules: schedules,
  );
  return starts.isEmpty ? null : starts.last;
}

/// What ending [event] on the local day [lastDay] gives, stated before it
/// is saved: `Last session: Sat 14 Nov 2026.`
String programmeEndResultLine(
  Event event,
  DateTime lastDay, {
  List<EventSchedule>? schedules,
}) {
  final cutoff = programmeEndCutoff(event, lastDay, schedules: schedules);
  final last = cutoff == null
      ? null
      : programmeLastSessionBefore(event, cutoff, schedules: schedules);
  if (last == null) return 'No session takes place on or before that day.';
  return 'Last session: ${programmeEndDayFormat.format(last.toLocal())}.';
}

/// The end-date line of [event]'s Schedule block: the day of its last
/// session, or [programmeNoEndDateLine].
String programmeEndDateLine(Event event, {List<EventSchedule>? schedules}) {
  final until = event.untilTimeUtc;
  if (until == null) return programmeNoEndDateLine;
  final last = programmeLastSessionBefore(event, until, schedules: schedules);
  // With no session before the cutoff, the day before it is the last day
  // the programme could have run on.
  final day = last ?? until.subtract(const Duration(days: 1));
  return 'End date: ${programmeEndDayFormat.format(day.toLocal())}';
}

/// The local day [event] ends on now (the day of its last session), or
/// `null` when it has no end.
DateTime? programmeEndDay(Event event, {List<EventSchedule>? schedules}) {
  final until = event.untilTimeUtc;
  if (until == null) return null;
  final last =
      programmeLastSessionBefore(event, until, schedules: schedules) ??
      until.subtract(const Duration(days: 1));
  final local = last.toLocal();
  return DateTime(local.year, local.month, local.day);
}
