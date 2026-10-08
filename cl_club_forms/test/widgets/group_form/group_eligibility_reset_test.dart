import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_fields.dart'
    show AgeEligibilityFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/group_form/group_eligibility_fields.dart'
    show GroupEligibilityFields;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Finder _input(String id) => find.byWidgetPredicate(
  (w) => w is ShadInputFormField && w.id == id,
);

Map<String, dynamic> _seeded({
  GroupMode mode = GroupMode.semiAuto,
  GroupGender gender = GroupGender.any,
  FormAge? minAge,
  FormAge? maxAge,
  bool strictAge = false,
}) => {
  GroupFormFields.modeId: mode,
  GroupFormFields.genderId: gender,
  ...AgeEligibilityFormValues.initial(
    minAge: minAge,
    maxAge: maxAge,
    strictAge: strictAge,
  ),
};

Future<void> _pumpHost(WidgetTester tester, Widget form) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(body: SingleChildScrollView(child: form)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<GroupEligibilityFormState> _pumpEditor(
  WidgetTester tester,
  Map<String, dynamic> initialValues, {
  List<int>? changes,
}) async {
  final key = GlobalKey<GroupEligibilityFormState>();
  await _pumpHost(
    tester,
    GroupEligibilityForm(
      key: key,
      initialValues: initialValues,
      onChanged: () => changes?.add(1),
    ),
  );
  return key.currentState!;
}

/// Picks [mode] in the Mode select, which currently shows [from].
Future<void> _pickMode(
  WidgetTester tester, {
  required GroupMode from,
  required GroupMode mode,
}) async {
  await tester.tap(find.text(from.label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(mode.label).last);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 34: the group eligibility editor', () {
    testWidgets('Issue 34: a Manual group and a criteria mode with nothing '
        'filled hold no value', (tester) async {
      final manual = await _pumpEditor(
        tester,
        _seeded(mode: GroupMode.manual),
      );
      expect(manual.hasValue, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());

      final empty = await _pumpEditor(tester, _seeded());
      expect(empty.hasValue, isFalse);
    });

    testWidgets('Issue 34: gender, either age or the Strict age check each '
        'count as a value', (tester) async {
      for (final values in [
        _seeded(gender: GroupGender.girls),
        _seeded(minAge: const FormAge(years: 5)),
        _seeded(maxAge: const FormAge(years: 18)),
        _seeded(strictAge: true),
      ]) {
        expect(GroupEligibilityForm.holdsValue(values), isTrue);
        final form = await _pumpEditor(tester, values);
        expect(form.hasValue, isTrue, reason: '$values');
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('Issue 34: the editor draws no Reset of its own (the card '
        'supplies it)', (tester) async {
      await _pumpEditor(tester, _seeded(minAge: const FormAge(years: 5)));
      expect(find.text('Reset'), findsNothing);
    });

    testWidgets('Issue 34: reset empties the criteria, sets the mode to '
        'Manual and leaves the form changed', (tester) async {
      final changes = <int>[];
      final form = await _pumpEditor(
        tester,
        _seeded(
          mode: GroupMode.auto,
          gender: GroupGender.boys,
          minAge: const FormAge(years: 5),
          maxAge: const FormAge(years: 18),
          strictAge: true,
        ),
        changes: changes,
      );
      expect(form.isDirty, isFalse);

      form.reset();
      await tester.pumpAndSettle();

      expect(form.hasValue, isFalse);
      expect(form.isDirty, isTrue);
      expect(changes, isNotEmpty);
      // Manual: the mode select shows it and the criteria are gone.
      expect(find.text(GroupMode.manual.label), findsOneWidget);
      expect(find.text(AgeEligibilityFields.minAgeTitle), findsNothing);

      final values = form.validate();
      expect(values, isNotNull);
      expect(values![GroupFormFields.modeId], GroupMode.manual);
      expect(values[GroupFormFields.genderId], GroupGender.any);
      expect(AgeEligibilityFormValues.minAge(values), isNull);
      expect(AgeEligibilityFormValues.maxAge(values), isNull);
      expect(AgeEligibilityFormValues.strictAge(values), isFalse);
    });

    testWidgets('Issue 34: after a reset, choosing a criteria mode again '
        'shows empty criteria', (tester) async {
      final form = await _pumpEditor(
        tester,
        _seeded(
          gender: GroupGender.boys,
          minAge: const FormAge(years: 5),
          strictAge: true,
        ),
      );
      form.reset();
      await tester.pumpAndSettle();

      await _pickMode(
        tester,
        from: GroupMode.manual,
        mode: GroupMode.semiAuto,
      );

      expect(find.text(AgeEligibilityFields.minAgeTitle), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: _input(AgeEligibilityFormFields.minAgeYearsId),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        isEmpty,
      );
      expect(
        tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).value,
        false,
      );
      expect(find.text(GroupGender.any.label), findsOneWidget);
      expect(form.hasValue, isFalse);
    });
  });

  group('Issue 34: group create', () {
    Future<GroupCreateFormState> pumpCreate(WidgetTester tester) async {
      final key = GlobalKey<GroupCreateFormState>();
      await _pumpHost(tester, GroupCreateForm(key: key));
      return key.currentState!;
    }

    bool holdsValue(GroupCreateFormState form) =>
        GroupEligibilityFields.holdsValue(form.formKey.currentState!.value);

    testWidgets('Issue 34: no Reset on a fresh Manual group, nor on a '
        'criteria mode with nothing filled', (tester) async {
      final form = await pumpCreate(tester);
      expect(find.text('Reset'), findsNothing);
      expect(holdsValue(form), isFalse);

      await _pickMode(tester, from: GroupMode.manual, mode: GroupMode.auto);

      expect(find.text(AgeEligibilityFields.minAgeTitle), findsOneWidget);
      expect(find.text('Reset'), findsNothing);
    });

    testWidgets('Issue 34: Reset appears inside the eligibility block once a '
        'criterion is set', (tester) async {
      final form = await pumpCreate(tester);
      await _pickMode(tester, from: GroupMode.manual, mode: GroupMode.auto);

      await tester.enterText(
        _input(AgeEligibilityFormFields.minAgeYearsId),
        '5',
      );
      await tester.pumpAndSettle();

      final reset = find.text('Reset');
      expect(reset, findsOneWidget);
      expect(holdsValue(form), isTrue);
      // Inside the block: under the criteria, above the "add me" switch.
      expect(
        tester.getTopLeft(reset).dy,
        greaterThan(tester.getTopLeft(find.text('Gender')).dy),
      );
      expect(
        tester.getTopLeft(reset).dy,
        lessThan(tester.getTopLeft(find.text('Add me into the group')).dy),
      );
    });

    testWidgets('Issue 34: pressing Reset empties the criteria, sets the '
        'mode to Manual, hides the button and keeps the name', (tester) async {
      final form = await pumpCreate(tester);
      await tester.enterText(_input(GroupFormFields.nameId), 'Juniors');
      await _pickMode(tester, from: GroupMode.manual, mode: GroupMode.auto);
      await tester.enterText(
        _input(AgeEligibilityFormFields.minAgeYearsId),
        '5',
      );
      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Reset'), findsNothing);
      expect(find.text(AgeEligibilityFields.minAgeTitle), findsNothing);
      expect(find.text(GroupMode.manual.label), findsOneWidget);
      expect(holdsValue(form), isFalse);

      final values = form.validate()!;
      await tester.pumpAndSettle();

      expect(values[GroupFormFields.nameId], 'Juniors');
      expect(values[GroupFormFields.modeId], GroupMode.manual);
      expect(values[GroupFormFields.genderId], GroupGender.any);
      expect(AgeEligibilityFormValues.minAge(values), isNull);
      expect(AgeEligibilityFormValues.strictAge(values), isFalse);
    });
  });
}
