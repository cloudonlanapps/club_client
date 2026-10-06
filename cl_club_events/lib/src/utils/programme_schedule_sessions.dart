import 'package:club_sdk_2/club_sdk_2.dart';

/// Session starts and weekdays of a programme's **current** schedule: the
/// latest one, which the event itself describes and which decides what
/// happens from now on. The server accepts only a session start of that
/// schedule as the effective time of a split and as the cutoff of an end
/// date.

/// How far ahead of now the effective time of a split, or the cutoff of an
/// end date, must be for the server to accept it.
const Duration programmeChangeLeadTime = Duration(minutes: 30);

/// The `BYDAY` codes of a weekly rule, Monday first: index `weekday - 1`.
const List<String> programmeByDayCodes = [
  'MO',
  'TU',
  'WE',
  'TH',
  'FR',
  'SA',
  'SU',
];

/// The current schedule of a programme among its [schedules]: the latest.
/// `null` when they are not known.
EventSchedule? currentProgrammeSchedule(List<EventSchedule>? schedules) {
  if (schedules == null || schedules.isEmpty) return null;
  return schedules.reduce(
    (a, b) => b.effectiveFromUtc.isAfter(a.effectiveFromUtc) ? b : a,
  );
}

/// The session starts of [event]'s current schedule inside
/// `[fromUtc, toUtc)`, soonest first, at most [limit] of them.
///
/// The rule is expanded from the schedule's own start, as the server does,
/// and never before the schedule takes effect ([schedules], when known,
/// give that instant). The programme's end date is not applied: a session
/// at or after it is still a session start of the schedule.
List<DateTime> programmeSessionStarts(
  Event event, {
  required DateTime fromUtc,
  required DateTime toUtc,
  List<EventSchedule>? schedules,
  int? limit,
}) {
  final effectiveFrom = currentProgrammeSchedule(schedules)?.effectiveFromUtc;
  final lower = effectiveFrom != null && effectiveFrom.isAfter(fromUtc)
      ? effectiveFrom
      : fromUtc;
  if (!lower.isBefore(toUtc)) return const [];
  final rrule = event.rrule;
  if (rrule == null || rrule.isEmpty) {
    final only = event.startTimeUtc;
    final inside = !only.isBefore(lower) && only.isBefore(toUtc);
    return inside ? [only] : const [];
  }
  return RruleUtil()
      .expand(
        rrule: rrule,
        dtStart: event.startTimeUtc,
        fromUtc: lower,
        toUtc: toUtc,
        limit: limit,
      )
      .occurrences;
}

/// How many days the local calendar date of [instant] is ahead of its UTC
/// date: -1, 0 or 1. A weekly rule names its days in UTC, so a session held
/// early or late in the local day falls on a neighbouring UTC weekday.
int localDayShiftOf(DateTime instant) {
  final local = instant.toLocal();
  final utc = instant.toUtc();
  return DateTime.utc(
    local.year,
    local.month,
    local.day,
  ).difference(DateTime.utc(utc.year, utc.month, utc.day)).inDays;
}

/// The UTC weekdays (1 = Monday … 7 = Sunday) a weekly [rrule] names.
Set<int> programmeRuleWeekdays(String? rrule) {
  final match = RegExp(
    'BYDAY=([A-Z,]+)',
    caseSensitive: false,
  ).firstMatch(rrule ?? '');
  if (match == null) return const <int>{};
  return {
    for (final code in match.group(1)!.toUpperCase().split(','))
      if (programmeByDayCodes.contains(code))
        programmeByDayCodes.indexOf(code) + 1,
  };
}

/// [weekdays] moved by [days], staying inside 1 … 7.
Set<int> shiftWeekdays(Set<int> weekdays, int days) => {
  for (final day in weekdays) (day - 1 + days) % 7 + 1,
};

/// The local weekdays the sessions of [event]'s current schedule fall on.
Set<int> programmeLocalWeekdays(Event event) => shiftWeekdays(
  programmeRuleWeekdays(event.rrule),
  localDayShiftOf(event.startTimeUtc),
);

/// The weekly rule for sessions on the UTC [weekdays]: `FREQ=WEEKLY` naming
/// its days, with no count, end date, interval or excluded dates.
String programmeRruleFor(Set<int> weekdays) {
  final byDay = (weekdays.toList()..sort())
      .map((day) => programmeByDayCodes[day - 1])
      .join(',');
  return 'FREQ=WEEKLY;BYDAY=$byDay';
}

/// The schedule a programme's sessions follow at [now]: the latest of
/// [schedules] already in effect, or the first when none is yet.
EventSchedule? presentProgrammeSchedule(
  List<EventSchedule>? schedules, {
  DateTime? now,
}) {
  if (schedules == null || schedules.isEmpty) return null;
  final nowUtc = (now ?? DateTime.now()).toUtc();
  final ordered = [...schedules]
    ..sort((a, b) => a.effectiveFromUtc.compareTo(b.effectiveFromUtc));
  return ordered.lastWhere(
    (s) => !s.effectiveFromUtc.isAfter(nowUtc),
    orElse: () => ordered.first,
  );
}

/// The schedule a programme changes to next: its current (latest) one, when
/// that takes over from an earlier schedule after [now]. `null` when no
/// change is pending.
EventSchedule? pendingProgrammeSchedule(
  List<EventSchedule>? schedules, {
  DateTime? now,
}) {
  if (schedules == null || schedules.length < 2) return null;
  final nowUtc = (now ?? DateTime.now()).toUtc();
  final current = currentProgrammeSchedule(schedules)!;
  return current.effectiveFromUtc.isAfter(nowUtc) ? current : null;
}
