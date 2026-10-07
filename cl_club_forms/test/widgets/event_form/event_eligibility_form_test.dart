import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/constants/form_spacing.dart' show FormSpacing;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_fields.dart'
    show AgeEligibilityFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_validators.dart'
    show AgeEligibilityFormValidators;
import 'package:cl_club_forms/src/widgets/form/form_body.dart' show FormBody;
import 'package:cl_club_forms/src/widgets/form/labeled_form_row.dart'
    show LabeledFormRow;
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
  testWidgets('Issue 678: no-constraint form validates and stays clean', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<EventEligibilityFormState>();
    // The section editor always seeds the eligibility keys (unset when the
    // event is open), mirroring buildEventFormInitialValues.
    await tester.pumpWidget(
      _wrap(
        EventEligibilityForm(
          key: key,
          initialValues: {
            EventFormFields.genderId: EventGender.any,
            ...AgeEligibilityFormValues.initial(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values![EventFormFields.genderId], EventGender.any);
    expect(AgeEligibilityFormValues.minAge(values), isNull);
    expect(key.currentState!.isDirty, isFalse);
  });

  testWidgets('Issue 678: seeded values validate and start clean', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<EventEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        EventEligibilityForm(
          key: key,
          initialValues: {
            EventFormFields.genderId: EventGender.boys,
            ...AgeEligibilityFormValues.initial(
              minAge: const FormAge(years: 5),
              maxAge: const FormAge(years: 18),
            ),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values![EventFormFields.genderId], EventGender.boys);
    expect(key.currentState!.isDirty, isFalse);
  });

  testWidgets('Issue 678: rejects an inverted age band', (tester) async {
    await _setSurface(tester);
    final key = GlobalKey<EventEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        EventEligibilityForm(
          key: key,
          initialValues: AgeEligibilityFormValues.initial(
            minAge: const FormAge(years: 18),
            maxAge: const FormAge(years: 5),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.text(AgeEligibilityFormValidators.bandMessage), findsOneWidget);
  });

  Finder input(String id) => find.byWidgetPredicate(
    (w) => w is ShadInputFormField && w.id == id,
  );

  testWidgets(
    'Issue 33: shows minimum age, maximum age and Strict age check, and no '
    'date pickers',
    (tester) async {
      await _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          EventEligibilityForm(
            initialValues: {
              EventFormFields.genderId: EventGender.any,
              ...AgeEligibilityFormValues.initial(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AgeEligibilityFields.minAgeTitle), findsOneWidget);
      expect(find.text(AgeEligibilityFields.maxAgeTitle), findsOneWidget);
      expect(find.text(AgeEligibilityFields.strictLabel), findsOneWidget);
      expect(find.text(AgeEligibilityFields.strictHint), findsOneWidget);
      for (final id in [
        ...AgeEligibilityFormFields.minAgeIds,
        ...AgeEligibilityFormFields.maxAgeIds,
      ]) {
        expect(input(id), findsOneWidget);
      }
      expect(find.byType(ShadCheckbox), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.textContaining('DOB'), findsNothing);
      expect(find.byType(CLDatePickerFormField), findsNothing);
    },
  );

  testWidgets('Issue 33: typed ages and a ticked Strict age check come back '
      'from validate, and the form is dirty', (tester) async {
    await _setSurface(tester);
    final key = GlobalKey<EventEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        EventEligibilityForm(
          key: key,
          initialValues: {
            EventFormFields.genderId: EventGender.any,
            ...AgeEligibilityFormValues.initial(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(key.currentState!.isDirty, isFalse);

    await tester.enterText(input(AgeEligibilityFormFields.minAgeYearsId), '5');
    await tester.enterText(input(AgeEligibilityFormFields.maxAgeYearsId), '18');
    await tester.tap(find.byType(ShadCheckbox));
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(AgeEligibilityFormValues.minAge(values!), const FormAge(years: 5));
    expect(AgeEligibilityFormValues.maxAge(values), const FormAge(years: 18));
    expect(AgeEligibilityFormValues.strictAge(values), isTrue);
    expect(key.currentState!.isDirty, isTrue);
  });

  testWidgets('Issue 33: emptying an age leaves no bound on that side', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<EventEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        EventEligibilityForm(
          key: key,
          initialValues: AgeEligibilityFormValues.initial(
            minAge: const FormAge(years: 5),
            maxAge: const FormAge(years: 18),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(input(AgeEligibilityFormFields.maxAgeYearsId), '');
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(AgeEligibilityFormValues.minAge(values!), const FormAge(years: 5));
    expect(AgeEligibilityFormValues.maxAge(values), isNull);
  });

  testWidgets('Issue 33: a minimum above the maximum shows the inline '
      'message and validate returns null', (tester) async {
    await _setSurface(tester);
    final key = GlobalKey<EventEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        EventEligibilityForm(
          key: key,
          initialValues: AgeEligibilityFormValues.initial(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(input(AgeEligibilityFormFields.minAgeYearsId), '18');
    await tester.enterText(input(AgeEligibilityFormFields.maxAgeYearsId), '5');
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.text(AgeEligibilityFormValidators.bandMessage), findsOneWidget);

    // Corrected, the message goes and the values come back.
    await tester.enterText(input(AgeEligibilityFormFields.minAgeYearsId), '4');
    await tester.pumpAndSettle();
    expect(key.currentState!.validate(), isNotNull);
    await tester.pumpAndSettle();
    expect(find.text(AgeEligibilityFormValidators.bandMessage), findsNothing);
  });

  testWidgets('Issue 33: months above 11 show the inline message', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<EventEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        EventEligibilityForm(
          key: key,
          initialValues: AgeEligibilityFormValues.initial(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(input(AgeEligibilityFormFields.minAgeYearsId), '5');
    await tester.enterText(
      input(AgeEligibilityFormFields.minAgeMonthsId),
      '12',
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(
      find.text(AgeEligibilityFormValidators.monthsMessage),
      findsOneWidget,
    );
  });

  testWidgets('Issue 33: the age cluster fits a phone-width editor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        Padding(
          padding: const EdgeInsets.all(16),
          child: EventEligibilityForm(
            initialValues: AgeEligibilityFormValues.initial(
              minAge: const FormAge(years: 5, months: 11, days: 30),
              maxAge: const FormAge(years: 150, months: 11, days: 30),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AgeEligibilityFields.strictHint), findsOneWidget);
  });

  group('Issue 54: EventEligibilityForm follows the form contract', () {
    Future<GlobalKey<EventEligibilityFormState>> pump(
      WidgetTester tester, {
      bool enabled = true,
    }) async {
      await _setSurface(tester);
      final key = GlobalKey<EventEligibilityFormState>();
      await tester.pumpWidget(
        _wrap(
          EventEligibilityForm(
            key: key,
            initialValues: {
              EventFormFields.genderId: EventGender.any,
              ...AgeEligibilityFormValues.initial(),
            },
            enabled: enabled,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return key;
    }

    testWidgets('Issue 54: gender, the ages and their parts are labelled '
        'rows', (tester) async {
      await pump(tester);

      for (final label in [
        'Gender',
        AgeEligibilityFields.minAgeTitle,
        AgeEligibilityFields.maxAgeTitle,
      ]) {
        expect(
          find.descendant(
            of: find.byType(LabeledFormRow),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
      // Years, months and days of both ages.
      expect(find.text('Years'), findsNWidgets(2));
      final inputs = tester.widgetList<ShadInputFormField>(
        find.byType(ShadInputFormField),
      );
      expect(inputs, hasLength(6));
      expect(inputs.every((input) => input.label == null), isTrue);
    });

    testWidgets('Issue 54: the rows are stacked by FormBody, the age rows '
        'with the same gap', (tester) async {
      await pump(tester);

      expect(find.byType(FormBody), findsOneWidget);
      final cluster = tester.widget<Column>(
        find
            .descendant(
              of: find.byType(AgeEligibilityFields),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(cluster.spacing, FormSpacing.rowGap);
    });

    testWidgets('Issue 54: enabled false turns every field off', (
      tester,
    ) async {
      await pump(tester, enabled: false);

      final inputs = tester.widgetList<ShadInputFormField>(
        find.byType(ShadInputFormField),
      );
      expect(inputs.every((input) => !input.enabled), isTrue);
      expect(
        tester
            .widget<ShadSelectFormField<EventGender>>(
              find.byType(ShadSelectFormField<EventGender>),
            )
            .enabled,
        isFalse,
      );
    });

    testWidgets('Issue 54: a refusal of the server shows on the field, and '
        'inline', (tester) async {
      final key = await pump(tester);

      key.currentState!.showErrors(
        fieldErrors: const {
          AgeEligibilityFormFields.minAgeYearsId: 'Too young.',
        },
        formError: 'Could not update eligibility.',
      );
      await tester.pumpAndSettle();

      expect(find.text('Too young.'), findsOneWidget);
      expect(find.text('Could not update eligibility.'), findsOneWidget);
    });
  });
}
