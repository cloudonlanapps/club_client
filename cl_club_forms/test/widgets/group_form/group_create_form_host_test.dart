// GroupCreateForm against the list of club_client#61, continued from
// group_create_form_contract_test.dart: the dirty check, what the server
// refused, enabled false and the phone width.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/constants/form_strings.dart';
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';

typedef _F = GroupFormFields;
typedef _A = AgeEligibilityFormFields;

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

void main() {
  group('Issue 61: GroupCreateForm dirty check', () {
    Future<GroupCreateFormState> pumpAuto(WidgetTester tester) async {
      final state = await _pump(
        tester,
        initialValues: _initial(name: 'Juniors', mode: GroupMode.auto),
      );
      expect(state.isDirty, isFalse);
      return state;
    }

    testWidgets('Issue 61: typing in the name or the description dirties it, '
        'and typing the old text back cleans it', (tester) async {
      final state = await pumpAuto(tester);

      await enterField(tester, _F.nameId, 'Seniors');
      expect(state.isDirty, isTrue);
      await enterField(tester, _F.nameId, 'Juniors');
      expect(state.isDirty, isFalse);

      await enterField(tester, _F.descriptionId, 'x');
      expect(state.isDirty, isTrue);
      await enterField(tester, _F.descriptionId, '');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the Add me switch dirties it, and switching back '
        'cleans it', (tester) async {
      final state = await pumpAuto(tester);

      await tester.tap(find.byType(ShadSwitch));
      await tester.pumpAndSettle();
      expect(state.isDirty, isTrue);

      await tester.tap(find.byType(ShadSwitch));
      await tester.pumpAndSettle();
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: an age typed dirties it, and emptying it cleans '
        'it', (tester) async {
      final state = await pumpAuto(tester);

      await enterField(tester, _A.minAgeYearsId, '5');
      expect(state.isDirty, isTrue);

      await enterField(tester, _A.minAgeYearsId, '');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the Strict age check dirties it, and unticking '
        'cleans it', (tester) async {
      final state = await pumpAuto(tester);

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();
      expect(state.isDirty, isTrue);

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: a gender picked dirties it, and taking it away '
        'cleans it', (tester) async {
      final state = await pumpAuto(tester);

      await pickOption(tester, from: 'Any gender', to: GroupGender.other.label);
      expect(state.isDirty, isTrue);

      // The select has no "none" option; the host's way back is the form.
      await setField(tester, state, _F.genderId, null);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: Reset on a group that started with criteria '
        'leaves it dirty', (tester) async {
      final state = await _pump(
        tester,
        initialValues: _initial(
          name: 'Juniors',
          mode: GroupMode.auto,
          gender: GroupGender.male,
        ),
      );
      expect(state.isDirty, isFalse);

      await tester.tap(find.text(FormStrings.reset));
      await tester.pumpAndSettle();

      expect(state.isDirty, isTrue);
      expect(formOf(tester).value[_F.modeId], GroupMode.manual);
    });
  });

  group('Issue 61: GroupCreateForm and its host', () {
    testWidgets('Issue 61: showErrors puts a message on a field and one '
        'inline', (tester) async {
      final state = await _pump(tester);

      await expectShowsServerErrors(tester, state, _F.descriptionId);
    });

    testWidgets('Issue 61: after a refused name it validates and returns '
        'its values again', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.nameId, 'Juniors');

      final values = await expectSavesAfterRefusal(tester, state, _F.nameId);
      expect(values[_F.nameId], 'Juniors');
    });

    testWidgets('Issue 61: a refusal about a field that is not on screen '
        'shows inline', (tester) async {
      final state = await _pump(tester);

      state.showErrors(fieldErrors: {_F.genderId: 'Gender refused.'});
      await tester.pumpAndSettle();

      expect(find.text('Gender refused.'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is ShadFormBuilderField),
          matching: find.text('Gender refused.'),
        ),
        findsNothing,
      );
    });

    testWidgets('Issue 61: with enabled false no field of a Manual group '
        'responds', (tester) async {
      await _pump(tester, enabled: false);

      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: with enabled false no field of a criteria group '
        'responds, nor does Reset', (tester) async {
      final initial = _initial(
        name: 'Juniors',
        mode: GroupMode.auto,
        gender: GroupGender.male,
      );
      await _pump(tester, initialValues: initial, enabled: false);

      await expectNoFieldResponds(tester);
      await tester.tap(find.text(FormStrings.reset), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(formOf(tester).value, initial);
    });

    testWidgets('Issue 61: it fits a phone as a Manual group', (tester) async {
      await expectFitsPhone(tester, const GroupCreateForm());
    });

    testWidgets('Issue 61: it fits a phone with its criteria and Reset', (
      tester,
    ) async {
      await expectFitsPhone(
        tester,
        GroupCreateForm(
          initialValues: _initial(
            name: 'Juniors',
            mode: GroupMode.semiAuto,
            gender: GroupGender.preferNotToSay,
          ),
        ),
      );
      expect(find.text(FormStrings.reset), findsOneWidget);
    });
  });
}
