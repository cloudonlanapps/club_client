// The values the camp and one-off schedule forms return. Their equality is
// what the forms' `isDirty` rests on.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _nine = ShadTimeOfDay(hour: 9, minute: 0, second: 0);
const _a = SessionInput(name: 'A', startTime: '09:00', endTime: '09:30');
const _b = SessionInput(name: 'B', startTime: '09:30', endTime: '11:00');

CampScheduleData _camp() => CampScheduleData(
  startDate: DateTime(2026, 8, 3),
  trainingDays: 5,
  sessionStartTime: _nine,
  durationMinutes: 120,
  excludedDates: {DateTime(2026, 8, 5), DateTime(2026, 8, 6)},
  sessions: const [_a, _b],
);

OneOffScheduleData _oneOff() =>
    OneOffScheduleData(date: DateTime(2030, 5, 14), startTime: _nine);

void main() {
  group('CampScheduleData', () {
    test('Issue 61: an empty one is seven training days of two hours with '
        'no date, time, rest day or split', () {
      const empty = CampScheduleData();
      expect(empty.startDate, isNull);
      expect(empty.sessionStartTime, isNull);
      expect(empty.trainingDays, 7);
      expect(empty.durationMinutes, 120);
      expect(empty.excludedDates, isEmpty);
      expect(empty.sessions, isEmpty);
    });

    test('Issue 61: two with the same content are equal, with one hash', () {
      expect(_camp(), _camp());
      expect(_camp().hashCode, _camp().hashCode);
    });

    test('Issue 61: the order of the rest days does not matter', () {
      final reversed = _camp().copyWith(
        excludedDates: {DateTime(2026, 8, 6), DateTime(2026, 8, 5)},
      );
      expect(reversed, _camp());
      expect(reversed.hashCode, _camp().hashCode);
    });

    test('Issue 61: the order of the sessions does matter', () {
      expect(_camp().copyWith(sessions: const [_b, _a]), isNot(_camp()));
    });

    test('Issue 61: a difference in any one part makes them unequal', () {
      final base = _camp();
      for (final other in [
        base.copyWith(startDate: () => DateTime(2026, 8, 4)),
        base.copyWith(startDate: () => null),
        base.copyWith(trainingDays: 6),
        base.copyWith(
          sessionStartTime: () =>
              const ShadTimeOfDay(hour: 9, minute: 15, second: 0),
        ),
        base.copyWith(sessionStartTime: () => null),
        base.copyWith(durationMinutes: 90),
        base.copyWith(excludedDates: {DateTime(2026, 8, 5)}),
        base.copyWith(
          excludedDates: {DateTime(2026, 8, 5), DateTime(2026, 8, 7)},
        ),
        base.copyWith(sessions: const []),
        base.copyWith(sessions: const [_a]),
        base.copyWith(
          sessions: [
            _a,
            _b.copyWith(name: 'C'),
          ],
        ),
      ]) {
        expect(other, isNot(base), reason: '$other');
      }
    });

    test('Issue 61: copyWith with nothing given changes nothing', () {
      expect(_camp().copyWith(), _camp());
    });
  });

  group('OneOffScheduleData', () {
    test('Issue 61: an empty one is two hours with no date or time', () {
      const empty = OneOffScheduleData();
      expect(empty.date, isNull);
      expect(empty.startTime, isNull);
      expect(empty.durationMinutes, 120);
    });

    test('Issue 61: equal by date, start time and duration', () {
      final base = _oneOff();
      expect(_oneOff(), base);
      expect(_oneOff().hashCode, base.hashCode);
      expect(base.copyWith(), base);
      for (final other in [
        base.copyWith(date: () => DateTime(2030, 5, 15)),
        base.copyWith(date: () => null),
        base.copyWith(startTime: () => null),
        base.copyWith(
          startTime: () => const ShadTimeOfDay(hour: 10, minute: 0, second: 0),
        ),
        base.copyWith(durationMinutes: 60),
      ]) {
        expect(other, isNot(base), reason: '$other');
      }
    });
  });

  group('OneOffScheduleValue', () {
    OneOffScheduleValue value() => OneOffScheduleValue(
      schedule: _oneOff(),
      venueId: 7,
      sessions: const [_a, _b],
    );

    test('Issue 61: a new one has no venue and no split', () {
      final fresh = OneOffScheduleValue(schedule: _oneOff());
      expect(fresh.venueId, isNull);
      expect(fresh.sessions, isEmpty);
    });

    test('Issue 61: equal by schedule, venue and sessions in order', () {
      final base = value();
      expect(value(), base);
      expect(value().hashCode, base.hashCode);
      expect(base.copyWith(), base);
      for (final other in [
        base.copyWith(schedule: _oneOff().copyWith(durationMinutes: 60)),
        base.copyWith(venueId: () => 9),
        base.copyWith(venueId: () => null),
        base.copyWith(sessions: const []),
        base.copyWith(sessions: const [_b, _a]),
      ]) {
        expect(other, isNot(base), reason: '$other');
      }
    });
  });
}
