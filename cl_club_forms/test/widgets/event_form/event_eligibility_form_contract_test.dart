import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_fields.dart'
    show AgeEligibilityFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_validators.dart'
    show AgeEligibilityFormValidators;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/eligibility_checks.dart';
import '../../support/form_harness.dart';

// Issue 61, points that do not apply to EventEligibilityForm: no field of
// its own has a validator (every limit is part of the rule across fields,
// the age band, and shows inline), no field is required, and no parameter
// hides or locks a field. Its other tests are in
// event_eligibility_form_test.dart and event_eligibility_form_clear_test.dart.

const String _genderId = GenderEligibilityFormFields.gendersId;
const String _minYears = AgeEligibilityFormFields.minAgeYearsId;
const String _minMonths = AgeEligibilityFormFields.minAgeMonthsId;
const String _minDays = AgeEligibilityFormFields.minAgeDaysId;
const String _maxYears = AgeEligibilityFormFields.maxAgeYearsId;
const String _maxDays = AgeEligibilityFormFields.maxAgeDaysId;
const String _strict = AgeEligibilityFormFields.strictAgeId;

Map<String, dynamic> _seeded({
  List<EligibilityGender> genders = const [],
  FormAge? minAge,
  FormAge? maxAge,
  bool strictAge = false,
}) => {
  _genderId: genders,
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

    testWidgets('Issue 80: the Gender row has a box per gender, none '
        'ticked, and says that none ticked admits every gender', (
      tester,
    ) async {
      await _pump(tester);

      for (final gender in EligibilityGender.values) {
        expect(genderBox(gender), findsOneWidget, reason: gender.label);
        expect(find.text(gender.label), findsOneWidget, reason: gender.label);
      }
      expect(tickedGenders(tester), isEmpty);
      expect(find.text(GenderEligibilityField.noneTickedHint), findsOneWidget);
      expect(find.text('Any'), findsNothing);
    });

    testWidgets('Issue 80: a seeded gender shows ticked, and the hint is '
        'gone', (tester) async {
      await _pump(
        tester,
        initial: _seeded(genders: const [EligibilityGender.girls]),
      );

      expect(tickedGenders(tester), [EligibilityGender.girls]);
      expect(find.text(GenderEligibilityField.noneTickedHint), findsNothing);
    });

    testWidgets('Issue 80: with no genders among the initial values none is '
        'ticked, and the form is clean and holds no value', (tester) async {
      final form = await _pump(
        tester,
        initial: AgeEligibilityFormValues.initial(),
      );

      expect(
        GenderEligibilityFormValues.genders(form.formKey.currentState!.value),
        isEmpty,
      );
      expect(form.isDirty, isFalse);
      expect(form.hasValue, isFalse);
      for (final label in ['Male', 'Female']) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });

    testWidgets('Issue 80: ticking Boys, Other and Prefer not to say '
        'validates to exactly those three, in box order', (tester) async {
      final form = await _pump(tester);

      await tapGenders(tester, const [
        EligibilityGender.preferNotToSay,
        EligibilityGender.boys,
        EligibilityGender.other,
      ]);

      expect(GenderEligibilityFormValues.genders(form.validate()!), const [
        EligibilityGender.boys,
        EligibilityGender.other,
        EligibilityGender.preferNotToSay,
      ]);
      expect(form.hasValue, isTrue);
      expect(form.isDirty, isTrue);
      expect(find.text(GenderEligibilityField.noneTickedHint), findsNothing);
    });

    testWidgets('Issue 80: each box ticked then unticked validates to no '
        'gender criterion, and the form is clean again', (tester) async {
      for (final gender in EligibilityGender.values) {
        final form = await _pump(tester);

        await tapGenders(tester, [gender]);
        expect(GenderEligibilityFormValues.genders(form.validate()!), [gender]);
        expect(form.hasValue, isTrue);
        expect(form.isDirty, isTrue);

        await tapGenders(tester, [gender]);
        final values = form.validate()!;
        expect(GenderEligibilityFormValues.genders(values), isEmpty);
        expect(GenderEligibilityFormValues.holdsValue(values), isFalse);
        expect(form.hasValue, isFalse);
        expect(form.isDirty, isFalse, reason: gender.label);
        expect(
          find.text(GenderEligibilityField.noneTickedHint),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('Issue 80: an event seeded with genders can have every box '
        'unticked, which holds no value', (tester) async {
      final form = await _pump(
        tester,
        initial: _seeded(
          genders: const [EligibilityGender.girls, EligibilityGender.other],
        ),
      );
      expect(form.hasValue, isTrue);
      expect(form.isDirty, isFalse);

      await tapGenders(tester, const [
        EligibilityGender.girls,
        EligibilityGender.other,
      ]);

      expect(GenderEligibilityFormValues.genders(form.validate()!), isEmpty);
      expect(form.hasValue, isFalse);
      expect(form.isDirty, isTrue);
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
        _genderId: <EligibilityGender>[],
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
        genders: const [EligibilityGender.girls],
        minAge: const FormAge(years: 5, months: 6),
        maxAge: const FormAge(years: 18, days: 2),
        strictAge: true,
      );
      final form = await _pump(tester, initial: initial);

      final values = form.validate()!;

      expect(values, initial);
      expect(values[_genderId], isA<List<Object?>>());
      expect(values[_minYears], isA<String>());
      expect(values[_strict], isA<bool>());
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: a gender ticked comes back from validate', (
      tester,
    ) async {
      final form = await _pump(tester);

      await tapGenders(tester, const [EligibilityGender.girls]);

      expect(GenderEligibilityFormValues.genders(form.validate()!), const [
        EligibilityGender.girls,
      ]);
      expect(form.hasValue, isTrue);
    });

    testWidgets('Issue 61: the static holdsValue reads a map as hasValue '
        'reads the form', (tester) async {
      expect(EventEligibilityForm.holdsValue(_seeded()), isFalse);
      expect(EventEligibilityForm.holdsValue(const {}), isFalse);
      expect(
        EventEligibilityForm.holdsValue(
          _seeded(genders: const [EligibilityGender.boys]),
        ),
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

    testWidgets('Issue 80: a ticked gender swapped for another, then swapped '
        'back, is clean again', (tester) async {
      final form = await _pump(
        tester,
        initial: _seeded(genders: const [EligibilityGender.boys]),
      );
      expect(form.isDirty, isFalse);

      await tapGenders(tester, const [
        EligibilityGender.boys,
        EligibilityGender.girls,
      ]);
      expect(form.isDirty, isTrue);

      await tapGenders(tester, const [
        EligibilityGender.girls,
        EligibilityGender.boys,
      ]);
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: the Strict age check ticked, then unticked', (
      tester,
    ) async {
      final form = await _pump(tester);

      await tester.tap(strictAgeBox());
      await tester.pumpAndSettle();
      expect(form.isDirty, isTrue);

      await tester.tap(strictAgeBox());
      await tester.pumpAndSettle();
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: onChanged is called for a typed age, a ticked '
        'gender and a ticked check', (tester) async {
      var changes = 0;
      await _pump(tester, onChanged: () => changes++);
      expect(changes, 0);

      await enterField(tester, _minYears, '5');
      final afterText = changes;
      expect(afterText, greaterThan(0));

      await tapGenders(tester, const [EligibilityGender.girls]);
      final afterSelect = changes;
      expect(afterSelect, greaterThan(afterText));

      await tester.tap(strictAgeBox());
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
    testWidgets('Issue 61: with enabled false nothing answers: the gender '
        'boxes and the check stay unticked, the ages as seeded', (
      tester,
    ) async {
      final initial = _seeded(minAge: const FormAge(years: 5));
      var changes = 0;
      final form = await _pump(
        tester,
        initial: initial,
        enabled: false,
        onChanged: () => changes++,
      );

      for (final gender in EligibilityGender.values) {
        await tester.tap(genderBox(gender), warnIfMissed: false);
      }
      await tester.pumpAndSettle();
      expect(tickedGenders(tester), isEmpty);

      await tester.tap(strictAgeBox(), warnIfMissed: false);
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
        'widest and every gender ticked', (tester) async {
      await expectFitsPhone(
        tester,
        EventEligibilityForm(
          initialValues: _seeded(
            genders: EligibilityGender.values,
            minAge: const FormAge(years: 150, months: 11, days: 30),
            maxAge: const FormAge(years: 150, months: 11, days: 30),
            strictAge: true,
          ),
        ),
      );
      expect(find.text('Prefer not to say'), findsOneWidget);
    });

    testWidgets('Issue 61: it draws no button: Clear and Save are the '
        "host's", (tester) async {
      await _pump(
        tester,
        initial: _seeded(
          genders: const [EligibilityGender.boys],
          strictAge: true,
        ),
      );

      expectNoHostChrome(tester);
      expect(find.text('Clear'), findsNothing);
      expect(find.text('Eligibility'), findsNothing);
    });
  });
}
