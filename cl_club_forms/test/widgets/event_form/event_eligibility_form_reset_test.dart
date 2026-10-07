import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_validators.dart'
    show AgeEligibilityFormValidators;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Finder _input(String id) => find.byWidgetPredicate(
  (w) => w is ShadInputFormField && w.id == id,
);

Map<String, dynamic> _seeded({
  EventGender? gender,
  FormAge? minAge,
  FormAge? maxAge,
  bool strictAge = false,
}) => {
  EventFormFields.genderId: gender,
  ...AgeEligibilityFormValues.initial(
    minAge: minAge,
    maxAge: maxAge,
    strictAge: strictAge,
  ),
};

/// Pumps the form and returns its state; [changes] counts `onChanged`.
Future<EventEligibilityFormState> _pump(
  WidgetTester tester,
  Map<String, dynamic> initialValues, {
  List<int>? changes,
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<EventEligibilityFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EventEligibilityForm(
            key: key,
            initialValues: initialValues,
            onChanged: () => changes?.add(1),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState!;
}

void main() {
  testWidgets('Issue 34: an empty event eligibility form holds no value', (
    tester,
  ) async {
    final form = await _pump(tester, _seeded());
    expect(form.hasValue, isFalse);
  });

  testWidgets('Issue 34: gender, either age or the Strict age check each '
      'count as a value', (tester) async {
    for (final values in [
      _seeded(gender: EventGender.female),
      _seeded(minAge: const FormAge(years: 5)),
      _seeded(maxAge: const FormAge(years: 18)),
      _seeded(strictAge: true),
    ]) {
      expect(
        EventEligibilityForm.holdsValue(values),
        isTrue,
        reason: '$values',
      );
      final form = await _pump(tester, values);
      expect(form.hasValue, isTrue, reason: '$values');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Issue 34: typing an age gives the form a value and tells the '
      'host', (tester) async {
    final changes = <int>[];
    final form = await _pump(tester, _seeded(), changes: changes);
    expect(form.hasValue, isFalse);

    await tester.enterText(_input(AgeEligibilityFormFields.maxAgeYearsId), '9');
    await tester.pumpAndSettle();

    expect(form.hasValue, isTrue);
    expect(changes, isNotEmpty);
  });

  testWidgets('Issue 34: reset empties gender, both ages and the Strict age '
      'check, and leaves the form changed', (tester) async {
    final changes = <int>[];
    final form = await _pump(
      tester,
      _seeded(
        gender: EventGender.female,
        minAge: const FormAge(years: 5, months: 6),
        maxAge: const FormAge(years: 18, days: 3),
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
    // The inputs themselves are emptied, not just the value map.
    for (final id in [
      ...AgeEligibilityFormFields.minAgeIds,
      ...AgeEligibilityFormFields.maxAgeIds,
    ]) {
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: _input(id),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        isEmpty,
        reason: id,
      );
    }
    expect(tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).value, false);
    expect(find.text(EventGender.female.label), findsNothing);
    expect(find.text('Any gender'), findsOneWidget);

    final values = form.validate();
    expect(values, isNotNull);
    expect(values![EventFormFields.genderId], isNull);
    expect(AgeEligibilityFormValues.minAge(values), isNull);
    expect(AgeEligibilityFormValues.maxAge(values), isNull);
    expect(AgeEligibilityFormValues.strictAge(values), isFalse);
  });

  testWidgets('Issue 34: reset clears the inline band message', (tester) async {
    final form = await _pump(
      tester,
      _seeded(
        minAge: const FormAge(years: 18),
        maxAge: const FormAge(years: 5),
      ),
    );
    expect(form.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.text(AgeEligibilityFormValidators.bandMessage), findsOneWidget);

    form.reset();
    await tester.pumpAndSettle();

    expect(find.text(AgeEligibilityFormValidators.bandMessage), findsNothing);
  });
}
