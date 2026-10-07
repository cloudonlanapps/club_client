import 'package:cl_club_forms/cl_club_forms.dart'
    show GroupFormValidators, GroupMode;
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
}
