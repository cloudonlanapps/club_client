import 'package:cl_club_events/src/models/programme_schedule_form_helpers.dart';
import 'package:cl_club_events/src/utils/programme_end_date.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/programme_fixtures.dart';
import '../support/recording_schedule_events.dart';

/// The local calendar day [days] from today.
DateTime _day(int days) {
  final t = localNoon(days);
  return DateTime(t.year, t.month, t.day);
}

/// The first day from [fromDays] days ahead that falls on [weekday].
int _daysUntil(int weekday, {int fromDays = 1}) {
  var days = fromDays;
  while (localNoon(days).weekday != weekday) {
    days++;
  }
  return days;
}

void main() {
  group('Issue 39: the cutoff a chosen last day gives', () {
    test('Issue 39: the cutoff is the first session start after the end of '
        'the chosen day', () {
      final event = programmeFixture();

      expect(programmeEndCutoff(event, _day(5)), localNoon(6).toUtc());
      expect(
        programmeEndCutoff(event, _day(0)),
        localNoon(1).toUtc(),
        reason: 'today as the last day ends before tomorrow',
      );
    });

    test('Issue 39: a last day between sessions ends before the next one, '
        'and the last session is the one before it', () {
      final event = programmeFixture(rrule: 'FREQ=WEEKLY;BYDAY=SA');
      final saturday = _daysUntil(DateTime.saturday, fromDays: 8);
      // The Monday after that Saturday.
      final cutoff = programmeEndCutoff(event, _day(saturday + 2));

      expect(cutoff, localNoon(saturday + 7).toUtc());
      expect(
        programmeLastSessionBefore(event, cutoff!),
        localNoon(saturday).toUtc(),
      );
      expect(
        programmeEndResultLine(event, _day(saturday + 2)),
        'Last session: '
        '${programmeEndDayFormat.format(localNoon(saturday))}.',
      );
    });

    test('Issue 39: the result line is written as "Sat 14 Nov 2026"', () {
      expect(
        programmeEndDayFormat.format(DateTime(2026, 11, 14)),
        'Sat 14 Nov 2026',
      );
    });

    test('Issue 39: with a change pending, the cutoff is a session of the '
        'pending schedule', () {
      final event = programmeFixture();
      final pendingFrom = localNoon(10).toUtc();
      final schedules = [
        scheduleFixture(21, localNoon(-20).toUtc(), until: pendingFrom),
        scheduleFixture(22, pendingFrom),
      ];

      expect(
        programmeEndCutoff(event, _day(3), schedules: schedules),
        pendingFrom,
      );
    });
  });

  group('Issue 39: the end date as the Schedule block reads it', () {
    test('Issue 39: a programme with no end reads "No end date"', () {
      expect(programmeEndDateLine(programmeFixture()), 'No end date');
      expect(programmeEndDay(programmeFixture()), isNull);
      expect(programmeHasEnded(programmeFixture()), isFalse);
    });

    test('Issue 39: an end ahead reads as the day of the last session', () {
      final event = programmeFixture(untilTimeUtc: localNoon(6).toUtc());

      expect(
        programmeEndDateLine(event),
        'End date: ${programmeEndDayFormat.format(localNoon(5))}',
      );
      expect(programmeEndDay(event), _day(5));
      expect(programmeHasEnded(event), isFalse);
    });

    test('Issue 39: an end that has passed has ended', () {
      final event = programmeFixture(untilTimeUtc: localNoon(-2).toUtc());

      expect(programmeHasEnded(event), isTrue);
    });
  });

  group('Issue 39: ProgrammeScheduleFormSubmit.adjustEndDate', () {
    test('Issue 39: a programme with no end is terminated at the cutoff of '
        'the chosen day, with the reason', () async {
      final event = programmeFixture();
      final notifier = RecordingScheduleEvents(event);

      await ProgrammeScheduleFormSubmit.adjustEndDate(
        event: event,
        lastDay: _day(5),
        reason: '  Season over ',
        notifier: notifier,
      );

      expect(notifier.endDateCalls, [
        'terminate(${localNoon(6).toUtc()}, Season over)',
      ]);
    });

    test('Issue 39: an end ahead is moved with extend, later or earlier, '
        'and a blank reason is not sent', () async {
      final event = programmeFixture(untilTimeUtc: localNoon(6).toUtc());
      final notifier = RecordingScheduleEvents(event);

      await ProgrammeScheduleFormSubmit.adjustEndDate(
        event: event,
        lastDay: _day(9),
        reason: ' ',
        notifier: notifier,
      );
      await ProgrammeScheduleFormSubmit.adjustEndDate(
        event: event,
        lastDay: _day(2),
        reason: 'Rink closes early',
        notifier: notifier,
      );

      expect(notifier.endDateCalls, [
        'extend(${localNoon(10).toUtc()}, null)',
        'extend(${localNoon(3).toUtc()}, Rink closes early)',
      ]);
    });

    test('Issue 39: the same end sends nothing', () async {
      final event = programmeFixture(untilTimeUtc: localNoon(6).toUtc());
      final notifier = RecordingScheduleEvents(event);

      final result = await ProgrammeScheduleFormSubmit.adjustEndDate(
        event: event,
        lastDay: _day(5),
        reason: '',
        notifier: notifier,
      );

      expect(result, same(event));
      expect(notifier.endDateCalls, isEmpty);
    });

    test('Issue 39: no last day clears the end', () async {
      final event = programmeFixture(untilTimeUtc: localNoon(6).toUtc());
      final notifier = RecordingScheduleEvents(event);

      await ProgrammeScheduleFormSubmit.adjustEndDate(
        event: event,
        lastDay: null,
        reason: '',
        notifier: notifier,
      );

      expect(notifier.endDateCalls, ['extendIndefinitely(null)']);
    });

    test('Issue 39: a day with no session after it is refused before any '
        'call', () async {
      final event = programmeFixture().copyWith(rrule: () => null);
      final notifier = RecordingScheduleEvents(event);

      await expectLater(
        ProgrammeScheduleFormSubmit.adjustEndDate(
          event: event,
          lastDay: _day(5),
          reason: 'Season over',
          notifier: notifier,
        ),
        throwsA(isA<SdkError>()),
      );
      expect(notifier.endDateCalls, isEmpty);
    });
  });
}
