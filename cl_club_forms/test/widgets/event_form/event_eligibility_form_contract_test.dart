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

import '../../support/form_harness.dart';

// Issue 61, points that do not apply to EventEligibilityForm: no field of
// its own has a validator (every limit is part of the rule across fields,
// the age band, and shows inline), no field is required, and no parameter
// hides or locks a field. Its other tests are in
// event_eligibility_form_test.dart and event_eligibility_form_reset_test.dart.

const String _genderId = EventFormFields.genderId;
const String _minYears = AgeEligibilityFormFields.minAgeYearsId;
const String _minMonths = AgeEligibilityFormFields.minAgeMonthsId;
const String _minDays = AgeEligibilityFormFields.minAgeDaysId;
const String _maxYears = AgeEligibilityFormFields.maxAgeYearsId;
const String _maxDays = AgeEligibilityFormFields.maxAgeDaysId;
const String _strict = AgeEligibilityFormFields.strictAgeId;

Map<String, dynamic> _seeded({
  EventGender? gender,
  FormAge? minAge,
  FormAge? maxAge,
  bool strictAge = false,
}) => {
  _genderId: gender,
  ...AgeEligibilityFormValues.initial(
    minAge: minAge,
    maxAge: maxAge,
    strictAge: strictAge,
  ),
};

Future<EventEligibilityFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initial,
  bool enabled = true,
  VoidCallback? onChanged,
}) async {
  final key = GlobalKey<EventEligibilityFormState>();
  await pumpForm(
    tester,
    EventEligibilityForm(
      key: key,
      initialValues: initial ?? _seeded(),
      enabled: enabled,
      onChanged: onChanged,
    ),
  );
  return key.currentState!;
}

