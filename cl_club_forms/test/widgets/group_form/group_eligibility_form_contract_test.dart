// GroupEligibilityForm against the list of club_client#61, beside
// group_eligibility_form_test.dart and group_eligibility_reset_test.dart,
// which already cover the seeded band, hasValue and reset(). Every point
// applies. No field of it is required and none has a validator of its own:
// its rules are the two across fields. It draws the section headings
// "Membership" and "Eligibility criteria" and no button at all (its Reset is
// the host card's). The age inputs are the shared age cluster's: only how
// this form uses them is tested here.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_fields.dart'
    show AgeEligibilityFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_validators.dart'
    show AgeEligibilityFormValidators;
import 'package:cl_club_forms/src/widgets/group_form/group_membership_heading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';

typedef _F = GroupFormFields;
typedef _A = AgeEligibilityFormFields;

const _ageRows = ['Years', 'Months', 'Days'];
const List<String> _criteriaRows = [
  AgeEligibilityFields.minAgeTitle,
  ..._ageRows,
  AgeEligibilityFields.maxAgeTitle,
  ..._ageRows,
  'Gender',
];

Map<String, dynamic> _seeded({
  GroupMode mode = GroupMode.semiAuto,
  GroupGender? gender,
  FormAge? minAge,
  FormAge? maxAge,
  bool strictAge = false,
}) => {
  _F.modeId: mode,
  _F.genderId: gender,
  ...AgeEligibilityFormValues.initial(
    minAge: minAge,
    maxAge: maxAge,
    strictAge: strictAge,
  ),
};

Future<GroupEligibilityFormState> _pump(
  WidgetTester tester,
  Map<String, dynamic> initialValues, {
  bool criteriaLocked = false,
  bool enabled = true,
  VoidCallback? onChanged,
}) async {
  final key = GlobalKey<GroupEligibilityFormState>();
  await pumpForm(
    tester,
    GroupEligibilityForm(
      key: key,
      initialValues: initialValues,
      criteriaLocked: criteriaLocked,
      enabled: enabled,
      onChanged: onChanged,
    ),
  );
  return key.currentState!;
}

Future<Map<String, dynamic>?> _validate(
  WidgetTester tester,
  GroupEligibilityFormState state,
) async {
  final values = state.validate();
  await tester.pumpAndSettle();
  return values;
}

