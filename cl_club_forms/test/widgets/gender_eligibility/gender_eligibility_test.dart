import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/eligibility_checks.dart';

const EligibilityGender _boys = EligibilityGender.boys;
const EligibilityGender _girls = EligibilityGender.girls;
const EligibilityGender _other = EligibilityGender.other;
const EligibilityGender _preferNotToSay = EligibilityGender.preferNotToSay;

/// The gender field alone under a bare form, seeded with [genders].
Future<GlobalKey<ShadFormState>> _pump(
  WidgetTester tester, {
  List<EligibilityGender> genders = const [],
  bool enabled = true,
}) async {
  final key = GlobalKey<ShadFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: ShadForm(
          key: key,
          initialValue: GenderEligibilityFormValues.initial(genders),
          child: GenderEligibilityField(enabled: enabled),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  group('Issue 80: EligibilityGender', () {
    test('Issue 80: one gender per gender a person can register with, in '
        'box order, each with its label', () {
      expect(
        {for (final g in EligibilityGender.values) g: g.label},
        {
          _boys: 'Boys',
          _girls: 'Girls',
          _other: 'Other',
          _preferNotToSay: 'Prefer not to say',
        },
      );
    });
  });

  group('Issue 80: GenderEligibilityText', () {
    test('Issue 80: one gender is "only for" it', () {
      expect(GenderEligibilityText.phrase([_boys]), 'only for Boys');
      expect(
        GenderEligibilityText.sentence('event', [_boys]),
        'This event is only for Boys.',
      );
      expect(GenderEligibilityText.line([_boys]), 'Only for Boys');
    });

    test('Issue 80: two genders are joined by "and"', () {
      expect(
        GenderEligibilityText.phrase([_boys, _girls]),
        'for Boys and Girls',
      );
    });

    test('Issue 80: three genders are listed, the last after "and"', () {
      const three = [_boys, _other, _preferNotToSay];
      expect(
        GenderEligibilityText.phrase(three),
        'for Boys, Other and Prefer not to say',
      );
      expect(
        GenderEligibilityText.sentence('group', three),
        'This group is for Boys, Other and Prefer not to say.',
      );
      expect(
        GenderEligibilityText.line(three),
        'For Boys, Other and Prefer not to say',
      );
    });

    test('Issue 80: no gender is no criterion, and says nothing', () {
      expect(GenderEligibilityText.phrase(const []), isNull);
      expect(GenderEligibilityText.sentence('event', const []), isNull);
      expect(GenderEligibilityText.line(const []), isNull);
    });

    test('Issue 80: the genders are named in box order, once each, '
        'whatever order they come in', () {
      expect(
        GenderEligibilityText.phrase([_preferNotToSay, _boys, _other, _boys]),
        'for Boys, Other and Prefer not to say',
      );
    });
  });

  group('Issue 80: GenderEligibilityFormValues', () {
    test('Issue 80: ordered keeps each gender once, in box order', () {
      expect(
        GenderEligibilityFormValues.ordered([_other, _boys, _other]),
        [_boys, _other],
      );
      expect(GenderEligibilityFormValues.ordered(const []), isEmpty);
    });

    test('Issue 80: initial seeds the entry in box order, none by default', () {
      expect(GenderEligibilityFormValues.initial(), {
        GenderEligibilityFormFields.gendersId: isEmpty,
      });
      expect(
        GenderEligibilityFormValues.initial([_preferNotToSay, _girls]),
        {
          GenderEligibilityFormFields.gendersId: [_girls, _preferNotToSay],
        },
      );
    });

    test('Issue 80: genders reads any list, and none when the entry is '
        'missing or null', () {
      expect(GenderEligibilityFormValues.genders(const {}), isEmpty);
      expect(
        GenderEligibilityFormValues.genders({
          GenderEligibilityFormFields.gendersId: null,
        }),
        isEmpty,
      );
      // ShadForm hands back a deep copy, typed List<dynamic>.
      expect(
        GenderEligibilityFormValues.genders({
          GenderEligibilityFormFields.gendersId: <dynamic>[_other, _boys],
        }),
        [_boys, _other],
      );
    });

    test('Issue 80: holdsValue is true once one gender is held', () {
      expect(GenderEligibilityFormValues.holdsValue(const {}), isFalse);
      expect(
        GenderEligibilityFormValues.holdsValue(gendersEntry([_girls])),
        isTrue,
      );
    });

    test('Issue 80: differ compares the genders as a set and every other '
        'entry by ==', () {
      final a = {
        ...gendersEntry([_boys, _other]),
        'name': 'U12',
      };
      expect(
        GenderEligibilityFormValues.differ(a, {
          ...gendersEntry([_other, _boys]),
          'name': 'U12',
        }),
        isFalse,
      );
      // Equal lists that are not the same list are no change.
      expect(
        GenderEligibilityFormValues.differ(gendersEntry([]), gendersEntry([])),
        isFalse,
      );
      // Another list entry, copied, is no change; changed, it is one.
      expect(
        GenderEligibilityFormValues.differ(
          {
            'coaches': ['Asha'],
          },
          {
            'coaches': List<dynamic>.of(['Asha']),
          },
        ),
        isFalse,
      );
      expect(
        GenderEligibilityFormValues.differ(
          {
            'coaches': ['Asha'],
          },
          {
            'coaches': ['Asha', 'Ben'],
          },
        ),
        isTrue,
      );
      expect(
        GenderEligibilityFormValues.differ(a, {
          ...gendersEntry([_boys]),
          'name': 'U12',
        }),
        isTrue,
      );
      expect(
        GenderEligibilityFormValues.differ(a, {
          ...gendersEntry([_boys, _other]),
          'name': 'U13',
        }),
        isTrue,
      );
      expect(
        GenderEligibilityFormValues.differ(gendersEntry([]), const {}),
        isFalse,
      );
    });
  });

  group('Issue 80: GenderEligibilityField', () {
    testWidgets('Issue 80: it draws a box per gender, labelled, none ticked, '
        'and the hint', (tester) async {
      final key = await _pump(tester);

      for (final gender in EligibilityGender.values) {
        expect(genderBox(gender), findsOneWidget, reason: gender.label);
        expect(find.text(gender.label), findsOneWidget, reason: gender.label);
      }
      expect(tickedGenders(tester), isEmpty);
      expect(find.text(GenderEligibilityField.noneTickedHint), findsOneWidget);
      expect(
        GenderEligibilityFormValues.genders(key.currentState!.value),
        isEmpty,
      );
    });

    testWidgets('Issue 80: ticking boxes holds them in box order and takes '
        'the hint away; unticking every box brings it back', (tester) async {
      final key = await _pump(tester);

      await tapGenders(tester, const [_preferNotToSay, _boys, _other]);

      expect(GenderEligibilityFormValues.genders(key.currentState!.value), [
        _boys,
        _other,
        _preferNotToSay,
      ]);
      expect(find.text(GenderEligibilityField.noneTickedHint), findsNothing);

      await tapGenders(tester, const [_boys, _other, _preferNotToSay]);

      expect(
        GenderEligibilityFormValues.genders(key.currentState!.value),
        isEmpty,
      );
      expect(find.text(GenderEligibilityField.noneTickedHint), findsOneWidget);
    });

    testWidgets('Issue 80: seeded genders show ticked', (tester) async {
      await _pump(tester, genders: const [_girls, _other]);

      expect(tickedGenders(tester), [_girls, _other]);
      expect(find.text(GenderEligibilityField.noneTickedHint), findsNothing);
    });

    testWidgets('Issue 80: a reset of the form unticks the boxes it ticked', (
      tester,
    ) async {
      final key = await _pump(tester);
      await tapGenders(tester, const [_girls]);

      key.currentState!.reset();
      await tester.pumpAndSettle();

      expect(tickedGenders(tester), isEmpty);
    });

    testWidgets('Issue 80: with enabled false no box answers', (tester) async {
      final key = await _pump(tester, enabled: false);

      for (final gender in EligibilityGender.values) {
        await tester.tap(genderBox(gender), warnIfMissed: false);
      }
      await tester.pumpAndSettle();

      expect(tickedGenders(tester), isEmpty);
      expect(
        GenderEligibilityFormValues.genders(key.currentState!.value),
        isEmpty,
      );
    });

    testWidgets('Issue 80: the boxes wrap on a phone without overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pump(tester, genders: EligibilityGender.values);

      expect(tester.takeException(), isNull);
      expect(tickedGenders(tester), EligibilityGender.values);
    });
  });
}
