import 'package:cl_club_events/src/models/programme_schedule_form_helpers.dart';
import 'package:cl_club_events/src/utils/programme_schedule_sessions.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;
import 'package:ui_lib/ui_lib.dart'
    show ProgrammeScheduleAdjustValue, SessionInput;

import '../support/programme_fixtures.dart';
import '../support/recording_schedule_events.dart';

const _noon = ShadTimeOfDay(hour: 12, minute: 0, second: 0);

/// The adjust form's value for [event] as it opens, from its first option.
ProgrammeScheduleAdjustValue _seed(Event event) =>
    buildProgrammeScheduleAdjustInitialValues(
      event,
      fromOptions: programmeAdjustFromOptions(event),
    );

void main() {
  group('Issue 38: programmeAdjustFromOptions', () {
    test('Issue 38: offers only upcoming session starts of the current '
        'schedule, soonest first', () {
      final event = programmeFixture();
      final now = DateTime.now();

      final options = programmeAdjustFromOptions(event, now: now);

      expect(options, hasLength(programmeAdjustFromOptionCount));
      for (final option in options) {
        final local = option.toLocal();
        expect((local.hour, local.minute), (12, 0));
        expect(
          option.isBefore(now.toUtc().add(programmeChangeLeadTime)),
          isFalse,
          reason: 'at least 30 minutes ahead',
        );
      }
      expect(options, [...options]..sort());
    });

    test('Issue 38: a session starting in under 30 minutes is not offered', () {
      final event = programmeFixture();
      // Ten minutes before today's session.
      final now = localNoon(0).subtract(const Duration(minutes: 10));

      final options = programmeAdjustFromOptions(event, now: now);

      expect(options.first, localNoon(1).toUtc());
    });

    test('Issue 38: only the named weekdays are offered', () {
      final event = programmeFixture(rrule: 'FREQ=WEEKLY;BYDAY=MO,TH');

      final options = programmeAdjustFromOptions(event);

      expect(options, isNotEmpty);
      expect(
        options.map((o) => o.toLocal().weekday).toSet(),
        {DateTime.monday, DateTime.thursday},
      );
    });

    test('Issue 38: with a change pending, sessions before the pending '
        'schedule takes effect are not offered', () {
      final event = programmeFixture();
      final pendingFrom = localNoon(10).toUtc();

      final options = programmeAdjustFromOptions(
        event,
        schedules: [
          scheduleFixture(21, localNoon(-20).toUtc(), until: pendingFrom),
          scheduleFixture(22, pendingFrom),
        ],
      );

      expect(options.first, pendingFrom);
    });

    test('Issue 38: sessions at or after the end date are not offered', () {
      final event = programmeFixture(untilTimeUtc: localNoon(4).toUtc());

      final options = programmeAdjustFromOptions(event);

      expect(options, isNotEmpty);
      expect(options.last.isBefore(localNoon(4).toUtc()), isTrue);
    });
  });

  group('Issue 38: buildProgrammeScheduleInitialValues', () {
    test('Issue 38: seeds the weekdays, start time, duration and sessions', () {
      final value = buildProgrammeScheduleInitialValues(
        programmeFixture(
          rrule: 'FREQ=WEEKLY;BYDAY=MO,TH',
          sessions: const [
            EventSession(name: 'Skills', periodMinutes: 20),
            EventSession(name: 'Game', periodMinutes: 40),
          ],
        ),
      );

      expect(value.weekdays, {DateTime.monday, DateTime.thursday});
      expect(value.sessionStartTime, _noon);
      expect(value.totalDurationMinutes, 60);
      expect(value.sessions, const [
        SessionInput(name: 'Skills', startTime: '12:00', endTime: '12:20'),
        SessionInput(name: 'Game', startTime: '12:20', endTime: '13:00'),
      ]);
    });
  });

  group('Issue 38: ProgrammeScheduleFormSubmit.adjustSchedule', () {
    test('Issue 38: unchanged terms send nothing, whatever From is', () async {
      final event = programmeFixture();
      final notifier = RecordingScheduleEvents(event);
      final options = programmeAdjustFromOptions(event);

      final result = await ProgrammeScheduleFormSubmit.adjustSchedule(
        event: event,
        value: _seed(event).copyWith(from: () => options[3]),
        notifier: notifier,
      );

      expect(result, same(event));
      expect(notifier.futureUpdates, isEmpty);
    });

    test('Issue 38: new days go as a weekly rule naming its days, from the '
        "chosen session, with the event's version", () async {
      final event = programmeFixture();
      final notifier = RecordingScheduleEvents(event);
      final seed = _seed(event);

      await ProgrammeScheduleFormSubmit.adjustSchedule(
        event: event,
        value: seed.copyWith(
          schedule: seed.schedule.copyWith(
            weekdays: {DateTime.tuesday, DateTime.saturday},
          ),
        ),
        notifier: notifier,
      );

      final call = notifier.futureUpdates.single;
      expect(call.effectiveDateTimeUtc, seed.from);
      expect(call.version, 4);
      expect(call.rrule, 'FREQ=WEEKLY;BYDAY=TU,SA');
      expect(call.startTimeUtc, isNull);
      expect(call.endTimeUtc, isNull);
      expect(call.venueId, isNull);
      expect(call.sessionsSent, isFalse);
    });

    test('Issue 38: a new start time and duration are anchored on the From '
        "session's day", () async {
      final event = programmeFixture();
      final notifier = RecordingScheduleEvents(event);
      final seed = _seed(event);
      final fromLocal = seed.from!.toLocal();

      await ProgrammeScheduleFormSubmit.adjustSchedule(
        event: event,
        value: seed.copyWith(
          schedule: seed.schedule.copyWith(
            sessionStartTime: () =>
                const ShadTimeOfDay(hour: 14, minute: 30, second: 0),
            totalDurationMinutes: 90,
          ),
        ),
        notifier: notifier,
      );

      final call = notifier.futureUpdates.single;
      final start = DateTime(
        fromLocal.year,
        fromLocal.month,
        fromLocal.day,
        14,
        30,
      ).toUtc();
      expect(call.startTimeUtc, start);
      expect(call.endTimeUtc, start.add(const Duration(minutes: 90)));
      expect(call.rrule, isNull, reason: 'the days did not change');
    });

    test('Issue 38: a new venue alone sends only the venue', () async {
      final event = programmeFixture();
      final notifier = RecordingScheduleEvents(event);

      await ProgrammeScheduleFormSubmit.adjustSchedule(
        event: event,
        value: _seed(event).copyWith(venueId: () => 9),
        notifier: notifier,
      );

      final call = notifier.futureUpdates.single;
      expect(call.venueId, 9);
      expect(call.rrule, isNull);
      expect(call.startTimeUtc, isNull);
      expect(call.sessionsSent, isFalse);
    });

    test('Issue 38: new sessions are sent as durations', () async {
      final event = programmeFixture();
      final notifier = RecordingScheduleEvents(event);
      final seed = _seed(event);

      await ProgrammeScheduleFormSubmit.adjustSchedule(
        event: event,
        value: seed.copyWith(
          schedule: seed.schedule.copyWith(
            sessions: const [
              SessionInput(
                name: 'Skills',
                startTime: '12:00',
                endTime: '12:20',
              ),
              SessionInput(name: 'Game', startTime: '12:20', endTime: '13:00'),
            ],
          ),
        ),
        notifier: notifier,
      );

      expect(notifier.futureUpdates.single.sessions, const [
        EventSession(name: 'Skills', periodMinutes: 20),
        EventSession(name: 'Game', periodMinutes: 40),
      ]);
    });
  });

  group('Issue 38: programme weekdays', () {
    test('Issue 38: a weekly rule gives its days, and days give the rule', () {
      expect(programmeRuleWeekdays('FREQ=WEEKLY;BYDAY=MO,WE,SU'), {1, 3, 7});
      expect(programmeRuleWeekdays(null), isEmpty);
      expect(programmeRruleFor({7, 1, 3}), 'FREQ=WEEKLY;BYDAY=MO,WE,SU');
    });

    test('Issue 38: weekdays shift across the week boundary', () {
      expect(shiftWeekdays({1, 7}, 1), {2, 1});
      expect(shiftWeekdays({1, 7}, -1), {7, 6});
      expect(shiftWeekdays({3}, 0), {3});
    });
  });

  group('Issue 38: pending and present schedules', () {
    final first = scheduleFixture(21, localNoon(-20).toUtc());
    final next = scheduleFixture(22, localNoon(5).toUtc());

    test('Issue 38: a later schedule not yet in effect is pending', () {
      expect(pendingProgrammeSchedule([first, next]), next);
      expect(presentProgrammeSchedule([first, next]), first);
    });

    test('Issue 38: nothing is pending once the latest is in effect', () {
      final past = scheduleFixture(22, localNoon(-5).toUtc());
      expect(pendingProgrammeSchedule([first, past]), isNull);
      expect(pendingProgrammeSchedule([first]), isNull);
      expect(pendingProgrammeSchedule(null), isNull);
    });
  });
}