void main() {
  group('Issue 61: GroupEligibilityForm fields', () {
    testWidgets('Issue 61: a Manual group shows the mode alone', (
      tester,
    ) async {
      await _pump(tester, _seeded(mode: GroupMode.manual));

      expect(rowLabels(tester), ['Mode']);
      expectLabelsAreRows(tester);
      expect(formOf(tester).fields.keys, [_F.modeId]);
    });

    for (final mode in [GroupMode.semiAuto, GroupMode.auto]) {
      testWidgets('Issue 61: a ${mode.label} group shows the mode, both '
          'ages, the Strict age check and the gender, none required', (
        tester,
      ) async {
        await _pump(tester, _seeded(mode: mode));

        expect(rowLabels(tester), ['Mode', ..._criteriaRows]);
        expectLabelsAreRows(tester);
        expect(formOf(tester).fields.keys, {
          _F.modeId,
          ..._A.minAgeIds,
          ..._A.maxAgeIds,
          _A.strictAgeId,
          _F.genderId,
        });
        expect(find.text(mode.label), findsOneWidget);
      });
    }

    testWidgets('Issue 61: it draws no button, with or without criteria', (
      tester,
    ) async {
      await _pump(
        tester,
        _seeded(gender: GroupGender.male, minAge: const FormAge(years: 5)),
      );

      expect(find.byType(ShadButton), findsNothing);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: unlocked, it explains the modes; locked, it says '
        'why the mode cannot change', (tester) async {
      await _pump(tester, _seeded());
      expect(find.text(GroupMembershipHeading.modeHint), findsOneWidget);
      expect(find.text(GroupMembershipHeading.lockedHint), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester, _seeded(), criteriaLocked: true);
      expect(find.text(GroupMembershipHeading.lockedHint), findsOneWidget);
      expect(find.text(GroupMembershipHeading.modeHint), findsNothing);
    });

    testWidgets('Issue 61: locked criteria are shown as stored, and neither '
        'the mode nor any criterion responds', (tester) async {
      final seeded = _seeded(
        gender: GroupGender.female,
        minAge: const FormAge(years: 5),
        strictAge: true,
      );
      final state = await _pump(tester, seeded, criteriaLocked: true);

      expect(rowLabels(tester), ['Mode', ..._criteriaRows]);
      expect(find.text(GroupGender.female.label), findsOneWidget);
      await expectNoFieldResponds(tester);
      expect(state.isDirty, isFalse);
      expect(await _validate(tester, state), seeded);
    });
  });

  group('Issue 61: GroupEligibilityForm rules across fields', () {
    for (final mode in [GroupMode.semiAuto, GroupMode.auto]) {
      testWidgets('Issue 61: a ${mode.label} group without a criterion is '
          'refused inline, by its mode', (tester) async {
        final state = await _pump(tester, _seeded(mode: mode));

        expect(await _validate(tester, state), isNull);
        expect(
          find.text(
            'Set at least one criterion (age or gender) for an '
            '${mode.label.toLowerCase()} group.',
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('Issue 61: picking a gender satisfies the rule and takes '
        'the message away', (tester) async {
      final state = await _pump(tester, _seeded(mode: GroupMode.auto));
      expect(await _validate(tester, state), isNull);

      await pickOption(tester, from: 'Any gender', to: GroupGender.male.label);

      expect((await _validate(tester, state))![_F.genderId], GroupGender.male);
      expect(find.textContaining('at least one criterion'), findsNothing);
    });

    testWidgets('Issue 61: an age of months alone satisfies the rule', (
      tester,
    ) async {
      final state = await _pump(tester, _seeded(mode: GroupMode.auto));
      await enterField(tester, _A.minAgeMonthsId, '6');

      final values = await _validate(tester, state);
      expect(
        AgeEligibilityFormValues.minAge(values!),
        const FormAge(years: 0, months: 6),
      );
    });

    testWidgets('Issue 61: the Strict age check alone does not', (
      tester,
    ) async {
      final state = await _pump(tester, _seeded(strictAge: true));

      expect(await _validate(tester, state), isNull);
      expect(find.textContaining('at least one criterion'), findsOneWidget);
    });

    testWidgets('Issue 61: days beyond 30 are refused inline with the age '
        'cluster message, and 30 accepted', (tester) async {
      final state = await _pump(tester, _seeded());
      await enterField(tester, _A.maxAgeYearsId, '12');
      await enterField(tester, _A.maxAgeDaysId, '31');

      expect(await _validate(tester, state), isNull);
      expect(
        find.text(AgeEligibilityFormValidators.daysMessage),
        findsOneWidget,
      );

      await enterField(tester, _A.maxAgeDaysId, '30');
      expect(await _validate(tester, state), isNotNull);
      expect(find.text(AgeEligibilityFormValidators.daysMessage), findsNothing);
    });

    testWidgets('Issue 61: a band whose ends are equal passes', (tester) async {
      final state = await _pump(
        tester,
        _seeded(
          minAge: const FormAge(years: 10),
          maxAge: const FormAge(years: 10),
        ),
      );

      expect(await _validate(tester, state), isNotNull);
      expect(find.text(AgeEligibilityFormValidators.bandMessage), findsNothing);
    });

    testWidgets('Issue 61: choosing Manual lifts both rules', (tester) async {
      final state = await _pump(tester, _seeded(mode: GroupMode.auto));
      expect(await _validate(tester, state), isNull);

      await pickOption(
        tester,
        from: GroupMode.auto.label,
        to: GroupMode.manual.label,
      );

      expect((await _validate(tester, state))![_F.modeId], GroupMode.manual);
      expect(find.textContaining('at least one criterion'), findsNothing);
    });
  });

  group('Issue 61: GroupEligibilityForm values', () {
    testWidgets('Issue 61: validate returns exactly the mode, the gender '
        'and the age cluster entries, as the fields hold them', (
      tester,
    ) async {
      final state = await _pump(tester, _seeded());
      await enterField(tester, _A.minAgeYearsId, '5');
      await enterField(tester, _A.maxAgeYearsId, '18');
      await enterField(tester, _A.maxAgeMonthsId, '6');
      await tester.tap(find.byType(ShadCheckbox));
      await pickOption(
        tester,
        from: 'Any gender',
        to: GroupGender.female.label,
      );

      final values = await _validate(tester, state);

      expect(values, {
        _F.modeId: GroupMode.semiAuto,
        _F.genderId: GroupGender.female,
        _A.minAgeYearsId: '5',
        _A.minAgeMonthsId: '',
        _A.minAgeDaysId: '',
        _A.maxAgeYearsId: '18',
        _A.maxAgeMonthsId: '6',
        _A.maxAgeDaysId: '',
        _A.strictAgeId: true,
      });
      expect(values![_F.modeId], isA<GroupMode>());
      expect(values[_F.genderId], isA<GroupGender>());
      expect(values[_A.strictAgeId], isA<bool>());
    });

    testWidgets('Issue 61: seeded values come back unchanged', (tester) async {
      final seeded = _seeded(
        mode: GroupMode.auto,
        gender: GroupGender.other,
        minAge: const FormAge(years: 9, months: 6, days: 15),
        maxAge: const FormAge(years: 12),
        strictAge: true,
      );
      final state = await _pump(tester, seeded);

      expect(state.isDirty, isFalse);
      expect(await _validate(tester, state), seeded);
    });

    testWidgets('Issue 61: a Manual group with no gender returns null for '
        'it', (tester) async {
      final state = await _pump(tester, _seeded(mode: GroupMode.manual));

      final values = (await _validate(tester, state))!;
      expect(values.containsKey(_F.genderId), isTrue);
      expect(values[_F.genderId], isNull);
    });
  });
}
