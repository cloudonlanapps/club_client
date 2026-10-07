// GroupCreateForm against the list of club_client#61, beside
// group_create_form_test.dart and group_eligibility_reset_test.dart, which
// already cover the defaults, the seeded band and the Reset action. Every
// point applies. The form draws the section headings "Membership" and
// "Eligibility criteria" of its eligibility block, and one in-form action,
// Reset; it has no title and no button that submits. The age inputs are the
// shared age cluster's: only how this form uses them is tested here.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/constants/form_strings.dart';
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_fields.dart'
    show AgeEligibilityFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_validators.dart'
    show AgeEligibilityFormValidators;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';

typedef _F = GroupFormFields;
typedef _A = AgeEligibilityFormFields;

const _addMeLabel = 'Add me into the group';
const _ageRows = ['Years', 'Months', 'Days'];

Map<String, dynamic> _initial({
  String name = '',
  GroupMode mode = GroupMode.manual,
  GroupGender? gender,
}) => {
  ...GroupCreateForm.emptyValues,
  _F.nameId: name,
  _F.modeId: mode,
  _F.genderId: gender,
};

Future<GroupCreateFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
  bool enabled = true,
}) async {
  final key = GlobalKey<GroupCreateFormState>();
  await pumpForm(
    tester,
    GroupCreateForm(key: key, initialValues: initialValues, enabled: enabled),
  );
  return key.currentState!;
}

Future<Map<String, dynamic>?> _validate(
  WidgetTester tester,
  GroupCreateFormState state,
) async {
  final values = state.validate();
  await tester.pumpAndSettle();
  return values;
}

