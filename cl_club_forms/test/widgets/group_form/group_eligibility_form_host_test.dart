// GroupEligibilityForm against the list of club_client#61, continued from
// group_eligibility_form_contract_test.dart: the dirty check, what the
// server refused, enabled false and the phone width.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/eligibility_checks.dart';
import '../../support/form_harness.dart';

typedef _F = GroupFormFields;
typedef _A = AgeEligibilityFormFields;

Map<String, dynamic> _seeded({
  GroupMode mode = GroupMode.semiAuto,
  List<EligibilityGender> genders = const [],
  FormAge? minAge,
  FormAge? maxAge,
  bool strictAge = false,
}) => {
  _F.modeId: mode,
  GenderEligibilityFormFields.gendersId: genders,
  ...AgeEligibilityFormValues.initial(
    minAge: minAge,
    maxAge: maxAge,
    strictAge: strictAge,
  ),
};

Future<GroupEligibilityFormState> _pump(
  WidgetTester tester,
  Map<String, dynamic> initialValues, {
  bool enabled = true,
  VoidCallback? onChanged,
}) async {
  final key = GlobalKey<GroupEligibilityFormState>();
  await pumpForm(
    tester,
    GroupEligibilityForm(
      key: key,
      initialValues: initialValues,
      enabled: enabled,
      onChanged: onChanged,
    ),
  );
  return key.currentState!;
}

void main() {
  group('Issue 61: GroupEligibilityForm dirty check', () {
    testWidgets('Issue 61: choosing another mode dirties it, and choosing '
        'the old one back cleans it', (tester) async {
      final state = await _pump(tester, _seeded());
      expect(state.isDirty, isFalse);

      await pickOption(
        tester,
        from: GroupMode.semiAuto.label,
        to: GroupMode.auto.label,
      );
      expect(state.isDirty, isTrue);

      await pickOption(
        tester,
        from: GroupMode.auto.label,
        to: GroupMode.semiAuto.label,
      );
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: an age typed dirties it, and typing the old one '
        'back cleans it', (tester) async {
      final state = await _pump(
        tester,
        _seeded(minAge: const FormAge(years: 5)),
      );

      await enterField(tester, _A.minAgeYearsId, '6');
      expect(state.isDirty, isTrue);

      await enterField(tester, _A.minAgeYearsId, '5');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the Strict age check dirties it, and unticking '
        'cleans it', (tester) async {
      final state = await _pump(tester, _seeded());

      await tester.tap(strictAgeBox());
      await tester.pumpAndSettle();
      expect(state.isDirty, isTrue);

      await tester.tap(strictAgeBox());
      await tester.pumpAndSettle();
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: another gender dirties it, and the old one back '
        'cleans it', (tester) async {
      final state = await _pump(
        tester,
        _seeded(genders: const [EligibilityGender.boys]),
      );

      await tapGenders(tester, const [
        EligibilityGender.boys,
        EligibilityGender.girls,
      ]);
      expect(state.isDirty, isTrue);

      await tapGenders(tester, const [
        EligibilityGender.girls,
        EligibilityGender.boys,
      ]);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: onChanged tells the host of each edit', (
      tester,
    ) async {
      var changes = 0;
      await _pump(tester, _seeded(), onChanged: () => changes++);
      expect(changes, 0);

      await enterField(tester, _A.minAgeYearsId, '5');
      expect(changes, 1);

      await tester.tap(strictAgeBox());
      await tester.pumpAndSettle();
      expect(changes, 2);
    });
  });

  group('Issue 61: GroupEligibilityForm and its host', () {
    testWidgets('Issue 61: showErrors puts a message on a field and one '
        'inline', (tester) async {
      final state = await _pump(tester, _seeded());

      await expectShowsServerErrors(
        tester,
        state,
        GenderEligibilityFormFields.gendersId,
      );
    });

    testWidgets('Issue 61: after a refused age it validates and returns its '
        'values again', (tester) async {
      final seeded = _seeded(maxAge: const FormAge(years: 12));
      final state = await _pump(tester, seeded);

      expect(
        await expectSavesAfterRefusal(tester, state, _A.maxAgeYearsId),
        seeded,
      );
    });

    testWidgets('Issue 61: with enabled false no field responds', (
      tester,
    ) async {
      await _pump(
        tester,
        _seeded(genders: const [EligibilityGender.boys], strictAge: true),
        enabled: false,
      );

      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone as a Manual group', (tester) async {
      await expectFitsPhone(
        tester,
        GroupEligibilityForm(initialValues: _seeded(mode: GroupMode.manual)),
      );
    });

    testWidgets('Issue 61: it fits a phone with its criteria', (tester) async {
      await expectFitsPhone(
        tester,
        GroupEligibilityForm(
          initialValues: _seeded(
            genders: const [EligibilityGender.girls],
            minAge: const FormAge(years: 100, months: 11, days: 30),
            maxAge: const FormAge(years: 150, months: 11, days: 30),
          ),
        ),
      );
    });
  });
}
