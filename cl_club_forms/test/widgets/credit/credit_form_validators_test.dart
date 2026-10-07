import 'package:cl_club_forms/src/widgets/credit/credit_form_validators.dart'
    show CreditFormValidators;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 61: CreditFormValidators.credits', () {
    test('Issue 61: text that is not a whole number is refused', () {
      for (final text in ['', '   ', 'abc', '1.5', '1,000', '2 3']) {
        expect(
          CreditFormValidators.credits(text),
          'Enter a whole number',
          reason: '"$text"',
        );
      }
    });

    test('Issue 61: a number below the minimum is refused, the minimum '
        'itself accepted', () {
      expect(CreditFormValidators.credits('0'), 'At least 1');
      expect(CreditFormValidators.credits('-3'), 'At least 1');
      expect(CreditFormValidators.credits('1'), isNull);
      expect(CreditFormValidators.credits('-1', min: 0), 'At least 0');
      expect(CreditFormValidators.credits('0', min: 0), isNull);
    });

    test('Issue 61: a number above the cap is refused, the cap itself '
        'accepted', () {
      expect(CreditFormValidators.credits('6', max: 5), 'At most 5');
      expect(CreditFormValidators.credits('5', max: 5), isNull);
    });

    test('Issue 61: without a cap any number from the minimum passes', () {
      expect(CreditFormValidators.credits('100000'), isNull);
    });

    test('Issue 61: the number is read with its spaces trimmed', () {
      expect(CreditFormValidators.credits(' 4 ', max: 4), isNull);
    });
  });

  group('Issue 61: CreditFormValidators.reason', () {
    test('Issue 61: an empty or blank reason is refused', () {
      expect(CreditFormValidators.reason(''), 'A reason is required');
      expect(CreditFormValidators.reason(' \n '), 'A reason is required');
    });

    test('Issue 61: any text is a reason', () {
      expect(CreditFormValidators.reason(' x '), isNull);
    });
  });

  group('Issue 61: CreditFormValidators.requiredDate', () {
    test('Issue 61: no date is refused', () {
      expect(CreditFormValidators.requiredDate(null), 'Pick a date');
    });

    test('Issue 61: a date passes', () {
      expect(CreditFormValidators.requiredDate(DateTime(2026, 9, 26)), isNull);
    });
  });

  group('Issue 61: CreditFormValidators.extended', () {
    final end = DateTime(2026, 9, 26);

    test('Issue 61: the same day or an earlier one is not an extension', () {
      expect(
        CreditFormValidators.extended(until: end, currentValidUntil: end),
        CreditFormValidators.notExtendedMessage,
      );
      expect(
        CreditFormValidators.extended(
          until: DateTime(2026, 9, 25),
          currentValidUntil: end,
        ),
        CreditFormValidators.notExtendedMessage,
      );
    });

    test('Issue 61: the day after the current end is an extension', () {
      expect(
        CreditFormValidators.extended(
          until: DateTime(2026, 9, 27),
          currentValidUntil: end,
        ),
        isNull,
      );
    });
  });

  group('Issue 61: CreditFormValidators.window', () {
    final today = DateTime(2026, 9, 26);

    test('Issue 61: a window that ends before it starts is refused', () {
      expect(
        CreditFormValidators.window(
          from: DateTime(2026, 10, 2),
          until: DateTime(2026, 10),
          today: today,
        ),
        'Valid until must not be before from',
      );
    });

    test('Issue 61: a window that ended before today is refused', () {
      expect(
        CreditFormValidators.window(
          from: DateTime(2026, 9),
          until: DateTime(2026, 9, 25),
          today: today,
        ),
        'Valid until must not be in the past',
      );
    });

    test('Issue 61: a one-day window ending today passes', () {
      expect(
        CreditFormValidators.window(from: today, until: today, today: today),
        isNull,
      );
    });

    test('Issue 61: today is compared by its date, whatever the time', () {
      expect(
        CreditFormValidators.window(
          from: today,
          until: today,
          today: DateTime(2026, 9, 26, 23, 59),
        ),
        isNull,
      );
    });

    test('Issue 61: a window both inverted and past reports the order '
        'first', () {
      expect(
        CreditFormValidators.window(
          from: DateTime(2026, 9, 20),
          until: DateTime(2026, 9, 10),
          today: today,
        ),
        'Valid until must not be before from',
      );
    });
  });
}
