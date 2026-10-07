import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserFormAssembly.floorToUtcMidnight', () {
    test('Issue 230: null in → null out', () {
      expect(UserFormAssembly.floorToUtcMidnight(null), isNull);
    });

    test(
      'Issue 230: local DateTime is floored to UTC midnight of the same '
      'calendar date',
      () {
        // The DOB picker emits a local DateTime; storing that as an instant
        // shifts the calendar date by up to one day in any non-UTC TZ. The
        // floor utility must collapse it to UTC midnight of the picked date
        // regardless of the host's timezone.
        // Spelling out month/day keeps the boundary-date intent obvious even
        // though they match Dart's defaults.
        final picked = DateTime(2014, 1, 1);
        final floored = UserFormAssembly.floorToUtcMidnight(picked);

        expect(floored, isNotNull);
        expect(floored!.isUtc, isTrue);
        expect(floored.year, 2014);
        expect(floored.month, 1);
        expect(floored.day, 1);
        expect(floored.hour, 0);
        expect(floored.minute, 0);
        expect(floored.second, 0);
        expect(floored.millisecond, 0);
      },
    );

    test('Issue 230: already-UTC midnight DateTime round-trips unchanged', () {
      final utcMidnight = DateTime.utc(2017, 12, 31);
      final floored = UserFormAssembly.floorToUtcMidnight(utcMidnight);
      expect(floored, equals(utcMidnight));
    });

    test('Issue 230: non-midnight UTC DateTime is floored to UTC midnight', () {
      // Simulates the broken pipeline before the fix: a DOB stored as an
      // east-of-UTC instant (e.g. 2013-12-31 18:30 UTC for IST 1-Jan-2014).
      // Re-flooring it shouldn't shift the calendar day in the picker's TZ —
      // it should yield the UTC-day component of the input.
      final instant = DateTime.utc(2014, 6, 15, 5, 30);
      final floored = UserFormAssembly.floorToUtcMidnight(instant);
      expect(floored, equals(DateTime.utc(2014, 6, 15)));
    });
  });
}