void main() {
  group('Issue 61: GroupCreateForm fields', () {
    testWidgets('Issue 61: a Manual group shows the name (required), the '
        'description, the mode and the Add me switch', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), ['Group Name *', 'Description', 'Mode']);
      expectLabelsAreRows(tester);
      expect(formOf(tester).fields.keys, {
        _F.nameId,
        _F.descriptionId,
        _F.modeId,
        _F.addMeId,
      });
      expect(
        find.descendant(
          of: fieldWithId(_F.addMeId),
          matching: find.text(_addMeLabel),
        ),
        findsOneWidget,
      );
      expect(find.text('e.g., U12 Boys'), findsOneWidget);
      expect(find.text('Optional description'), findsOneWidget);
    });

    for (final mode in [GroupMode.semiAuto, GroupMode.auto]) {
      testWidgets('Issue 61: a ${mode.label} group adds the ages, the Strict '
          'age check and the gender, none of them required', (tester) async {
        await _pump(tester, initialValues: _initial(mode: mode));

        expect(rowLabels(tester), [
          'Group Name *',
          'Description',
          'Mode',
          AgeEligibilityFields.minAgeTitle,
          ..._ageRows,
          AgeEligibilityFields.maxAgeTitle,
          ..._ageRows,
          'Gender',
        ]);
        expectLabelsAreRows(tester);
        expect(
          formOf(tester).fields.keys,
          containsAll([
            ..._A.minAgeIds,
            ..._A.maxAgeIds,
            _A.strictAgeId,
            _F.genderId,
          ]),
        );
      });
    }

    testWidgets('Issue 61: it has no button that submits; Reset is its only '
        'action, and only once a criterion is set', (tester) async {
      await _pump(tester, initialValues: _initial(mode: GroupMode.auto));
      expectNoHostChrome(tester);

      await pickOption(tester, from: 'Any gender', to: GroupGender.male.label);
      expect(find.byType(ShadButton), findsOneWidget);
      expectNoHostChrome(tester, allowedButtonTexts: {FormStrings.reset});
    });
  });

  group('Issue 61: GroupCreateForm field validation', () {
    testWidgets('Issue 61: an empty or blank name is refused on the field', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _F.nameId, '   ');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.nameId, 'Group name is required');
    });

    testWidgets('Issue 61: a name of one character is refused on the field, '
        'one of two accepted', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.nameId, 'A');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.nameId, 'At least 2 characters');

      await enterField(tester, _F.nameId, 'U8');
      expect(await _validate(tester, state), isNotNull);
      expect(find.text('At least 2 characters'), findsNothing);
    });

    testWidgets('Issue 61: the description is optional', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.nameId, 'Juniors');

      expect((await _validate(tester, state))![_F.descriptionId], '');
    });
  });

  group('Issue 61: GroupCreateForm rules across fields', () {
    for (final mode in [GroupMode.semiAuto, GroupMode.auto]) {
      testWidgets('Issue 61: a ${mode.label} group without a criterion is '
          'refused inline, by its mode', (tester) async {
        final state = await _pump(
          tester,
          initialValues: _initial(name: 'Juniors', mode: mode),
        );

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

    testWidgets('Issue 61: a gender picked alone satisfies a criteria mode', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        initialValues: _initial(name: 'Juniors', mode: GroupMode.auto),
      );
      expect(await _validate(tester, state), isNull);

      await pickOption(
        tester,
        from: 'Any gender',
        to: GroupGender.female.label,
      );

      final values = await _validate(tester, state);
      expect(values![_F.genderId], GroupGender.female);
      expect(find.textContaining('at least one criterion'), findsNothing);
    });

    testWidgets('Issue 61: the Strict age check alone is not a criterion', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        initialValues: _initial(name: 'Juniors', mode: GroupMode.auto),
      );
      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();

      expect(await _validate(tester, state), isNull);
      expect(find.textContaining('at least one criterion'), findsOneWidget);
    });

    testWidgets('Issue 61: a part of an age beyond its limit is refused '
        'inline with the message of the age cluster', (tester) async {
      final state = await _pump(
        tester,
        initialValues: _initial(name: 'Juniors', mode: GroupMode.semiAuto),
      );
      await enterField(tester, _A.minAgeYearsId, '5');
      await enterField(tester, _A.minAgeMonthsId, '12');

      expect(await _validate(tester, state), isNull);
      expect(
        find.text(AgeEligibilityFormValidators.monthsMessage),
        findsOneWidget,
      );

      await enterField(tester, _A.minAgeMonthsId, '11');
      expect(await _validate(tester, state), isNotNull);
      expect(
        find.text(AgeEligibilityFormValidators.monthsMessage),
        findsNothing,
      );
    });

    testWidgets('Issue 61: an inverted band is not checked once the group '
        'is Manual again', (tester) async {
      final state = await _pump(
        tester,
        initialValues: _initial(name: 'Juniors', mode: GroupMode.auto),
      );
      await enterField(tester, _A.minAgeYearsId, '18');
      await enterField(tester, _A.maxAgeYearsId, '5');
      expect(await _validate(tester, state), isNull);
      expect(
        find.text(AgeEligibilityFormValidators.bandMessage),
        findsOneWidget,
      );

      await pickOption(
        tester,
        from: GroupMode.auto.label,
        to: GroupMode.manual.label,
      );

      final values = await _validate(tester, state);
      expect(values![_F.modeId], GroupMode.manual);
      expect(find.text(AgeEligibilityFormValidators.bandMessage), findsNothing);
    });

    testWidgets('Issue 61: a broken name is reported before the criteria '
        'rule', (tester) async {
      final state = await _pump(
        tester,
        initialValues: _initial(mode: GroupMode.auto),
      );

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.nameId, 'Group name is required');
      expect(find.textContaining('at least one criterion'), findsNothing);
    });
  });

  group('Issue 61: GroupCreateForm values', () {
    testWidgets('Issue 61: a fresh Manual group returns exactly the group '
        'entries and those of the age cluster, as the fields hold them', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _F.nameId, ' U12 Boys ');
      await enterField(tester, _F.descriptionId, 'Tuesday ice');

      final values = await _validate(tester, state);

      // Not trimmed here: the host's adapter trims the name.
      expect(values, {
        _F.nameId: ' U12 Boys ',
        _F.descriptionId: 'Tuesday ice',
        _F.modeId: GroupMode.manual,
        _F.genderId: null,
        _F.addMeId: false,
        ...AgeEligibilityFormValues.initial(),
      });
    });

    testWidgets('Issue 61: emptyValues is what a form without initial '
        'values starts with', (tester) async {
      final state = await _pump(tester);

      expect(state.initialValues, GroupCreateForm.emptyValues);
      expect(formOf(tester).value, GroupCreateForm.emptyValues);
      expect(GroupCreateForm.emptyValues[_F.modeId], GroupMode.manual);
      expect(GroupCreateForm.emptyValues[_F.addMeId], isFalse);
    });

    testWidgets('Issue 61: a seeded criteria group comes back unchanged', (
      tester,
    ) async {
      final seeded = {
        _F.nameId: 'U12 Girls',
        _F.descriptionId: 'Tuesday ice',
        _F.modeId: GroupMode.semiAuto,
        _F.genderId: GroupGender.female,
        _F.addMeId: true,
        ...AgeEligibilityFormValues.initial(
          minAge: const FormAge(years: 9, months: 6),
          maxAge: const FormAge(years: 12),
          strictAge: true,
        ),
      };
      final state = await _pump(tester, initialValues: seeded);

      expect(state.isDirty, isFalse);
      expect(await _validate(tester, state), seeded);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the Add me switch, the mode and typed ages come '
        'back as set', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.nameId, 'Juniors');
      await tester.tap(find.byType(ShadSwitch));
      await pickOption(
        tester,
        from: GroupMode.manual.label,
        to: GroupMode.semiAuto.label,
      );
      await enterField(tester, _A.maxAgeYearsId, '12');
      await enterField(tester, _A.maxAgeDaysId, '30');

      final values = (await _validate(tester, state))!;

      expect(values[_F.addMeId], isTrue);
      expect(values[_F.modeId], GroupMode.semiAuto);
      expect(
        AgeEligibilityFormValues.maxAge(values),
        const FormAge(years: 12, days: 30),
      );
      expect(AgeEligibilityFormValues.minAge(values), isNull);
    });
  });
}
