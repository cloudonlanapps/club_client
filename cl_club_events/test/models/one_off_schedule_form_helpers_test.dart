import 'package:cl_club_events/src/models/one_off_schedule_form_helpers.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show OneOffScheduleData, OneOffScheduleValue, SessionInput;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import '../support/recording_schedule_events.dart';

/// A local wall-clock start two days ahead, at 18:00.
DateTime _startLocal() {
  final day = DateTime.now().add(const Duration(days: 2));
  return DateTime(day.year, day.month, day.day, 18);
}

Event _oneOff({List<EventSession>? sessions, DateTime? startLocal}) {
  final start = (startLocal ?? _startLocal()).toUtc();
  return Event(
    id: 1,
    version: 4,
    title: 'workflow_moveoneoff',
    description: '',
    type: EventType.oneOff,
    visibility: Visibility.public,
    venueId: 7,
    startTimeUtc: start,
    endTimeUtc: start.add(const Duration(hours: 2)),
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
    sessions: sessions,
  );
}

const _split = [
  EventSession(name: 'Warm-up', periodMinutes: 30),
  EventSession(name: 'Match', periodMinutes: 90),
];

void main() {
  group('Issue 37: buildOneOffScheduleInitialValues', () {
    test('Issue 37: seeds the date, start time, duration, venue and '
        'sessions of the one-off', () {
      final start = _startLocal();
      final value = buildOneOffScheduleInitialValues(
        _oneOff(sessions: _split),
      );

      expect(value.schedule.date, DateTime(start.year, start.month, start.day));
      expect(
        value.schedule.startTime,
        const ShadTimeOfDay(hour: 18, minute: 0, second: 0),
      );
      expect(value.schedule.durationMinutes, 120);
      expect(value.venueId, 7);
      expect(value.sessions, const [
        SessionInput(name: 'Warm-up', startTime: '18:00', endTime: '18:30'),
        SessionInput(name: 'Match', startTime: '18:30', endTime: '20:00'),
      ]);
    });
  });

  group('Issue 37: OneOffScheduleFormSubmit.updateSchedule', () {
    test('Issue 37: an unedited schedule sends nothing', () async {
      final event = _oneOff(sessions: _split);
      final notifier = RecordingScheduleEvents(event);

      final result = await OneOffScheduleFormSubmit.updateSchedule(
        event: event,
        value: buildOneOffScheduleInitialValues(event),
        notifier: notifier,
      );

      expect(result, same(event));
      expect(notifier.reschedules, isEmpty);
    });

    test('Issue 37: a new date and time go in one reschedule with the '
        "event's version and no rrule", () async {
      final event = _oneOff();
      final notifier = RecordingScheduleEvents(event);
      final moved = _startLocal().add(const Duration(days: 3, hours: 1));

      await OneOffScheduleFormSubmit.updateSchedule(
        event: event,
        value: OneOffScheduleValue(
          schedule: OneOffScheduleData(
            date: DateTime(moved.year, moved.month, moved.day),
            startTime: ShadTimeOfDay(hour: moved.hour, minute: 0, second: 0),
            durationMinutes: 90,
          ),
          venueId: 7,
        ),
        notifier: notifier,
      );

      final call = notifier.reschedules.single;
      expect(call.version, 4);
      expect(call.startTimeUtc, moved.toUtc());
      expect(call.endTimeUtc, moved.toUtc().add(const Duration(minutes: 90)));
      expect(call.rrule, isNull, reason: 'a one-off does not recur');
      expect(call.venueId, isNull, reason: 'the venue did not change');
      expect(call.sessionsSent, isFalse, reason: 'the sessions did not change');
    });

    test('Issue 37: a new venue alone sends only the venue', () async {
      final event = _oneOff();
      final notifier = RecordingScheduleEvents(event);

      await OneOffScheduleFormSubmit.updateSchedule(
        event: event,
        value: buildOneOffScheduleInitialValues(event).copyWith(
          venueId: () => 9,
        ),
        notifier: notifier,
      );

      final call = notifier.reschedules.single;
      expect(call.venueId, 9);
      expect(call.startTimeUtc, isNull);
      expect(call.endTimeUtc, isNull);
      expect(call.rrule, isNull);
      expect(call.sessionsSent, isFalse);
    });

    test('Issue 37: new sessions are sent as durations, and an emptied '
        'split clears the timetable', () async {
      final event = _oneOff();
      final notifier = RecordingScheduleEvents(event);
      await OneOffScheduleFormSubmit.updateSchedule(
        event: event,
        value: buildOneOffScheduleInitialValues(event).copyWith(
          sessions: const [
            SessionInput(name: 'Warm-up', startTime: '18:00', endTime: '18:30'),
            SessionInput(name: 'Match', startTime: '18:30', endTime: '20:00'),
          ],
        ),
        notifier: notifier,
      );
      expect(notifier.reschedules.single.sessions, _split);
      expect(notifier.reschedules.single.rrule, isNull);

      final split = _oneOff(sessions: _split);
      final cleared = RecordingScheduleEvents(split);
      await OneOffScheduleFormSubmit.updateSchedule(
        event: split,
        value: buildOneOffScheduleInitialValues(split).copyWith(
          sessions: const [],
        ),
        notifier: cleared,
      );
      expect(cleared.reschedules.single.sessionsSent, isTrue);
      expect(cleared.reschedules.single.sessions, isNull);
    });
  });

  group('Issue 37: oneOffRescheduleLockReason', () {
    final now = DateTime.now();

    test('Issue 37: a one-off well ahead can be moved', () {
      expect(oneOffRescheduleLockReason(_oneOff(), now: now), isNull);
    });

    test('Issue 37: a started one-off is locked', () {
      final started = _oneOff(
        startLocal: now.subtract(const Duration(hours: 1)),
      );
      expect(
        oneOffRescheduleLockReason(started, now: now),
        oneOffStartedMessage,
      );
    });

    test('Issue 37: a called-off one-off is locked', () {
      expect(
        oneOffRescheduleLockReason(_oneOff(), calledOff: true, now: now),
        oneOffCalledOffMessage,
      );
    });

    test('Issue 37: a one-off starting in under 30 minutes is locked', () {
      final soon = _oneOff(startLocal: now.add(const Duration(minutes: 20)));
      expect(
        oneOffRescheduleLockReason(soon, now: now),
        oneOffStartsSoonMessage,
      );
    });
  });
}
