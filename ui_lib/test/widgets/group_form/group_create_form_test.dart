import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/age_eligibility/age_eligibility_fields.dart'
    show AgeEligibilityFields;
import 'package:ui_lib/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:ui_lib/src/widgets/age_eligibility/age_eligibility_form_validators.dart'
    show AgeEligibilityFormValidators;
import 'package:ui_lib/ui_lib.dart';

Widget _wrap(Widget child) => ShadApp(
  home: Scaffold(
    body: SingleChildScrollView(child: child),
  ),
);

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('defaults to manual mode and hides eligibility criteria', (
    tester,
  ) async {
    await _setSurface(tester);
    await tester.pumpWidget(_wrap(GroupCreateForm(onSubmit: (_) async {})));
    await tester.pumpAndSettle();

    expect(find.text('Mode'), findsOneWidget);
    expect(find.text(AgeEligibilityFields.minAgeTitle), findsNothing);
    expect(find.text('Gender'), findsNothing);
  });

  testWidgets('selecting Auto reveals the eligibility criteria', (
    tester,
  ) async {
    await _setSurface(tester);
    await tester.pumpWidget(_wrap(GroupCreateForm(onSubmit: (_) async {})));
    await tester.pumpAndSettle();

    // Open the mode select (shows the current value "Manual") and pick "Auto".
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto').last);
    await tester.pumpAndSettle();

    expect(find.text(AgeEligibilityFields.minAgeTitle), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
  });

  testWidgets('submits manual group with addMe flag in the value map', (
    tester,
  ) async {
    await _setSurface(tester);
    final formKey = GlobalKey<GroupCreateFormState>();
    Map<String, dynamic>? submitted;
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          key: formKey,
          onSubmit: (values) async => submitted = values,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is ShadInputFormField && w.id == GroupFormFields.nameId,
      ),
      'U12 Boys',
    );
    await formKey.currentState!.handleSubmit();
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted![GroupFormFields.nameId], 'U12 Boys');
    expect(submitted![GroupFormFields.modeId], GroupMode.manual);
    expect(submitted![GroupFormFields.addMeId], false);
  });

  testWidgets('blocks submit when the name is empty', (tester) async {
    await _setSurface(tester);
    final formKey = GlobalKey<GroupCreateFormState>();
    var submitCount = 0;
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          key: formKey,
          onSubmit: (_) async => submitCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await formKey.currentState!.handleSubmit();
    await tester.pumpAndSettle();

    expect(submitCount, 0);
  });

  testWidgets('accepts and submits initial values (not defaults)', (
    tester,
  ) async {
    await _setSurface(tester);
    final formKey = GlobalKey<GroupCreateFormState>();
    Map<String, dynamic>? submitted;
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          key: formKey,
          initialValues: const {
            GroupFormFields.nameId: 'U10 Girls',
            GroupFormFields.descriptionId: 'desc',
            GroupFormFields.modeId: GroupMode.manual,
            GroupFormFields.addMeId: true,
          },
          onSubmit: (values) async => submitted = values,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await formKey.currentState!.handleSubmit();
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted![GroupFormFields.nameId], 'U10 Girls');
    // addMe reflects the passed initial value, not the `false` default.
    expect(submitted![GroupFormFields.addMeId], true);
  });

  testWidgets('isDirty is false initially and true after a field change', (
    tester,
  ) async {
    await _setSurface(tester);
    final formKey = GlobalKey<GroupCreateFormState>();
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          key: formKey,
          initialValues: const {
            GroupFormFields.nameId: 'U10 Girls',
            GroupFormFields.descriptionId: '',
            GroupFormFields.modeId: GroupMode.manual,
            GroupFormFields.addMeId: false,
          },
          onSubmit: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      formKey.currentState!.isDirty,
      isFalse,
      reason: 'unchanged form must not be dirty (no discard prompt)',
    );

    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is ShadInputFormField && w.id == GroupFormFields.nameId,
      ),
      'U12 Girls',
    );
    await tester.pump();

    expect(
      formKey.currentState!.isDirty,
      isTrue,
      reason: 'editing a field marks the form dirty (discard prompt)',
    );
  });

  Finder input(String id) => find.byWidgetPredicate(
    (w) => w is ShadInputFormField && w.id == id,
  );

  testWidgets('Issue 33: a criteria mode shows minimum age, maximum age and '
      'Strict age check, and no date pickers', (tester) async {
    await _setSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          initialValues: {
            ...GroupCreateForm.emptyValues,
            GroupFormFields.modeId: GroupMode.semiAuto,
          },
          onSubmit: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AgeEligibilityFields.minAgeTitle), findsOneWidget);
    expect(find.text(AgeEligibilityFields.maxAgeTitle), findsOneWidget);
    expect(find.text(AgeEligibilityFields.strictLabel), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.textContaining('DOB'), findsNothing);
    expect(find.byType(CLDatePickerFormField), findsNothing);
  });

  testWidgets('Issue 33: submits the ages and the Strict age check', (
    tester,
  ) async {
    await _setSurface(tester);
    final formKey = GlobalKey<GroupCreateFormState>();
    Map<String, dynamic>? submitted;
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          key: formKey,
          initialValues: {
            ...GroupCreateForm.emptyValues,
            GroupFormFields.nameId: 'Juniors',
            GroupFormFields.modeId: GroupMode.semiAuto,
            GroupFormFields.genderId: null,
          },
          onSubmit: (values) async => submitted = values,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(formKey.currentState!.isDirty, isFalse);

    await tester.enterText(input(AgeEligibilityFormFields.minAgeYearsId), '5');
    await tester.enterText(input(AgeEligibilityFormFields.maxAgeYearsId), '18');
    await tester.tap(find.byType(ShadCheckbox));
    await tester.pumpAndSettle();
    await formKey.currentState!.handleSubmit();
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(
      AgeEligibilityFormValues.minAge(submitted!),
      const FormAge(years: 5),
    );
    expect(
      AgeEligibilityFormValues.maxAge(submitted!),
      const FormAge(years: 18),
    );
    expect(AgeEligibilityFormValues.strictAge(submitted!), isTrue);
  });

  testWidgets('Issue 33: a minimum above the maximum shows the inline '
      'message and does not submit', (tester) async {
    await _setSurface(tester);
    final formKey = GlobalKey<GroupCreateFormState>();
    var submitCount = 0;
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          key: formKey,
          initialValues: {
            ...GroupCreateForm.emptyValues,
            GroupFormFields.nameId: 'Juniors',
            GroupFormFields.modeId: GroupMode.auto,
          },
          onSubmit: (_) async => submitCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(input(AgeEligibilityFormFields.minAgeYearsId), '18');
    await tester.enterText(input(AgeEligibilityFormFields.maxAgeYearsId), '5');
    await tester.pumpAndSettle();
    await formKey.currentState!.handleSubmit();
    await tester.pumpAndSettle();

    expect(submitCount, 0);
    expect(find.text(AgeEligibilityFormValidators.bandMessage), findsOneWidget);
  });

  testWidgets('Issue 33: an age alone is a criterion for an auto group', (
    tester,
  ) async {
    await _setSurface(tester);
    final formKey = GlobalKey<GroupCreateFormState>();
    var submitCount = 0;
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          key: formKey,
          initialValues: {
            ...GroupCreateForm.emptyValues,
            GroupFormFields.nameId: 'Juniors',
            GroupFormFields.modeId: GroupMode.auto,
          },
          onSubmit: (_) async => submitCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await formKey.currentState!.handleSubmit();
    await tester.pumpAndSettle();
    expect(submitCount, 0);
    expect(find.textContaining('at least one criterion'), findsOneWidget);

    await tester.enterText(input(AgeEligibilityFormFields.maxAgeYearsId), '12');
    await tester.pumpAndSettle();
    await formKey.currentState!.handleSubmit();
    await tester.pumpAndSettle();
    expect(submitCount, 1);
  });
}
