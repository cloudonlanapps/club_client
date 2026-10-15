// GroupEligibilityFields, the cluster GroupCreateForm and
// GroupEligibilityForm share, mounted alone under a bare ShadForm. It has no
// validator and no rule of its own (the forms apply
// GroupFormValidators.eligibility) and returns no values itself. Its in-form
// action is Clear. The age inputs inside it are the shared age cluster's,
// tested in test/widgets/age_eligibility/.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/constants/form_strings.dart';
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_fields.dart'
    show AgeEligibilityFields;
import 'package:cl_club_forms/src/widgets/group_form/group_eligibility_fields.dart';
import 'package:cl_club_forms/src/widgets/group_form/group_membership_heading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/eligibility_checks.dart';
import '../../support/form_harness.dart';

typedef _A = AgeEligibilityFormFields;

const _ageRows = ['Years', 'Months', 'Days'];
const List<String> _criteriaRows = [
  AgeEligibilityFields.minAgeTitle,
  ..._ageRows,
  AgeEligibilityFields.maxAgeTitle,
  ..._ageRows,
  'Gender',
];

Map<String, dynamic> _values({
  GroupMode mode = GroupMode.manual,
  List<EligibilityGender> genders = const [],
  FormAge? minAge,
  FormAge? maxAge,
  bool strictAge = false,
}) => {
  GroupFormFields.modeId: mode,
  GenderEligibilityFormFields.gendersId: genders,
  ...AgeEligibilityFormValues.initial(
    minAge: minAge,
    maxAge: maxAge,
    strictAge: strictAge,
  ),
};

Widget _cluster(
  GlobalKey<ShadFormState> key,
  Map<String, dynamic> values, {
  bool showClear = false,
  bool enabled = true,
}) => ClusterHost(
  formKey: key,
  initialValue: values,
  builder: (_) => GroupEligibilityFields(
    initialMode: values[GroupFormFields.modeId] as GroupMode,
    showClear: showClear,
    enabled: enabled,
  ),
);

Future<ShadFormState> _pump(
  WidgetTester tester,
  Map<String, dynamic> values, {
  bool showClear = false,
  bool enabled = true,
}) async {
  final key = GlobalKey<ShadFormState>();
  await pumpForm(
    tester,
    _cluster(
      key,
      values,
      showClear: showClear,
      enabled: enabled,
    ),
  );
  return key.currentState!;
}

