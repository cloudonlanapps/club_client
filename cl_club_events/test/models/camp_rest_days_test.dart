// The server removes an occurrence only when an EXDATE equals its start
// instant, so a rest day is sent as the UTC start of the session it removes.
// A camp's COUNT is the days it is held: rest days are not counted
// (club_client#122, club_server#30).
import 'package:cl_club_events/src/models/camp_schedule_form_helpers.dart';
import 'package:cl_club_events/src/utils/camp_rest_days.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show CampScheduleData, EventFormType;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import '../support/recording_create_events.dart';

/// A camp from Monday 19 October 2026 at five in the afternoon, four
/// training days, resting on Wednesday 21.
final CampScheduleData _camp = CampScheduleData(
  startDate: DateTime(2026, 10, 19),
  trainingDays: 4,
  sessionStartTime: const ShadTimeOfDay(hour: 17, minute: 0, second: 0),
  durationMinutes: 60,
  excludedDates: {DateTime(2026, 10, 21)},
);

/// The start of the session the rest day removes.
final DateTime _restDaySession = DateTime(2026, 10, 21, 17).toUtc();

List<DateTime> _exdatesOf(String? rrule) =>
    RruleUtil().parseRruleWithExdates(rrule ?? '').$2;

void main() {
  test("Issue 122: a camp's rest day is sent as the start of the session "
      'it removes', () {
    final fields = assembleCampSchedule(_camp);

    expect(_exdatesOf(fields.rrule), [_restDaySession]);
  });

  test("Issue 122: a created camp's rest day is sent as the start of the "
      'session it removes', () async {
    final sent = await createWith(EventFormType.camp, _camp);

    expect(_exdatesOf(sent.rrule), [_restDaySession]);
  });

  test("Issue 122: a camp's COUNT is its training days, rest days not "
      'counted', () {
    final fields = assembleCampSchedule(_camp);

    expect(fields.rrule, startsWith('FREQ=DAILY;COUNT=4'));
  });

  test('Issue 122: a rule of four days held and one rest day opens as '
      'four training days', () {
    final opened = buildCampScheduleInitialValues(
      _campEvent('FREQ=DAILY;COUNT=4\nEXDATE:${_exdate(_restDaySession)}'),
    );

    expect(opened.trainingDays, 4);
    expect(opened.excludedDates, {DateTime(2026, 10, 21)});
  });

  test('Issue 122: a camp opens as the schedule that was saved', () {
    final fields = assembleCampSchedule(_camp);
    final saved = _campEvent(fields.rrule);

    expect(buildCampScheduleInitialValues(saved), _camp);
  });

  test('Issue 122: an excluded instant that is no session start is not a '
      'rest day', () {
    // What the app sent before: the rest day's local midnight.
    final midnight = DateTime(2026, 10, 21).toUtc();
    final opened = buildCampScheduleInitialValues(
      _campEvent('FREQ=DAILY;COUNT=5\nEXDATE:${_exdate(midnight)}'),
    );

    expect(opened.trainingDays, 5);
    expect(opened.excludedDates, isEmpty);
  });

  test('Issue 122: a camp spans its days held and its rest days', () {
    final start = DateTime(2026, 10, 19, 17).toUtc();
    final rrule = assembleCampSchedule(_camp).rrule;

    expect(campSpanDays(rrule, start), 5);
    expect(campSpanDays('FREQ=DAILY;COUNT=4', start), 4);
    expect(campSpanDays(null, start), isNull);
  });

  test('Issue 122: a rest day past the last day held removes nothing', () {
    final start = DateTime(2026, 10, 19, 17).toUtc();
    final after = start.add(const Duration(days: 6));

    expect(
      campRestDayOffsets('FREQ=DAILY;COUNT=4\nEXDATE:${_exdate(after)}', start),
      isEmpty,
    );
  });

  test('Issue 122: a rescheduled camp moves its rest day to the new session '
      'start', () {
    final fields = assembleCampSchedule(
      _camp.copyWith(
        sessionStartTime: () =>
            const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
      ),
    );

    expect(_exdatesOf(fields.rrule), [DateTime(2026, 10, 21, 9).toUtc()]);
  });
}

/// A camp event from Monday 19 October 2026 at five, an hour a day, on
/// [rrule].
Event _campEvent(String rrule) => Event(
  id: 1,
  title: 'Camp',
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: DateTime(2026, 10, 19, 17).toUtc(),
  endTimeUtc: DateTime(2026, 10, 19, 18).toUtc(),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  rrule: rrule,
);

/// [instant] as an `EXDATE` value.
String _exdate(DateTime instant) =>
    RruleUtil().buildRruleWithExdates('', [instant]).split('EXDATE:').last;
