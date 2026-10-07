import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
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
  group('Issue 61: AgeEligibilityFormValues', () {
    test('Issue 61: initial gives the seven entries, six texts and a bool', () {
      final seeded = AgeEligibilityFormValues.initial(
        minAge: const FormAge(years: 0, months: 6),
        maxAge: const FormAge(years: 18, days: 2),
        strictAge: true,
      );

      expect(seeded, {
        AgeEligibilityFormFields.minAgeYearsId: '0',
        AgeEligibilityFormFields.minAgeMonthsId: '6',
        AgeEligibilityFormFields.minAgeDaysId: '',
        AgeEligibilityFormFields.maxAgeYearsId: '18',
        AgeEligibilityFormFields.maxAgeMonthsId: '',
        AgeEligibilityFormFields.maxAgeDaysId: '2',
        AgeEligibilityFormFields.strictAgeId: true,
      });
    });

    test('Issue 61: an age of zero years is still a set age', () {
      final seeded = AgeEligibilityFormValues.initial(
        minAge: const FormAge(years: 0),
      );

      expect(seeded[AgeEligibilityFormFields.minAgeYearsId], '0');
      expect(AgeEligibilityFormValues.minAge(seeded), const FormAge(years: 0));
      expect(AgeEligibilityFormValues.hasAgeBound(seeded), isTrue);
    });

    test('Issue 61: text trims, and reads null as empty', () {
      expect(AgeEligibilityFormValues.text(' 5 '), '5');
      expect(AgeEligibilityFormValues.text(null), '');
      expect(AgeEligibilityFormValues.text(''), '');
    });

    test('Issue 61: yearsText is empty only for no age; partText also for '
        'zero', () {
      expect(AgeEligibilityFormValues.yearsText(null), '');
      expect(AgeEligibilityFormValues.yearsText(const FormAge(years: 0)), '0');
      expect(AgeEligibilityFormValues.yearsText(const FormAge(years: 7)), '7');
      expect(AgeEligibilityFormValues.partText(null), '');
      expect(AgeEligibilityFormValues.partText(0), '');
      expect(AgeEligibilityFormValues.partText(3), '3');
    });

    test('Issue 61: age reads the three ids it is given', () {
      expect(
        AgeEligibilityFormValues.age(
          const {'y': '3', 'm': ' 4 ', 'd': '5'},
          const ['y', 'm', 'd'],
        ),
        const FormAge(years: 3, months: 4, days: 5),
      );
      expect(
        AgeEligibilityFormValues.age(const {}, const ['y', 'm', 'd']),
        isNull,
      );
    });

    test('Issue 61: hasAgeBound is true with either age', () {
      expect(
        AgeEligibilityFormValues.hasAgeBound(_values(minDays: '1')),
        isTrue,
      );
      expect(
        AgeEligibilityFormValues.hasAgeBound(_values(maxYears: '9')),
        isTrue,
      );
    });

    test('Issue 61: strictAge is false when the entry is missing', () {
      expect(AgeEligibilityFormValues.strictAge(const {}), isFalse);
      expect(
        AgeEligibilityFormValues.strictAge(const {
          AgeEligibilityFormFields.strictAgeId: true,
        }),
        isTrue,
      );
    });

    test('Issue 61: holdsValue is true for an age or a ticked Strict age '
        'check, false for neither', () {
      expect(AgeEligibilityFormValues.holdsValue(_values()), isFalse);
      expect(
        AgeEligibilityFormValues.holdsValue(
          AgeEligibilityFormValues.initial(),
        ),
        isFalse,
      );
      expect(
        AgeEligibilityFormValues.holdsValue(_values(maxMonths: '3')),
        isTrue,
      );
      expect(
        AgeEligibilityFormValues.holdsValue(
          AgeEligibilityFormValues.initial(strictAge: true),
        ),
        isTrue,
      );
    });

    test('Issue 61: the id lists are years, months, days of each side', () {
      expect(AgeEligibilityFormFields.minAgeIds, [
        'minAgeYears',
        'minAgeMonths',
        'minAgeDays',
      ]);
      expect(AgeEligibilityFormFields.maxAgeIds, [
        'maxAgeYears',
        'maxAgeMonths',
        'maxAgeDays',
      ]);
      expect(AgeEligibilityFormFields.strictAgeId, 'strictAge');
    });
  });

  group('Issue 61: FormAge', () {
    test('Issue 61: months and days default to zero', () {
      const age = FormAge(years: 5);
      expect(age.months, 0);
      expect(age.days, 0);
      expect(age.isWholeYears, isTrue);
    });

    test('Issue 61: an age with months or days is not whole years', () {
      expect(const FormAge(years: 5, months: 1).isWholeYears, isFalse);
      expect(const FormAge(years: 5, days: 1).isWholeYears, isFalse);
    });

    test('Issue 61: compareTo orders by years, then months, then days', () {
      const base = FormAge(years: 5, months: 6, days: 7);
      expect(base.compareTo(const FormAge(years: 5, months: 6, days: 7)), 0);
      expect(base.compareTo(const FormAge(years: 6)), isNegative);
      expect(base.compareTo(const FormAge(years: 4, months: 11, days: 30)), 1);
      expect(
        base.compareTo(const FormAge(years: 5, months: 7)),
        isNegative,
      );
      expect(base.compareTo(const FormAge(years: 5, months: 5, days: 30)), 1);
      expect(
        base.compareTo(const FormAge(years: 5, months: 6, days: 8)),
        isNegative,
      );
      expect(base.compareTo(const FormAge(years: 5, months: 6, days: 6)), 1);
    });

    test('Issue 61: equal parts make equal ages with one hash', () {
      // Not const, so the two are distinct objects.
      final a = FormAge(years: int.parse('5'), months: 6, days: 7);
      final b = FormAge(years: int.parse('5'), months: 6, days: 7);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const FormAge(years: 5, months: 6)));
      expect(a, isNot(const FormAge(years: 5, months: 7, days: 7)));
      expect(a, isNot(const FormAge(years: 4, months: 6, days: 7)));
    });

    test('Issue 61: toString names the three parts', () {
      expect(
        const FormAge(years: 5, months: 6, days: 7).toString(),
        'FormAge(years: 5, months: 6, days: 7)',
      );
    });
  });
}