void main() {
  group('Issue 61: GroupEligibilityFields fields', () {
    testWidgets('Issue 61: a Manual group shows the mode alone, under the '
        'Membership heading and its hint', (tester) async {
      final form = await _pump(tester, _values());

      expect(rowLabels(tester), ['Mode']);
      expectLabelsAreRows(tester);
      expect(form.fields.keys, [GroupFormFields.modeId]);
      expect(find.text(GroupMembershipHeading.title), findsOneWidget);
      expect(find.text(GroupMembershipHeading.modeHint), findsOneWidget);
      expect(find.text(GroupEligibilityFields.criteriaTitle), findsNothing);
    });

    for (final mode in [GroupMode.semiAuto, GroupMode.auto]) {
      testWidgets('Issue 61: a ${mode.label} group adds the criteria: both '
          'ages, the Strict age check and the gender, none required', (
        tester,
      ) async {
        final form = await _pump(tester, _values(mode: mode));

        expect(rowLabels(tester), ['Mode', ..._criteriaRows]);
        expect(find.text(GroupEligibilityFields.criteriaTitle), findsOneWidget);
        expect(find.text(AgeEligibilityFields.strictLabel), findsOneWidget);
        expect(form.fields.keys, {
          GroupFormFields.modeId,
          ..._A.minAgeIds,
          ..._A.maxAgeIds,
          _A.strictAgeId,
          GenderEligibilityFormFields.gendersId,
        });
      });
    }

    testWidgets('Issue 61: the mode select offers the three modes, and the '
        'criteria follow the one chosen', (tester) async {
      final form = await _pump(tester, _values());

      await tester.tap(find.text(GroupMode.manual.label));
      await tester.pumpAndSettle();
      for (final mode in [GroupMode.semiAuto, GroupMode.auto]) {
        expect(find.text(mode.label), findsOneWidget);
      }
      await tester.tap(find.text(GroupMode.semiAuto.label));
      await tester.pumpAndSettle();
      expect(form.value[GroupFormFields.modeId], GroupMode.semiAuto);
      expect(find.text(GroupEligibilityFields.criteriaTitle), findsOneWidget);

      await pickOption(
        tester,
        from: GroupMode.semiAuto.label,
        to: GroupMode.auto.label,
      );
      expect(form.value[GroupFormFields.modeId], GroupMode.auto);
      expect(find.text(GroupEligibilityFields.criteriaTitle), findsOneWidget);

      await pickOption(
        tester,
        from: GroupMode.auto.label,
        to: GroupMode.manual.label,
      );
      expect(form.value[GroupFormFields.modeId], GroupMode.manual);
      expect(find.text(GroupEligibilityFields.criteriaTitle), findsNothing);
      expect(rowLabels(tester), ['Mode']);
    });

    testWidgets('Issue 80: the gender row starts with no box ticked, offers '
        'the four genders and holds those ticked', (tester) async {
      final form = await _pump(tester, _values(mode: GroupMode.auto));

      expect(
        GenderEligibilityFormValues.genders(form.value),
        isEmpty,
      );
      for (final gender in EligibilityGender.values) {
        expect(genderBox(gender), findsOneWidget, reason: gender.label);
      }
      expect(find.text(GenderEligibilityField.noneTickedHint), findsOneWidget);
      expect(find.text('Any'), findsNothing);

      await tapGenders(tester, const [
        EligibilityGender.preferNotToSay,
        EligibilityGender.girls,
      ]);

      expect(GenderEligibilityFormValues.genders(form.value), const [
        EligibilityGender.girls,
        EligibilityGender.preferNotToSay,
      ]);
      expect(find.text(GenderEligibilityField.noneTickedHint), findsNothing);
    });

    testWidgets('Issue 80: each box ticked then unticked leaves the group '
        'with no gender criterion', (tester) async {
      for (final gender in EligibilityGender.values) {
        final form = await _pump(tester, _values(mode: GroupMode.semiAuto));

        await tapGenders(tester, [gender]);
        expect(GenderEligibilityFormValues.genders(form.value), [gender]);
        expect(GroupEligibilityFields.holdsValue(form.value), isTrue);

        await tapGenders(tester, [gender]);
        expect(GenderEligibilityFormValues.genders(form.value), isEmpty);
        expect(GroupEligibilityFields.holdsValue(form.value), isFalse);

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('Issue 80: ticked genders survive a visit to Manual and '
        'back, which takes the boxes down and puts them back', (tester) async {
      final form = await _pump(tester, _values(mode: GroupMode.auto));
      await tapGenders(tester, const [
        EligibilityGender.boys,
        EligibilityGender.other,
      ]);

      await pickOption(
        tester,
        from: GroupMode.auto.label,
        to: GroupMode.manual.label,
      );
      expect(genderBox(EligibilityGender.boys), findsNothing);
      await pickOption(
        tester,
        from: GroupMode.manual.label,
        to: GroupMode.auto.label,
      );

      expect(tickedGenders(tester), const [
        EligibilityGender.boys,
        EligibilityGender.other,
      ]);
      expect(GenderEligibilityFormValues.genders(form.value), const [
        EligibilityGender.boys,
        EligibilityGender.other,
      ]);
    });

    testWidgets('Issue 61: a seeded gender shows ticked', (tester) async {
      await _pump(
        tester,
        _values(mode: GroupMode.auto, genders: const [EligibilityGender.girls]),
      );

      expect(tickedGenders(tester), const [EligibilityGender.girls]);
    });
  });

  group('Issue 61: GroupEligibilityFields.holdsValue', () {
    test('Issue 61: a Manual group holds none, whatever its hidden criteria '
        'hold', () {
      expect(
        GroupEligibilityFields.holdsValue(
          _values(
            genders: const [EligibilityGender.boys],
            minAge: const FormAge(years: 5),
            strictAge: true,
          ),
        ),
        isFalse,
      );
    });

    test('Issue 61: values without a mode read as Manual', () {
      expect(
        GroupEligibilityFields.holdsValue(const {
          GenderEligibilityFormFields.gendersId: [EligibilityGender.boys],
        }),
        isFalse,
      );
    });

    test('Issue 61: a criteria mode with nothing filled holds none', () {
      for (final mode in [GroupMode.semiAuto, GroupMode.auto]) {
        expect(GroupEligibilityFields.holdsValue(_values(mode: mode)), isFalse);
      }
    });

    test('Issue 80: no gender ticked, or no genders entry at all, is not a '
        'held criterion', () {
      expect(
        GroupEligibilityFields.holdsValue(
          _values(mode: GroupMode.auto, genders: const []),
        ),
        isFalse,
      );
      expect(
        GroupEligibilityFields.holdsValue(
          {
            ..._values(mode: GroupMode.auto),
          }..remove(GenderEligibilityFormFields.gendersId),
        ),
        isFalse,
      );
      expect(
        GroupEligibilityFields.seeded(const {
          GroupFormFields.modeId: GroupMode.auto,
        })[GenderEligibilityFormFields.gendersId],
        isEmpty,
      );
    });

    test('Issue 61: in a criteria mode a gender, an age on either side, a '
        'part of an age or the Strict age check each count', () {
      for (final values in [
        _values(mode: GroupMode.auto, genders: const [EligibilityGender.girls]),
        _values(mode: GroupMode.auto, minAge: const FormAge(years: 5)),
        _values(mode: GroupMode.semiAuto, maxAge: const FormAge(years: 18)),
        _values(mode: GroupMode.semiAuto, strictAge: true),
        {..._values(mode: GroupMode.auto), _A.maxAgeDaysId: '3'},
      ]) {
        expect(
          GroupEligibilityFields.holdsValue(values),
          isTrue,
          reason: '$values',
        );
      }
    });
  });

  group('Issue 61: GroupEligibilityFields Clear', () {
    final filled = _values(
      mode: GroupMode.auto,
      genders: const [EligibilityGender.boys],
      minAge: const FormAge(years: 5, months: 6),
      maxAge: const FormAge(years: 18),
      strictAge: true,
    );

    testWidgets('Issue 61: clear empties the gender, both ages and the '
        'Strict age check, and sets the mode to Manual', (tester) async {
      final form = await _pump(tester, filled);

      GroupEligibilityFields.clear(form);
      await tester.pumpAndSettle();

      expect(form.value, _values());
      expect(find.text(GroupEligibilityFields.criteriaTitle), findsNothing);
      expect(find.text(GroupMode.manual.label), findsOneWidget);
    });

    testWidgets('Issue 61: without showClear it never draws a Clear', (
      tester,
    ) async {
      await _pump(tester, filled);

      expect(find.text(FormStrings.clear), findsNothing);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: with showClear, Clear shows only while a '
        'criterion is held, and pressing it empties them', (tester) async {
      final form = await _pump(
        tester,
        _values(mode: GroupMode.semiAuto),
        showClear: true,
      );
      expect(find.text(FormStrings.clear), findsNothing);

      await tester.tap(strictAgeBox());
      await tester.pumpAndSettle();
      expect(find.text(FormStrings.clear), findsOneWidget);
      expectNoHostChrome(tester, allowedButtonTexts: {FormStrings.clear});

      await tester.tap(strictAgeBox());
      await tester.pumpAndSettle();
      expect(find.text(FormStrings.clear), findsNothing);

      await enterField(tester, _A.maxAgeMonthsId, '6');
      await tapGenders(tester, const [EligibilityGender.girls]);
      await tester.tap(find.text(FormStrings.clear));
      await tester.pumpAndSettle();

      expect(form.value, _values());
      expect(find.text(FormStrings.clear), findsNothing);
    });

    testWidgets('Issue 61: with enabled false Clear is drawn but does '
        'nothing', (tester) async {
      final form = await _pump(tester, filled, showClear: true, enabled: false);

      await tester.tap(find.text(FormStrings.clear), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(form.value, filled);
      expect(
        tester.widget<ShadButton>(find.byType(ShadButton)).onPressed,
        isNull,
      );
    });
  });

  group('Issue 61: GroupEligibilityFields disabled and narrow', () {
    final seeded = _values(
      mode: GroupMode.semiAuto,
      genders: const [EligibilityGender.girls],
      minAge: const FormAge(years: 5),
    );

    testWidgets('Issue 61: every field responds', (tester) async {
      final form = await _pump(tester, seeded);

      expect(
        [
          for (final entry in form.fields.entries)
            if (!entry.value.enabled) entry.key,
        ],
        isEmpty,
      );
      await enterField(tester, _A.minAgeYearsId, '7');
      expect(form.value[_A.minAgeYearsId], '7');
    });

    testWidgets('Issue 61: with enabled false no field responds, and the '
        'hint is the ordinary one', (tester) async {
      await _pump(tester, seeded, enabled: false);

      expect(find.text(GroupMembershipHeading.modeHint), findsOneWidget);
      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone, criteria and Clear included', (
      tester,
    ) async {
      await expectFitsPhone(
        tester,
        _cluster(GlobalKey<ShadFormState>(), seeded, showClear: true),
      );
      expect(find.text(FormStrings.clear), findsOneWidget);
    });
  });
}
