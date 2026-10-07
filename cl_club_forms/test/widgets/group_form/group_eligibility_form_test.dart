import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_fields.dart'
    show AgeEligibilityFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_validators.dart'
    show AgeEligibilityFormValidators;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) => ShadApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('manual mode validates with no criteria', (tester) async {
    await _setSurface(tester);
    final key = GlobalKey<GroupEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        GroupEligibilityForm(
          key: key,
          initialValues: const {GroupFormFields.modeId: GroupMode.manual},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values![GroupFormFields.modeId], GroupMode.manual);
  });

  testWidgets('auto mode requires at least one criterion', (tester) async {
    await _setSurface(tester);
    final key = GlobalKey<GroupEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        GroupEligibilityForm(
          key: key,
          initialValues: const {GroupFormFields.modeId: GroupMode.auto},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.textContaining('at least one criterion'), findsOneWidget);
  });

  testWidgets('auto mode validates once a gender criterion is set', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<GroupEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        GroupEligibilityForm(
          key: key,
          initialValues: const {
            GroupFormFields.modeId: GroupMode.auto,
            GroupFormFields.genderId: GroupGender.girls,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values![GroupFormFields.genderId], GroupGender.girls);
  });

  Finder input(String id) => find.byWidgetPredicate(
    (w) => w is ShadInputFormField && w.id == id,
  );

  Map<String, dynamic> seeded({
    GroupMode mode = GroupMode.semiAuto,
    FormAge? minAge,
    FormAge? maxAge,
    bool strictAge = false,
  }) => {
    GroupFormFields.modeId: mode,
    GroupFormFields.genderId: null,
    ...AgeEligibilityFormValues.initial(
      minAge: minAge,
      maxAge: maxAge,
      strictAge: strictAge,
    ),
  };

  testWidgets('Issue 33: shows minimum age, maximum age and Strict age '
      'check, and no date pickers', (tester) async {
    await _setSurface(tester);
    await tester.pumpWidget(
      _wrap(GroupEligibilityForm(initialValues: seeded())),
    );
    await tester.pumpAndSettle();

    expect(find.text(AgeEligibilityFields.minAgeTitle), findsOneWidget);
    expect(find.text(AgeEligibilityFields.maxAgeTitle), findsOneWidget);
    expect(find.text(AgeEligibilityFields.strictLabel), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.textContaining('DOB'), findsNothing);
    expect(find.byType(CLDatePickerFormField), findsNothing);
  });

  testWidgets('Issue 33: a seeded band starts clean and comes back from '
      'validate', (tester) async {
    await _setSurface(tester);
    final key = GlobalKey<GroupEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        GroupEligibilityForm(
          key: key,
          initialValues: seeded(
            minAge: const FormAge(years: 5),
            maxAge: const FormAge(years: 18),
            strictAge: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.isDirty, isFalse);
    expect(tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).value, true);
    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(AgeEligibilityFormValues.minAge(values!), const FormAge(years: 5));
    expect(AgeEligibilityFormValues.maxAge(values), const FormAge(years: 18));
    expect(AgeEligibilityFormValues.strictAge(values), isTrue);
  });

  testWidgets('Issue 33: emptying an age clears that bound and dirties the '
      'form', (tester) async {
    await _setSurface(tester);
    final key = GlobalKey<GroupEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        GroupEligibilityForm(
          key: key,
          initialValues: seeded(
            minAge: const FormAge(years: 5),
            maxAge: const FormAge(years: 18),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(input(AgeEligibilityFormFields.minAgeYearsId), '');
    await tester.pumpAndSettle();

    expect(key.currentState!.isDirty, isTrue);
    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(AgeEligibilityFormValues.minAge(values!), isNull);
    expect(AgeEligibilityFormValues.maxAge(values), const FormAge(years: 18));
  });

  testWidgets('Issue 33: a minimum above the maximum shows the inline '
      'message and validate returns null', (tester) async {
    await _setSurface(tester);
    final key = GlobalKey<GroupEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(GroupEligibilityForm(key: key, initialValues: seeded())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(input(AgeEligibilityFormFields.minAgeYearsId), '18');
    await tester.enterText(input(AgeEligibilityFormFields.maxAgeYearsId), '5');
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.text(AgeEligibilityFormValidators.bandMessage), findsOneWidget);
  });

  testWidgets('Issue 33: locked criteria disable the age inputs and the '
      'Strict age check', (tester) async {
    await _setSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GroupEligibilityForm(
          initialValues: seeded(minAge: const FormAge(years: 5)),
          criteriaLocked: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ShadInputFormField>(
            input(AgeEligibilityFormFields.minAgeYearsId),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).enabled,
      isFalse,
    );
  });
}
