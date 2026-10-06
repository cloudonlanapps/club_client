import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

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
}
