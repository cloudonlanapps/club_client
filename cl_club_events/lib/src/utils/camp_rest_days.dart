import 'package:club_sdk_2/club_sdk_2.dart' show RruleUtil;

/// A camp's rule, as the server reads it (camp R19a, club_client#122): one
/// session a day from the camp's first, `COUNT` of them **held**. A rest day
/// is an `EXDATE` equal to the start instant of the session it removes; it is
/// not counted in `COUNT`, so the camp spans the days held plus its rest
/// days.

/// The rule of a camp of [trainingDays] days held, whose first session
/// starts at [startTimeUtc] on the local day [startDate], resting on
/// [restDays] (local days): `FREQ=DAILY;COUNT=<trainingDays>` and one
/// `EXDATE` per rest day, at the start of the session that day would hold.
String campRruleFor({
  required DateTime startTimeUtc,
  required DateTime startDate,
  required int trainingDays,
  required Iterable<DateTime> restDays,
}) => RruleUtil().buildRruleWithExdates('FREQ=DAILY;COUNT=$trainingDays', [
  for (final day in restDays)
    startTimeUtc.toUtc().add(Duration(days: campDayOffset(startDate, day))),
]);

/// How many calendar days [day] is after [startDate], both read as local
/// days.
int campDayOffset(DateTime startDate, DateTime day) =>
    DateTime.utc(
          day.year,
          day.month,
          day.day,
        )
        .difference(
          DateTime.utc(startDate.year, startDate.month, startDate.day),
        )
        .inDays;

/// The days held a camp [rrule] names in `COUNT`, or `null` when it names
/// none.
int? campDaysHeld(String? rrule) {
  final match = RegExp(r'COUNT=(\d+)').firstMatch(rrule ?? '');
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// The rest days of a camp, as day offsets from its first session at
/// [startTimeUtc]: the `EXDATE`s of [rrule] that equal a session start
/// inside the camp's span. An `EXDATE` at any other instant removes no
/// session, and is no rest day.
Set<int> campRestDayOffsets(String? rrule, DateTime startTimeUtc) {
  final held = campDaysHeld(rrule);
  if (held == null) return const <int>{};
  final start = startTimeUtc.toUtc();
  final candidates = <int>{
    for (final exdate in RruleUtil().parseRruleWithExdates(rrule!).$2)
      if (!exdate.isBefore(start) &&
          exdate.difference(start).inMicroseconds %
                  Duration.microsecondsPerDay ==
              0)
        exdate.difference(start).inDays,
  };
  // Walk the days as the server does: a rest day past the last day held
  // removes nothing.
  final rest = <int>{};
  var remaining = held;
  for (var offset = 0; remaining > 0; offset++) {
    if (candidates.contains(offset)) {
      rest.add(offset);
    } else {
      remaining--;
    }
  }
  return rest;
}

/// The calendar days a camp spans, first to last day held: its days held
/// plus its rest days. `null` when [rrule] names no `COUNT`.
int? campSpanDays(String? rrule, DateTime startTimeUtc) {
  final held = campDaysHeld(rrule);
  if (held == null) return null;
  return held + campRestDayOffsets(rrule, startTimeUtc).length;
}
