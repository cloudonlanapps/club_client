import 'package:cl_club_forms/cl_club_forms.dart'
    show
        GroupCreateForm,
        GroupFormFields,
        GroupFormValidators,
        GroupGender,
        GroupMode;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_validators.dart'
    show AgeEligibilityFormValidators;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupFormValidators.name', () {
    test('rejects empty / whitespace', () {
      expect(GroupFormValidators.name(''), isNotNull);
      expect(GroupFormValidators.name('  '), isNotNull);
    });

    test('accepts non-empty', () {
      expect(GroupFormValidators.name('U12 Boys'), isNull);
    });

    test('Issue 676: requires at least 2 characters (shared name rule)', () {
      expect(GroupFormValidators.name('A'), isNotNull);
      expect(GroupFormValidators.name('U8'), isNull);
    });
  });

  // The band's ordering rule moved with the age inputs to the shared
  // AgeEligibilityFormValidators (club_client#33).
  group('AgeEligibilityFormValidators.band', () {
    Map<String, dynamic> band({String min = '', String max = ''}) => {
      AgeEligibilityFormFields.minAgeYearsId: min,
      AgeEligibilityFormFields.maxAgeYearsId: max,
    };

    test('null when either bound is null', () {
      expect(AgeEligibilityFormValidators.band(band(max: '16')), isNull);
      expect(AgeEligibilityFormValidators.band(band(min: '10')), isNull);
    });

    test('rejects a minimum above the maximum', () {
      expect(
        AgeEligibilityFormValidators.band(band(min: '16', max: '10')),
        isNotNull,
      );
    });

    test('accepts minimum <= maximum', () {
      expect(
        AgeEligibilityFormValidators.band(band(min: '10', max: '16')),
        isNull,
      );
      expect(
        AgeEligibilityFormValidators.band(band(min: '10', max: '10')),
        isNull,
      );
    });
  });

  group('GroupFormValidators.criteriaForMode', () {
    test('manual mode never requires criteria', () {
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.manual,
          hasAnyCriterion: false,
        ),
        isNull,
      );
    });

    test('auto / semi-auto require at least one criterion', () {
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.auto,
          hasAnyCriterion: false,
        ),
        isNotNull,
      );
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.semiAuto,
          hasAnyCriterion: false,
        ),
        isNotNull,
      );
    });

    test('auto / semi-auto pass when a criterion is set', () {
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.auto,
          hasAnyCriterion: true,
        ),
        isNull,
      );
    });
  });

  group('Issue 55: GroupFormValidators.eligibility', () {
    Map<String, dynamic> values({
      required GroupMode mode,
      String minYears = '',
      String maxYears = '',
      GroupGender? gender,
    }) => {
      ...GroupCreateForm.emptyValues,
      GroupFormFields.modeId: mode,
      GroupFormFields.genderId: gender,
      AgeEligibilityFormFields.minAgeYearsId: minYears,
      AgeEligibilityFormFields.maxAgeYearsId: maxYears,
    };

    test('Issue 55: a manual group is valid whatever its hidden ages hold', () {
      expect(
        GroupFormValidators.eligibility(
          values(mode: GroupMode.manual, minYears: '18', maxYears: '5'),
        ),
        isNull,
      );
    });

    test('Issue 55: a criteria mode with no criterion is refused', () {
      expect(
        GroupFormValidators.eligibility(values(mode: GroupMode.semiAuto)),
        contains('at least one criterion'),
      );
    });

    test('Issue 55: a minimum above the maximum is refused with the band '
        'message', () {
      expect(
        GroupFormValidators.eligibility(
          values(mode: GroupMode.auto, minYears: '18', maxYears: '5'),
        ),
        AgeEligibilityFormValidators.bandMessage,
      );
    });

    test('Issue 55: a gender or an age alone is enough', () {
      expect(
        GroupFormValidators.eligibility(
          values(mode: GroupMode.auto, gender: GroupGender.male),
        ),
        isNull,
      );
      expect(
        GroupFormValidators.eligibility(
          values(mode: GroupMode.auto, maxYears: '12'),
        ),
        isNull,
      );
    });
  });

  group('Issue 61: GroupFormValidators.name', () {
    test('Issue 61: an empty name is refused by the name of a group', () {
      expect(GroupFormValidators.name(''), 'Group name is required');
      expect(GroupFormValidators.name(' \t '), 'Group name is required');
    });

    test('Issue 61: the length is counted after trimming', () {
      expect(GroupFormValidators.name('  A  '), 'At least 2 characters');
      expect(GroupFormValidators.name(' U8 '), isNull);
    });
  });

  group('Issue 61: GroupFormValidators.criteriaForMode', () {
    test('Issue 61: the message names the mode', () {
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.auto,
          hasAnyCriterion: false,
        ),
        'Set at least one criterion (age or gender) for an auto group.',
      );
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.semiAuto,
          hasAnyCriterion: false,
        ),
        'Set at least one criterion (age or gender) for an semi-auto group.',
      );
    });

    test('Issue 61: a Manual group passes with criteria too', () {
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.manual,
          hasAnyCriterion: true,
        ),
        isNull,
      );
    });

    test('Issue 61: a semi-auto group passes once a criterion is set', () {
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.semiAuto,
          hasAnyCriterion: true,
        ),
        isNull,
      );
    });
  });

  group('Issue 61: GroupFormValidators.eligibility', () {
    Map<String, dynamic> values(
      GroupMode? mode, [
      Map<String, dynamic> more = const {},
    ]) => {
      ...GroupCreateForm.emptyValues,
      GroupFormFields.modeId: mode,
      ...more,
    };

    test('Issue 61: values without a mode are those of a Manual group', () {
      expect(
        GroupFormValidators.eligibility(
          values(null, const {AgeEligibilityFormFields.minAgeMonthsId: '99'}),
        ),
        isNull,
      );
    });

    test('Issue 61: a part of an age beyond its limit is refused with its '
        'own message, before the criterion rule', () {
      expect(
        GroupFormValidators.eligibility(
          values(GroupMode.auto, const {
            AgeEligibilityFormFields.maxAgeYearsId: '151',
          }),
        ),
        AgeEligibilityFormValidators.yearsMessage,
      );
      expect(
        GroupFormValidators.eligibility(
          values(GroupMode.semiAuto, const {
            AgeEligibilityFormFields.minAgeMonthsId: '12',
          }),
        ),
        AgeEligibilityFormValidators.monthsMessage,
      );
      expect(
        GroupFormValidators.eligibility(
          values(GroupMode.auto, const {
            AgeEligibilityFormFields.minAgeDaysId: '31',
          }),
        ),
        AgeEligibilityFormValidators.daysMessage,
      );
    });

    test('Issue 61: the limits themselves pass', () {
      expect(
        GroupFormValidators.eligibility(
          values(GroupMode.auto, const {
            AgeEligibilityFormFields.maxAgeYearsId: '150',
            AgeEligibilityFormFields.maxAgeMonthsId: '11',
            AgeEligibilityFormFields.maxAgeDaysId: '30',
          }),
        ),
        isNull,
      );
    });

    test('Issue 61: months or days alone are an age, and so a criterion', () {
      for (final id in [
        AgeEligibilityFormFields.minAgeMonthsId,
        AgeEligibilityFormFields.maxAgeDaysId,
      ]) {
        expect(
          GroupFormValidators.eligibility(values(GroupMode.auto, {id: '3'})),
          isNull,
          reason: id,
        );
      }
    });

    test('Issue 61: the Strict age check alone is not a criterion', () {
      expect(
        GroupFormValidators.eligibility(
          values(GroupMode.semiAuto, const {
            AgeEligibilityFormFields.strictAgeId: true,
          }),
        ),
        contains('at least one criterion'),
      );
    });

    test('Issue 61: an inverted band is refused even with a gender set', () {
      expect(
        GroupFormValidators.eligibility(
          values(GroupMode.auto, const {
            GroupFormFields.genderId: GroupGender.female,
            AgeEligibilityFormFields.minAgeYearsId: '12',
            AgeEligibilityFormFields.maxAgeYearsId: '11',
            AgeEligibilityFormFields.maxAgeMonthsId: '11',
          }),
        ),
        AgeEligibilityFormValidators.bandMessage,
      );
    });
  });
}
