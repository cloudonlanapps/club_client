import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/constants/form_spacing.dart' show FormSpacing;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_fields.dart'
    show AgeEligibilityFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_input_row.dart'
    show AgeInputRow;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/form_harness.dart';

// The age cluster shared by EventEligibilityForm, GroupCreateForm and
// GroupEligibilityForm, mounted alone under a bare ShadForm. It is a field
// cluster, not a form: validate(), isDirty and showErrors are its host
// form's, and its one rule across fields (the band) is
// AgeEligibilityFormValidators.band, tested in
// age_eligibility_form_validators_test.dart.

const List<String> _ageIds = [
  ...AgeEligibilityFormFields.minAgeIds,
  ...AgeEligibilityFormFields.maxAgeIds,
];

/// Mounts the cluster under a ShadForm seeded with [initial]; returns the
/// form's key.
Future<GlobalKey<ShadFormState>> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initial,
  bool enabled = true,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<ShadFormState>();
  await pumpForm(
    tester,
    ShadForm(
      key: key,
      initialValue: initial ?? AgeEligibilityFormValues.initial(),
      child: AgeEligibilityFields(enabled: enabled),
    ),
    size: size,
  );
  return key;
}

EditableText _editable(WidgetTester tester, String id) =>
    tester.widget<EditableText>(
      find.descendant(of: fieldWithId(id), matching: find.byType(EditableText)),
    );

String _shown(WidgetTester tester, String id) =>
    _editable(tester, id).controller.text;

