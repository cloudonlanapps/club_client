import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_validators.dart'
    show AgeEligibilityFormValidators;
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _values({
  String minYears = '',
  String minMonths = '',
  String minDays = '',
  String maxYears = '',
  String maxMonths = '',
  String maxDays = '',
}) => {
  AgeEligibilityFormFields.minAgeYearsId: minYears,
  AgeEligibilityFormFields.minAgeMonthsId: minMonths,
  AgeEligibilityFormFields.minAgeDaysId: minDays,
  AgeEligibilityFormFields.maxAgeYearsId: maxYears,
  AgeEligibilityFormFields.maxAgeMonthsId: maxMonths,
  AgeEligibilityFormFields.maxAgeDaysId: maxDays,
};

void main() {
  group('Issue 33: AgeEligibilityFormValidators.band', () {
    test('Issue 33: an empty band is valid', () {
      expect(AgeEligibilityFormValidators.band(_values()), isNull);
      expect(AgeEligibilityFormValidators.band(const {}), isNull);
    });

    test('Issue 33: one bound alone is valid', () {
      expect(
        AgeEligibilityFormValidators.band(_values(minYears: '5')),
        isNull,
      );
      expect(
        AgeEligibilityFormValidators.band(_values(maxYears: '18')),
        isNull,
      );
    });

    test('Issue 33: a minimum equal to the maximum is valid', () {
      expect(
        AgeEligibilityFormValidators.band(
          _values(minYears: '10', maxYears: '10'),
        ),
        isNull,
      );
    });

    test('Issue 33: a minimum above the maximum is refused', () {
      expect(
        AgeEligibilityFormValidators.band(
          _values(minYears: '18', maxYears: '5'),
        ),
        AgeEligibilityFormValidators.bandMessage,
      );
    });

    test('Issue 33: months and days decide between equal years', () {
      expect(
        AgeEligibilityFormValidators.band(
          _values(minYears: '5', minMonths: '6', maxYears: '5'),
        ),
        AgeEligibilityFormValidators.bandMessage,
      );
      expect(
        AgeEligibilityFormValidators.band(
          _values(
            minYears: '5',
            minMonths: '6',
            maxYears: '5',
            maxMonths: '6',
            maxDays: '1',
          ),
        ),
        isNull,
      );
    });

    test('Issue 33: months are 0 to 11', () {
      expect(
        AgeEligibilityFormValidators.band(
          _values(minYears: '1', minMonths: '12'),
        ),
        AgeEligibilityFormValidators.monthsMessage,
      );
      expect(
        AgeEligibilityFormValidators.band(
          _values(maxYears: '1', maxMonths: '11'),
        ),
        isNull,
      );
    });

    test('Issue 33: days are 0 to 30', () {
      expect(
        AgeEligibilityFormValidators.band(
          _values(maxYears: '1', maxDays: '31'),
        ),
        AgeEligibilityFormValidators.daysMessage,
      );
      expect(
        AgeEligibilityFormValidators.band(
          _values(minYears: '1', minDays: '30'),
        ),
        isNull,
      );
    });

    test('Issue 33: years are 0 to 150 and whole numbers', () {
      expect(
        AgeEligibilityFormValidators.band(_values(maxYears: '151')),
        AgeEligibilityFormValidators.yearsMessage,
      );
      expect(
        AgeEligibilityFormValidators.band(_values(minYears: '5.5')),
        AgeEligibilityFormValidators.yearsMessage,
      );
    });
  });

  group('Issue 33: AgeEligibilityFormValues', () {
    test('Issue 33: three empty inputs are no bound', () {
      expect(AgeEligibilityFormValues.minAge(_values()), isNull);
      expect(AgeEligibilityFormValues.maxAge(_values()), isNull);
      expect(AgeEligibilityFormValues.hasAgeBound(_values()), isFalse);
    });

    test('Issue 33: empty months and days of a set age count as zero', () {
      expect(
        AgeEligibilityFormValues.minAge(_values(minYears: '5')),
        const FormAge(years: 5),
      );
      expect(
        AgeEligibilityFormValues.maxAge(_values(maxMonths: '6')),
        const FormAge(years: 0, months: 6),
      );
    });

    test('Issue 33: initial seeds text the inputs read back', () {
      final seeded = AgeEligibilityFormValues.initial(
        minAge: const FormAge(years: 5),
        maxAge: const FormAge(years: 18, months: 6, days: 2),
        strictAge: true,
      );
      expect(seeded[AgeEligibilityFormFields.minAgeYearsId], '5');
      expect(seeded[AgeEligibilityFormFields.minAgeMonthsId], '');
      expect(seeded[AgeEligibilityFormFields.maxAgeMonthsId], '6');
      expect(AgeEligibilityFormValues.minAge(seeded), const FormAge(years: 5));
      expect(
        AgeEligibilityFormValues.maxAge(seeded),
        const FormAge(years: 18, months: 6, days: 2),
      );
      expect(AgeEligibilityFormValues.strictAge(seeded), isTrue);
    });

    test('Issue 33: an unset band seeds empty text and strict off', () {
      final seeded = AgeEligibilityFormValues.initial();
      expect(seeded[AgeEligibilityFormFields.minAgeYearsId], '');
      expect(seeded[AgeEligibilityFormFields.maxAgeYearsId], '');
      expect(AgeEligibilityFormValues.strictAge(seeded), isFalse);
    });
  });

  group('Issue 61: AgeEligibilityFormValidators.part', () {
    const message = 'Out of range.';
    String? part(Object? raw) =>
        AgeEligibilityFormValidators.part(raw, max: 11, message: message);

    test('Issue 61: an empty, blank or missing input is accepted', () {
      expect(part(''), isNull);
      expect(part('   '), isNull);
      expect(part(null), isNull);
    });

    test('Issue 61: zero and the maximum are accepted', () {
      expect(part('0'), isNull);
      expect(part('11'), isNull);
    });

    test('Issue 61: one above the maximum is refused', () {
      expect(part('12'), message);
    });

    test('Issue 61: a negative number is refused', () {
      expect(part('-1'), message);
    });

    test('Issue 61: text that is not a whole number is refused', () {
      expect(part('abc'), message);
      expect(part('1.5'), message);
      expect(part('1 1'), message);
    });

    test('Issue 61: blanks around a number are ignored', () {
      expect(part(' 7 '), isNull);
      expect(part(' 12 '), message);
    });
  });

  group('Issue 61: AgeEligibilityFormValidators.band', () {
    test("Issue 61: the limits are the server's and the messages name "
        'them', () {
      expect(AgeEligibilityFormValidators.maxYears, 150);
      expect(AgeEligibilityFormValidators.maxMonths, 11);
      expect(AgeEligibilityFormValidators.maxDays, 30);
      expect(
        AgeEligibilityFormValidators.yearsMessage,
        'Years must be between 0 and 150.',
      );
      expect(
        AgeEligibilityFormValidators.monthsMessage,
        'Months must be between 0 and 11.',
      );
      expect(
        AgeEligibilityFormValidators.daysMessage,
        'Days must be between 0 and 30.',
      );
    });

    test('Issue 61: every part at its limit, on both sides, is valid', () {
      expect(
        AgeEligibilityFormValidators.band(
          _values(
            minYears: '0',
            minMonths: '0',
            minDays: '0',
            maxYears: '150',
            maxMonths: '11',
            maxDays: '30',
          ),
        ),
        isNull,
      );
    });

    test('Issue 61: each part is checked on each side', () {
      expect(
        AgeEligibilityFormValidators.band(_values(minYears: '151')),
        AgeEligibilityFormValidators.yearsMessage,
      );
      expect(
        AgeEligibilityFormValidators.band(_values(maxMonths: '12')),
        AgeEligibilityFormValidators.monthsMessage,
      );
      expect(
        AgeEligibilityFormValidators.band(_values(minDays: '31')),
        AgeEligibilityFormValidators.daysMessage,
      );
    });

    test('Issue 61: a part out of range is reported before an inverted '
        'band', () {
      expect(
        AgeEligibilityFormValidators.band(
          _values(minYears: '18', maxYears: '5', maxMonths: '12'),
        ),
        AgeEligibilityFormValidators.monthsMessage,
      );
    });

    test('Issue 61: the minimum is reported before the maximum, years '
        'before months before days', () {
      expect(
        AgeEligibilityFormValidators.band(
          _values(minDays: '31', maxYears: '151'),
        ),
        AgeEligibilityFormValidators.daysMessage,
      );
      expect(
        AgeEligibilityFormValidators.band(
          _values(minYears: '151', minMonths: '12', minDays: '31'),
        ),
        AgeEligibilityFormValidators.yearsMessage,
      );
      expect(
        AgeEligibilityFormValidators.band(
          _values(minMonths: '12', minDays: '31'),
        ),
        AgeEligibilityFormValidators.monthsMessage,
      );
    });

    test('Issue 61: a single day decides the band', () {
      expect(
        AgeEligibilityFormValidators.band(
          _values(minYears: '5', minDays: '1', maxYears: '5'),
        ),
        AgeEligibilityFormValidators.bandMessage,
      );
      expect(
        AgeEligibilityFormValidators.band(
          _values(minYears: '5', maxYears: '5', maxDays: '1'),
        ),
        isNull,
      );
    });

    test('Issue 61: a minimum of months alone is compared as zero years', () {
      expect(
        AgeEligibilityFormValidators.band(
          _values(minMonths: '6', maxYears: '0', maxMonths: '5'),
        ),
        AgeEligibilityFormValidators.bandMessage,
      );
    });

    test('Issue 61: blanks around the numbers are ignored', () {
      expect(
        AgeEligibilityFormValidators.band(
          _values(minYears: ' 5 ', maxYears: ' 18 '),
        ),
        isNull,
      );
      expect(
        AgeEligibilityFormValidators.band(
          _values(minYears: ' 18 ', maxYears: ' 5 '),
        ),
        AgeEligibilityFormValidators.bandMessage,
      );
    });
  });
}