/// Picks [label] in the gender select, which shows [current].
Future<void> _pickGender(
  WidgetTester tester,
  String current,
  String label,
) async {
  await tester.tap(find.text(current));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Expects the band refused with [message] inline, under the rows.
Future<void> _expectRefused(
  WidgetTester tester,
  EventEligibilityFormState form,
  String message,
) async {
  expect(form.validate(), isNull);
  await tester.pumpAndSettle();
  expect(find.text(message), findsOneWidget);
  // Inline at the foot of the form, not on a field.
  expect(
    tester.getTopLeft(find.text(message)).dy,
    greaterThan(
      tester.getBottomLeft(find.text(AgeEligibilityFields.strictHint)).dy,
    ),
  );
}

void main() {
  group('Issue 61: EventEligibilityForm fields', () {
    testWidgets('Issue 61: its rows are Gender and the two ages with their '
        'parts, none required', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), [
        'Gender',
        'Minimum age',
        'Years',
        'Months',
        'Days',
        'Maximum age',
        'Years',
        'Months',
        'Days',
      ]);
      expectLabelsAreRows(tester);
    });

    testWidgets('Issue 61: it registers the gender, six age parts and the '
        'Strict age check, and nothing else', (tester) async {
      final form = await _pump(tester);

      expect(form.formKey.currentState!.fields.keys.toSet(), {
        _genderId,
        ...AgeEligibilityFormFields.minAgeIds,
        ...AgeEligibilityFormFields.maxAgeIds,
        _strict,
      });
    });

    testWidgets('Issue 61: the gender select offers every gender and reads '
        '"Any gender" while none is chosen', (tester) async {
      await _pump(tester);
      expect(find.text('Any gender'), findsOneWidget);

      await tester.tap(find.text('Any gender'));
      await tester.pumpAndSettle();

      for (final gender in EventGender.values) {
        expect(find.text(gender.label), findsOneWidget, reason: gender.label);
      }
    });

    testWidgets('Issue 61: a seeded gender shows by its label', (tester) async {
      await _pump(tester, initial: _seeded(gender: EventGender.preferNotToSay));

      expect(find.text('Prefer not to say'), findsOneWidget);
      expect(find.text('Any gender'), findsNothing);
    });
  });

  group('Issue 61: EventEligibilityForm age band', () {
    testWidgets('Issue 61: years above 150 are refused inline, 150 is '
        'accepted', (tester) async {
      final form = await _pump(tester);

      await enterField(tester, _maxYears, '151');
      await _expectRefused(
        tester,
        form,
        AgeEligibilityFormValidators.yearsMessage,
      );

      await enterField(tester, _maxYears, '150');
      expect(form.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(
        find.text(AgeEligibilityFormValidators.yearsMessage),
        findsNothing,
      );
    });

    testWidgets('Issue 61: months above 11 are refused inline, 11 is '
        'accepted', (tester) async {
      final form = await _pump(tester);
      await enterField(tester, _minYears, '5');

      await enterField(tester, _minMonths, '12');
      await _expectRefused(
        tester,
        form,
        AgeEligibilityFormValidators.monthsMessage,
      );

      await enterField(tester, _minMonths, '11');
      expect(form.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(
        find.text(AgeEligibilityFormValidators.monthsMessage),
        findsNothing,
      );
    });

    testWidgets('Issue 61: days above 30 are refused inline, 30 is '
        'accepted', (tester) async {
      final form = await _pump(tester);

      await enterField(tester, _maxDays, '31');
      await _expectRefused(
        tester,
        form,
        AgeEligibilityFormValidators.daysMessage,
      );

      await enterField(tester, _maxDays, '30');
      expect(form.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(find.text(AgeEligibilityFormValidators.daysMessage), findsNothing);
    });

    testWidgets('Issue 61: a minimum a day above the maximum is refused '
        'inline, the same age on both sides is accepted', (tester) async {
      final form = await _pump(
        tester,
        initial: _seeded(
          minAge: const FormAge(years: 10),
          maxAge: const FormAge(years: 10),
        ),
      );
      expect(form.validate(), isNotNull);

      await enterField(tester, _minDays, '1');
      await _expectRefused(
        tester,
        form,
        AgeEligibilityFormValidators.bandMessage,
      );

      await enterField(tester, _maxDays, '1');
      expect(form.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(find.text(AgeEligibilityFormValidators.bandMessage), findsNothing);
    });

    testWidgets('Issue 61: letters cannot be typed into an age', (
      tester,
    ) async {
      final form = await _pump(tester);

      await enterField(tester, _minYears, 'a1b2');

      expect(form.validate()![_minYears], '12');
    });
  });

  group('Issue 61: EventEligibilityForm values', () {
    testWidgets('Issue 61: an open event returns the eight entries: no '
        'gender, six empty texts, strict off', (tester) async {
      final form = await _pump(tester);

      expect(form.validate(), {
        _genderId: null,
        _minYears: '',
        _minMonths: '',
        _minDays: '',
        _maxYears: '',
        AgeEligibilityFormFields.maxAgeMonthsId: '',
        _maxDays: '',
        _strict: false,
      });
    });

    testWidgets('Issue 61: seeded eligibility comes back unchanged', (
      tester,
    ) async {
      final initial = _seeded(
        gender: EventGender.female,
        minAge: const FormAge(years: 5, months: 6),
        maxAge: const FormAge(years: 18, days: 2),
        strictAge: true,
      );
      final form = await _pump(tester, initial: initial);

      final values = form.validate()!;

      expect(values, initial);
      expect(values[_genderId], isA<EventGender>());
      expect(values[_minYears], isA<String>());
      expect(values[_strict], isA<bool>());
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: a gender picked in the select comes back from '
        'validate', (tester) async {
      final form = await _pump(tester);

      await _pickGender(tester, 'Any gender', 'Female');

      expect(form.validate()![_genderId], EventGender.female);
      expect(form.hasValue, isTrue);
    });

    testWidgets('Issue 61: the static holdsValue reads a map as hasValue '
        'reads the form', (tester) async {
      expect(EventEligibilityForm.holdsValue(_seeded()), isFalse);
      expect(EventEligibilityForm.holdsValue(const {}), isFalse);
      expect(
        EventEligibilityForm.holdsValue(_seeded(gender: EventGender.other)),
        isTrue,
      );
      expect(
        EventEligibilityForm.holdsValue(
          _seeded(maxAge: const FormAge(years: 0)),
        ),
        isTrue,
      );
      expect(EventEligibilityForm.holdsValue(_seeded(strictAge: true)), isTrue);
    });
  });

  group('Issue 61: EventEligibilityForm isDirty', () {
    testWidgets('Issue 61: an age typed, then emptied again', (tester) async {
      final form = await _pump(tester);
      expect(form.isDirty, isFalse);

      await enterField(tester, _minYears, '5');
      expect(form.isDirty, isTrue);

      await enterField(tester, _minYears, '');
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: a seeded age changed, then typed back', (
      tester,
    ) async {
      final form = await _pump(
        tester,
        initial: _seeded(maxAge: const FormAge(years: 18)),
      );

      await enterField(tester, _maxYears, '19');
      expect(form.isDirty, isTrue);

      await enterField(tester, _maxYears, '18');
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: a gender chosen, then the first one chosen '
        'again', (tester) async {
      final form = await _pump(
        tester,
        initial: _seeded(gender: EventGender.male),
      );
      expect(form.isDirty, isFalse);

      await _pickGender(tester, 'Male', 'Female');
      expect(form.isDirty, isTrue);

      await _pickGender(tester, 'Female', 'Male');
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: the Strict age check ticked, then unticked', (
      tester,
    ) async {
      final form = await _pump(tester);

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();
      expect(form.isDirty, isTrue);

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: onChanged is called for a typed age, a picked '
        'gender and a ticked check', (tester) async {
      var changes = 0;
      await _pump(tester, onChanged: () => changes++);
      expect(changes, 0);

      await enterField(tester, _minYears, '5');
      final afterText = changes;
      expect(afterText, greaterThan(0));

      await _pickGender(tester, 'Any gender', 'Other');
      final afterSelect = changes;
      expect(afterSelect, greaterThan(afterText));

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();
      expect(changes, greaterThan(afterSelect));
    });
  });

  group('Issue 61: EventEligibilityForm and the server', () {
    testWidgets('Issue 61: what the server refuses shows on the gender, on '
        'an age part, and inline', (tester) async {
      final form = await _pump(tester);

      await expectShowsServerErrors(tester, form, _genderId);
      await expectShowsServerErrors(tester, form, _maxYears);
    });

    testWidgets('Issue 61: after a refusal the corrected form validates '
        'and the messages go', (tester) async {
      final form = await _pump(
        tester,
        initial: _seeded(minAge: const FormAge(years: 3)),
      );

      form.showErrors(
        fieldErrors: const {_minYears: 'Too young.'},
        formError: 'Could not update eligibility.',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: fieldWithId(_minYears),
          matching: find.text('Too young.'),
        ),
        findsOneWidget,
      );

      await enterField(tester, _minYears, '5');
      final values = form.validate();
      await tester.pumpAndSettle();

      expect(values, isNotNull);
      expect(AgeEligibilityFormValues.minAge(values!), const FormAge(years: 5));
      expect(find.text('Too young.'), findsNothing);
      expect(find.text('Could not update eligibility.'), findsNothing);
    });
  });

  group('Issue 61: EventEligibilityForm disabled', () {
    testWidgets('Issue 61: with enabled false nothing answers: the select '
        'stays shut, the check unticked, the ages as seeded', (tester) async {
      final initial = _seeded(minAge: const FormAge(years: 5));
      var changes = 0;
      final form = await _pump(
        tester,
        initial: initial,
        enabled: false,
        onChanged: () => changes++,
      );

      await tester.tap(find.text('Any gender'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Female'), findsNothing);

      await tester.tap(find.byType(ShadCheckbox), warnIfMissed: false);
      await tester.tap(
        find.text(AgeEligibilityFields.strictLabel),
        warnIfMissed: false,
      );
      await tester.tap(fieldWithId(_maxYears), warnIfMissed: false);
      await tester.pumpAndSettle();
      tester.testTextInput.enterText('18');
      await tester.pumpAndSettle();

      expect(form.formKey.currentState!.value, initial);
      expect(form.isDirty, isFalse);
      expect(changes, 0);
    });
  });

  group('Issue 61: EventEligibilityForm layout', () {
    testWidgets('Issue 61: it fits a phone with every age part at its '
        'widest and the longest gender', (tester) async {
      await expectFitsPhone(
        tester,
        EventEligibilityForm(
          initialValues: _seeded(
            gender: EventGender.preferNotToSay,
            minAge: const FormAge(years: 150, months: 11, days: 30),
            maxAge: const FormAge(years: 150, months: 11, days: 30),
            strictAge: true,
          ),
        ),
      );
      expect(find.text('Prefer not to say'), findsOneWidget);
    });

    testWidgets('Issue 61: it draws no button: Reset and Save are the '
        "host's", (tester) async {
      await _pump(
        tester,
        initial: _seeded(gender: EventGender.male, strictAge: true),
      );

      expectNoHostChrome(tester);
      expect(find.text('Reset'), findsNothing);
      expect(find.text('Eligibility'), findsNothing);
    });
  });
}