void main() {
  group('Issue 61: AgeEligibilityFields', () {
    testWidgets('Issue 61: it shows a minimum and a maximum age, each as '
        'years, months and days, none required', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), [
        AgeEligibilityFields.minAgeTitle,
        AgeInputRow.yearsLabel,
        AgeInputRow.monthsLabel,
        AgeInputRow.daysLabel,
        AgeEligibilityFields.maxAgeTitle,
        AgeInputRow.yearsLabel,
        AgeInputRow.monthsLabel,
        AgeInputRow.daysLabel,
      ]);
      expectLabelsAreRows(tester);
      for (final id in _ageIds) {
        expect(fieldWithId(id), findsOneWidget, reason: id);
      }
      expect(find.text(AgeEligibilityFields.emptyHint), findsOneWidget);
    });

    testWidgets('Issue 61: the Strict age check carries its label and its '
        'explanation', (tester) async {
      await _pump(tester);

      final strict = fieldWithId(AgeEligibilityFormFields.strictAgeId);
      expect(
        find.descendant(
          of: strict,
          matching: find.text(AgeEligibilityFields.strictLabel),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: strict,
          matching: find.text(AgeEligibilityFields.strictHint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: the rows are a row gap apart', (tester) async {
      await _pump(tester);

      final cluster = tester.widget<Column>(
        find
            .descendant(
              of: find.byType(AgeEligibilityFields),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(cluster.spacing, FormSpacing.rowGap);
      // Minimum above maximum.
      expect(
        tester.getTopLeft(find.text(AgeEligibilityFields.minAgeTitle)).dy,
        lessThan(
          tester.getTopLeft(find.text(AgeEligibilityFields.maxAgeTitle)).dy,
        ),
      );
    });

    testWidgets('Issue 61: each input writes its own entry of the form', (
      tester,
    ) async {
      final form = await _pump(tester);

      for (final (index, id) in _ageIds.indexed) {
        await enterField(tester, id, '${index + 1}');
      }

      expect(form.currentState!.value, {
        AgeEligibilityFormFields.minAgeYearsId: '1',
        AgeEligibilityFormFields.minAgeMonthsId: '2',
        AgeEligibilityFormFields.minAgeDaysId: '3',
        AgeEligibilityFormFields.maxAgeYearsId: '4',
        AgeEligibilityFormFields.maxAgeMonthsId: '5',
        AgeEligibilityFormFields.maxAgeDaysId: '6',
        AgeEligibilityFormFields.strictAgeId: false,
      });
      expect(
        AgeEligibilityFormValues.minAge(form.currentState!.value),
        const FormAge(years: 1, months: 2, days: 3),
      );
      expect(
        AgeEligibilityFormValues.maxAge(form.currentState!.value),
        const FormAge(years: 4, months: 5, days: 6),
      );
    });

    testWidgets('Issue 61: an input keeps digits only', (tester) async {
      final form = await _pump(tester);

      await enterField(
        tester,
        AgeEligibilityFormFields.minAgeYearsId,
        ' -1a2.5 ',
      );

      expect(
        form.currentState!.value[AgeEligibilityFormFields.minAgeYearsId],
        '125',
      );
      expect(_shown(tester, AgeEligibilityFormFields.minAgeYearsId), '125');
    });

    testWidgets('Issue 61: every age input asks for the number keyboard', (
      tester,
    ) async {
      await _pump(tester);

      for (final id in _ageIds) {
        expect(
          _editable(tester, id).keyboardType,
          TextInputType.number,
          reason: id,
        );
      }
    });

    testWidgets('Issue 61: seeded ages and a seeded Strict age check show '
        'in the inputs', (tester) async {
      final form = await _pump(
        tester,
        initial: AgeEligibilityFormValues.initial(
          minAge: const FormAge(years: 5),
          maxAge: const FormAge(years: 18, months: 6, days: 2),
          strictAge: true,
        ),
      );

      expect(_shown(tester, AgeEligibilityFormFields.minAgeYearsId), '5');
      expect(_shown(tester, AgeEligibilityFormFields.minAgeMonthsId), '');
      expect(_shown(tester, AgeEligibilityFormFields.minAgeDaysId), '');
      expect(_shown(tester, AgeEligibilityFormFields.maxAgeYearsId), '18');
      expect(_shown(tester, AgeEligibilityFormFields.maxAgeMonthsId), '6');
      expect(_shown(tester, AgeEligibilityFormFields.maxAgeDaysId), '2');
      expect(
        tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).value,
        true,
      );
      expect(
        AgeEligibilityFormValues.strictAge(form.currentState!.value),
        true,
      );
    });

    testWidgets('Issue 61: ticking and unticking Strict age check writes '
        'true, then false', (tester) async {
      final form = await _pump(tester);
      expect(
        AgeEligibilityFormValues.strictAge(form.currentState!.value),
        false,
      );

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();
      expect(
        AgeEligibilityFormValues.strictAge(form.currentState!.value),
        true,
      );
      expect(
        AgeEligibilityFormValues.holdsValue(form.currentState!.value),
        true,
      );

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();
      expect(
        AgeEligibilityFormValues.strictAge(form.currentState!.value),
        false,
      );
    });

    testWidgets('Issue 61: without a seeded Strict age check it starts '
        'unticked', (tester) async {
      final form = await _pump(tester, initial: const {});

      expect(
        tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).value,
        false,
      );
      expect(
        AgeEligibilityFormValues.strictAge(form.currentState!.value),
        false,
      );
    });

    testWidgets('Issue 61: taken down and put back, the cluster shows what '
        'the form holds now', (tester) async {
      final form = GlobalKey<ShadFormState>();
      final shown = ValueNotifier<bool>(true);
      addTearDown(shown.dispose);
      await pumpForm(
        tester,
        ShadForm(
          key: form,
          initialValue: AgeEligibilityFormValues.initial(),
          child: ValueListenableBuilder<bool>(
            valueListenable: shown,
            builder: (context, visible, _) => visible
                ? const AgeEligibilityFields()
                : const SizedBox.shrink(),
          ),
        ),
      );
      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();
      expect(
        AgeEligibilityFormValues.strictAge(form.currentState!.value),
        true,
      );

      shown.value = false;
      await tester.pumpAndSettle();
      expect(find.byType(AgeEligibilityFields), findsNothing);
      shown.value = true;
      await tester.pumpAndSettle();

      expect(
        tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).value,
        true,
      );
      expect(
        AgeEligibilityFormValues.strictAge(form.currentState!.value),
        true,
      );
    });

    testWidgets('Issue 61: enabled false locks the six inputs and the '
        'Strict age check', (tester) async {
      final initial = AgeEligibilityFormValues.initial(
        minAge: const FormAge(years: 5),
      );
      final form = await _pump(tester, initial: initial, enabled: false);

      for (final id in _ageIds) {
        expect(
          tester.widget<ShadInputFormField>(fieldWithId(id)).enabled,
          isFalse,
          reason: id,
        );
      }
      await tester.tap(find.byType(ShadCheckbox), warnIfMissed: false);
      await tester.tap(
        find.text(AgeEligibilityFields.strictLabel),
        warnIfMissed: false,
      );
      await tester.tap(
        fieldWithId(AgeEligibilityFormFields.maxAgeYearsId),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      tester.testTextInput.enterText('18');
      await tester.pumpAndSettle();

      expect(form.currentState!.value, initial);
      expect(
        tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).value,
        false,
      );
    });

    testWidgets('Issue 61: it fits a phone with every part at its widest', (
      tester,
    ) async {
      await _pump(
        tester,
        initial: AgeEligibilityFormValues.initial(
          minAge: const FormAge(years: 150, months: 11, days: 30),
          maxAge: const FormAge(years: 150, months: 11, days: 30),
          strictAge: true,
        ),
        size: kPhoneSurface,
      );

      expect(tester.takeException(), isNull);
      // The three inputs of an age share one line, also on a phone.
      final tops = {
        for (final id in AgeEligibilityFormFields.minAgeIds)
          tester.getTopLeft(fieldWithId(id)).dy,
      };
      expect(tops, hasLength(1));
    });
  });

  group('Issue 61: AgeInputRow', () {
    Future<GlobalKey<ShadFormState>> pumpRow(
      WidgetTester tester, {
      bool enabled = true,
    }) async {
      final key = GlobalKey<ShadFormState>();
      await pumpForm(
        tester,
        ShadForm(
          key: key,
          child: AgeInputRow(
            title: 'Age at entry',
            yearsId: 'y',
            monthsId: 'm',
            daysId: 'd',
            enabled: enabled,
          ),
        ),
      );
      return key;
    }

    testWidgets('Issue 61: one titled row holds three labelled inputs under '
        'the ids it is given', (tester) async {
      final form = await pumpRow(tester);

      expect(rowLabels(tester), ['Age at entry', 'Years', 'Months', 'Days']);
      expect(form.currentState!.fields.keys, ['y', 'm', 'd']);

      await enterField(tester, 'y', '7');
      await enterField(tester, 'm', '8');
      await enterField(tester, 'd', '9');
      expect(form.currentState!.value, {'y': '7', 'm': '8', 'd': '9'});
    });

    testWidgets('Issue 61: years, months and days read left to right, a gap '
        'apart and equally wide', (tester) async {
      await pumpRow(tester);

      final years = tester.getRect(fieldWithId('y'));
      final months = tester.getRect(fieldWithId('m'));
      final days = tester.getRect(fieldWithId('d'));
      expect(months.left - years.right, AgeInputRow.inputGap);
      expect(days.left - months.right, AgeInputRow.inputGap);
      expect(months.width, moreOrLessEquals(years.width, epsilon: 0.5));
      expect(days.width, moreOrLessEquals(years.width, epsilon: 0.5));
      expect(years.top, months.top);
    });

    testWidgets('Issue 61: enabled false turns the three inputs off', (
      tester,
    ) async {
      await pumpRow(tester, enabled: false);

      for (final id in ['y', 'm', 'd']) {
        expect(
          tester.widget<ShadInputFormField>(fieldWithId(id)).enabled,
          isFalse,
        );
      }
    });

    testWidgets('Issue 61: the inputs filter to digits', (tester) async {
      final form = await pumpRow(tester);

      await enterField(tester, 'm', '1x1');

      expect(form.currentState!.value['m'], '11');
    });
  });
}
