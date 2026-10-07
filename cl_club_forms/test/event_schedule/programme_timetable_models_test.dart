// The form-local values the timetable and programme schedule forms take and
// return: equality (which the forms' dirty checks rest on) and `copyWith`.
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventTimetableValue,
        ProgrammeScheduleAdjustValue,
        ProgrammeScheduleData,
        SessionInput,
        TimetableScheduleOption;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

const ShadTimeOfDay _six = ShadTimeOfDay(hour: 6, minute: 0, second: 0);
const SessionInput _warmUp = SessionInput(
  name: 'Warm-up',
  startTime: '06:00',
  endTime: '06:30',
);

ProgrammeScheduleData _schedule() => ProgrammeScheduleData(
  weekdays: const {DateTime.monday, DateTime.thursday},
  startDate: DateTime(2030, 5),
  endDate: DateTime(2030, 9),
  hasNoEndDate: false,
  sessionStartTime: _six,
  totalDurationMinutes: 30,
  sessions: [_warmUp.copyWith()],
);

void main() {
  group('Issue 61: SessionInput', () {
    test('Issue 61: equal when name and both times are', () {
      expect(_warmUp.copyWith(), _warmUp);
      expect(_warmUp.copyWith().hashCode, _warmUp.hashCode);
      expect(_warmUp.copyWith(name: 'Stretch'), isNot(_warmUp));
      expect(_warmUp.copyWith(startTime: '06:05'), isNot(_warmUp));
      expect(_warmUp.copyWith(endTime: '06:35'), isNot(_warmUp));
    });

    test('Issue 61: copyWith changes only what it is given', () {
      expect(
        _warmUp.copyWith(endTime: '07:00'),
        const SessionInput(
          name: 'Warm-up',
          startTime: '06:00',
          endTime: '07:00',
        ),
      );
    });
  });

  group('Issue 61: ProgrammeScheduleData', () {
    test('Issue 61: defaults to an ongoing hour with nothing chosen', () {
      const empty = ProgrammeScheduleData();
      expect(empty.weekdays, isEmpty);
      expect(empty.startDate, isNull);
      expect(empty.endDate, isNull);
      expect(empty.hasNoEndDate, isTrue);
      expect(empty.sessionStartTime, isNull);
      expect(empty.totalDurationMinutes, 60);
      expect(empty.sessions, isEmpty);
    });

    test('Issue 61: equal whatever the order of the weekdays', () {
      final other = _schedule().copyWith(
        weekdays: {DateTime.thursday, DateTime.monday},
      );
      expect(other, _schedule());
      expect(other.hashCode, _schedule().hashCode);
    });

    test('Issue 61: differs when any one part does', () {
      final base = _schedule();
      for (final changed in [
        base.copyWith(weekdays: {DateTime.monday}),
        base.copyWith(startDate: () => DateTime(2030, 5, 2)),
        base.copyWith(endDate: () => DateTime(2030, 10)),
        base.copyWith(hasNoEndDate: true),
        base.copyWith(
          sessionStartTime: () =>
              const ShadTimeOfDay(hour: 7, minute: 0, second: 0),
        ),
        base.copyWith(totalDurationMinutes: 45),
        base.copyWith(sessions: const []),
        base.copyWith(sessions: [_warmUp.copyWith(name: 'Stretch')]),
      ]) {
        expect(changed, isNot(base), reason: '$changed');
      }
    });

    test('Issue 61: copyWith can clear the dates and the start time', () {
      final cleared = _schedule().copyWith(
        startDate: () => null,
        endDate: () => null,
        sessionStartTime: () => null,
      );
      expect(cleared.startDate, isNull);
      expect(cleared.endDate, isNull);
      expect(cleared.sessionStartTime, isNull);
      expect(cleared.weekdays, _schedule().weekdays);
      expect(cleared.sessions, _schedule().sessions);
    });
  });

  group('Issue 61: ProgrammeScheduleAdjustValue', () {
    final from = DateTime.utc(2030, 5, 13, 6);
    ProgrammeScheduleAdjustValue value() => ProgrammeScheduleAdjustValue(
      from: from,
      schedule: _schedule(),
      venueId: 7,
    );

    test('Issue 61: equal when From, the schedule and the venue are', () {
      expect(value(), value());
      expect(value().hashCode, value().hashCode);
      expect(
        value().copyWith(from: () => from.add(const Duration(days: 3))),
        isNot(value()),
      );
      expect(value().copyWith(venueId: () => 9), isNot(value()));
      expect(
        value().copyWith(
          schedule: _schedule().copyWith(totalDurationMinutes: 45),
        ),
        isNot(value()),
      );
    });

    test('Issue 61: copyWith can clear From and the venue', () {
      final cleared = value().copyWith(from: () => null, venueId: () => null);
      expect(cleared.from, isNull);
      expect(cleared.venueId, isNull);
      expect(cleared.schedule, _schedule());
    });
  });

  group('Issue 61: TimetableScheduleOption and EventTimetableValue', () {
    TimetableScheduleOption option({
      int? id = 11,
      String label = 'current',
      int totalMinutes = 30,
      List<SessionInput>? sessions,
    }) => TimetableScheduleOption(
      id: id,
      label: label,
      startTime: _six,
      totalMinutes: totalMinutes,
      sessions: sessions ?? [_warmUp.copyWith()],
    );

    test('Issue 61: a schedule option has no id and no split by default', () {
      const plain = TimetableScheduleOption(
        label: 'the camp',
        startTime: _six,
        totalMinutes: 120,
      );
      expect(plain.id, isNull);
      expect(plain.sessions, isEmpty);
    });

    test('Issue 61: schedule options are equal when every part is', () {
      expect(option(), option());
      expect(option().hashCode, option().hashCode);
      expect(option(id: null), isNot(option()));
      expect(option(label: 'earlier'), isNot(option()));
      expect(option(totalMinutes: 60), isNot(option()));
      expect(option(sessions: const []), isNot(option()));
    });

    test('Issue 61: timetable values are equal when the schedule and the '
        'split are', () {
      EventTimetableValue value({int? scheduleId = 11, String name = 'A'}) =>
          EventTimetableValue(
            scheduleId: scheduleId,
            sessions: [_warmUp.copyWith(name: name)],
          );
      expect(value(), value());
      expect(value().hashCode, value().hashCode);
      expect(value(scheduleId: null), isNot(value()));
      expect(value(name: 'B'), isNot(value()));
      expect(
        const EventTimetableValue(sessions: []).scheduleId,
        isNull,
      );
    });
  });
}
