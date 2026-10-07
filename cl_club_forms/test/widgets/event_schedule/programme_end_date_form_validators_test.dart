import 'package:cl_club_forms/src/widgets/event_schedule/programme_end_date_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 61: ProgrammeEndDateFormValidators.lastDay', () {
    const check = ProgrammeEndDateFormValidators.lastDay;
    final today = DateTime(2030, 5, 14, 16, 30);

    test('Issue 61: no day is refused as required', () {
      expect(
        check(null, today: today),
        ProgrammeEndDateFormValidators.dayRequiredMessage,
      );
    });

    test('Issue 61: yesterday is refused, even at its last minute', () {
      expect(
        check(DateTime(2030, 5, 13, 23, 59), today: today),
        ProgrammeEndDateFormValidators.dayInPastMessage,
      );
    });

    test('Issue 61: today is accepted at any time of day', () {
      expect(check(DateTime(2030, 5, 14), today: today), isNull);
      expect(check(DateTime(2030, 5, 14, 23, 59), today: today), isNull);
    });

    test('Issue 61: a later day is accepted', () {
      expect(check(DateTime(2030, 5, 15), today: today), isNull);
      expect(check(DateTime(2031), today: today), isNull);
    });

    test('Issue 61: without a today it measures from now', () {
      final now = DateTime.now();
      expect(check(now), isNull);
      expect(
        check(now.subtract(const Duration(days: 2))),
        ProgrammeEndDateFormValidators.dayInPastMessage,
      );
    });
  });

  group('Issue 61: ProgrammeEndDateFormValidators.reason', () {
    const check = ProgrammeEndDateFormValidators.reason;
    const max = ProgrammeEndDateFormValidators.reasonMaxLength;

    test('Issue 61: a required reason refuses null, empty and blanks', () {
      const refused = ProgrammeEndDateFormValidators.reasonRequiredMessage;
      expect(check(null, required: true), refused);
      expect(check('', required: true), refused);
      expect(check('   ', required: true), refused);
      expect(check('Season over', required: true), isNull);
    });

    test('Issue 61: an optional reason may be left out', () {
      expect(check(null, required: false), isNull);
      expect(check('', required: false), isNull);
      expect(check('   ', required: false), isNull);
    });

    test('Issue 61: a reason is at most 500 characters, counted trimmed', () {
      expect(max, 500);
      expect(check('x' * max, required: true), isNull);
      expect(check('  ${'x' * max}  ', required: false), isNull);
      for (final required in [true, false]) {
        expect(
          check('x' * (max + 1), required: required),
          ProgrammeEndDateFormValidators.reasonTooLongMessage,
        );
      }
    });
  });
}
