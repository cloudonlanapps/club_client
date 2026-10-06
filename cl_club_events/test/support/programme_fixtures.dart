import 'package:club_sdk_2/club_sdk_2.dart';

/// Local noon, [days] from today: far from midnight, so the local and UTC
/// weekdays agree wherever the tests run.
DateTime localNoon(int days) {
  final t = DateTime.now().add(Duration(days: days));
  return DateTime(t.year, t.month, t.day, 12);
}

/// A one-hour programme on every weekday, whose current schedule started
/// [startedDaysAgo] days ago at local noon.
Event programmeFixture({
  int startedDaysAgo = 20,
  String rrule = 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU',
  List<EventSession>? sessions,
  DateTime? untilTimeUtc,
}) {
  final start = localNoon(-startedDaysAgo).toUtc();
  return Event(
    id: 1,
    version: 4,
    title: 'workflow_adjustprog',
    description: '',
    type: EventType.programme,
    visibility: Visibility.public,
    venueId: 7,
    startTimeUtc: start,
    endTimeUtc: start.add(const Duration(hours: 1)),
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
    rrule: rrule,
    sessions: sessions,
    untilTimeUtc: untilTimeUtc,
  );
}

/// A schedule of [programmeFixture]'s event taking effect at [from].
EventSchedule scheduleFixture(
  int id,
  DateTime from, {
  DateTime? until,
  String rrule = 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU',
}) => EventSchedule(
  id: id,
  eventId: 1,
  effectiveFromUtc: from,
  effectiveUntilUtc: until,
  startTimeUtc: from,
  endTimeUtc: from.add(const Duration(hours: 1)),
  venueId: 7,
  rrule: rrule,
);
