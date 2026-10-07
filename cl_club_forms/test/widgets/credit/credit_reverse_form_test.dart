// CreditReverseForm against the list of club_client#61. It has two typed
// fields and nothing else, so: no rule across fields, no parameter that
// hides a field (`unspent` sets the cap and the seed), and no button at all.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';

typedef _F = CreditFormFields;

Future<CreditReverseFormState> _pump(
  WidgetTester tester, {
  int unspent = 4,
  bool enabled = true,
}) async {
  final key = GlobalKey<CreditReverseFormState>();
  await pumpForm(
    tester,
    CreditReverseForm(key: key, unspent: unspent, enabled: enabled),
  );
  return key.currentState!;
}

Future<Map<String, dynamic>?> _validate(
  WidgetTester tester,
  CreditReverseFormState state,
) async {
  final values = state.validate();
  await tester.pumpAndSettle();
  return values;
}

void main() {
  group('Issue 61: CreditReverseForm', () {
    testWidgets('Issue 61: it shows its two fields as required labelled '
        'rows, the credits capped at and seeded with what is unspent', (
      tester,
    ) async {
      await _pump(tester, unspent: 7);

      expect(rowLabels(tester), ['Credits (max 7) *', 'Reason *']);
      expectLabelsAreRows(tester);
      expect(formOf(tester).fields.keys, {_F.creditsId, _F.reasonId});
      expect(
        find.descendant(
          of: fieldWithId(_F.creditsId),
          matching: find.text('7'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: it draws no heading and no button', (tester) async {
      await _pump(tester);

      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: credits that are not a whole number are refused '
        'on the field', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Entered twice');
      await enterField(tester, _F.creditsId, '');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.creditsId, 'Enter a whole number');
    });

    testWidgets('Issue 61: fewer than one credit is refused on the field', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Entered twice');
      await enterField(tester, _F.creditsId, '0');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.creditsId, 'At least 1');
    });

    testWidgets('Issue 61: more than is unspent is refused on the field, '
        'and all of it accepted', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Entered twice');
      await enterField(tester, _F.creditsId, '5');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.creditsId, 'At most 4');

      await enterField(tester, _F.creditsId, '4');
      expect(await _validate(tester, state), isNotNull);
      expect(find.text('At most 4'), findsNothing);
    });

    testWidgets('Issue 61: a blank reason is refused on the field', (
      tester,
    ) async {
      final state = await _pump(tester);

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.reasonId, 'A reason is required');
    });

    testWidgets('Issue 61: validate returns exactly the credits as a number '
        'and the reason, both trimmed', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.creditsId, ' 2 ');
      await enterField(tester, _F.reasonId, '  Entered twice ');

      final values = await _validate(tester, state);

      expect(values, {_F.creditsId: 2, _F.reasonId: 'Entered twice'});
      expect(values![_F.creditsId], isA<int>());
    });

    testWidgets('Issue 61: left as seeded, it reverses all that is unspent', (
      tester,
    ) async {
      final state = await _pump(tester, unspent: 7);
      await enterField(tester, _F.reasonId, 'Entered twice');

      expect((await _validate(tester, state))![_F.creditsId], 7);
    });

    testWidgets('Issue 61: typing in either field dirties it, and typing '
        'the old text back cleans it', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      await enterField(tester, _F.creditsId, '2');
      expect(state.isDirty, isTrue);
      await enterField(tester, _F.creditsId, '4');
      expect(state.isDirty, isFalse);

      await enterField(tester, _F.reasonId, 'x');
      expect(state.isDirty, isTrue);
      await enterField(tester, _F.reasonId, '');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: showErrors puts a message on a field and one '
        'inline', (tester) async {
      final state = await _pump(tester);

      await expectShowsServerErrors(tester, state, _F.reasonId);
    });

    testWidgets('Issue 61: after a refusal it validates and returns its '
        'values again', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Entered twice');

      expect(
        await expectSavesAfterRefusal(tester, state, _F.creditsId),
        {_F.creditsId: 4, _F.reasonId: 'Entered twice'},
      );
    });

    testWidgets('Issue 61: with enabled false no field responds', (
      tester,
    ) async {
      await _pump(tester, enabled: false);

      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone', (tester) async {
      await expectFitsPhone(tester, const CreditReverseForm(unspent: 4));
    });
  });
}
