// CreditTransferForm against the list of club_client#61. Every point
// applies: a typed penalty and reason, two picked dates, and one rule across
// fields (the new account's validity window). No parameter hides a field.
// Its only buttons are the calendar triggers inside the date fields.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';

typedef _F = CreditFormFields;

final _today = DateTime(2026, 9, 26, 14, 30);
final _from = DateTime(2026, 9, 26);
final _until = DateTime(2026, 12, 25);

Future<CreditTransferFormState> _pump(
  WidgetTester tester, {
  int balance = 8,
  bool enabled = true,
}) async {
  final key = GlobalKey<CreditTransferFormState>();
  await pumpForm(
    tester,
    CreditTransferForm(
      key: key,
      balance: balance,
      today: _today,
      enabled: enabled,
    ),
  );
  return key.currentState!;
}

Future<Map<String, dynamic>?> _validate(
  WidgetTester tester,
  CreditTransferFormState state,
) async {
  final values = state.validate();
  await tester.pumpAndSettle();
  return values;
}

void main() {
  group('Issue 61: CreditTransferForm fields', () {
    testWidgets('Issue 61: it shows its four fields as required labelled '
        'rows, the penalty capped at the balance', (tester) async {
      await _pump(tester, balance: 5);

      expect(rowLabels(tester), [
        'Penalty (max 5) *',
        'Valid from *',
        'Valid until *',
        'Reason *',
      ]);
      expectLabelsAreRows(tester);
      expect(formOf(tester).fields.keys, {
        _F.penaltyId,
        _F.validFromId,
        _F.validUntilId,
        _F.reasonId,
      });
    });

    testWidgets('Issue 61: it starts with no penalty and a window of 90 '
        'days from the date of today', (tester) async {
      await _pump(tester);

      expect(formOf(tester).value, {
        _F.penaltyId: '0',
        _F.validFromId: _from,
        _F.validUntilId: _until,
        _F.reasonId: '',
      });
      expect(find.text('26 Sep 2026'), findsOneWidget);
      expect(find.text('25 Dec 2026'), findsOneWidget);
    });

    testWidgets('Issue 61: it draws no heading and no button of its own', (
      tester,
    ) async {
      await _pump(tester);

      expectNoHostChrome(tester);
    });
  });

  group('Issue 61: CreditTransferForm field validation', () {
    testWidgets('Issue 61: a penalty that is not a whole number is refused '
        'on the field', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Programme ended');
      await enterField(tester, _F.penaltyId, 'half');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.penaltyId, 'Enter a whole number');
    });

    testWidgets('Issue 61: a penalty below zero is refused on the field', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Programme ended');
      await enterField(tester, _F.penaltyId, '-1');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.penaltyId, 'At least 0');
    });

    testWidgets('Issue 61: a penalty above the balance is refused on the '
        'field, and the whole balance accepted', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Programme ended');
      await enterField(tester, _F.penaltyId, '9');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.penaltyId, 'At most 8');

      await enterField(tester, _F.penaltyId, '8');
      expect((await _validate(tester, state))![_F.penaltyId], 8);
    });

    testWidgets('Issue 61: a blank reason is refused on the field', (
      tester,
    ) async {
      final state = await _pump(tester);

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.reasonId, 'A reason is required');
    });
  });

  group('Issue 61: CreditTransferForm rule across fields', () {
    testWidgets('Issue 61: an end picked before the start is refused inline, '
        'and accepted once it is moved to the start', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Programme ended');
      await pickDate(tester, _F.validFromId, DateTime(2026, 10, 10));
      await pickDate(tester, _F.validUntilId, DateTime(2026, 10, 9));

      expect(await _validate(tester, state), isNull);
      expect(find.text('Valid until must not be before from'), findsOneWidget);

      await pickDate(tester, _F.validUntilId, DateTime(2026, 10, 10));
      expect(await _validate(tester, state), isNotNull);
      expect(find.text('Valid until must not be before from'), findsNothing);
    });

    testWidgets('Issue 61: a window that ended before today is refused '
        'inline, and one ending today passes', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Programme ended');
      await pickDate(tester, _F.validFromId, DateTime(2026, 9));
      await pickDate(tester, _F.validUntilId, DateTime(2026, 9, 25));

      expect(await _validate(tester, state), isNull);
      expect(find.text('Valid until must not be in the past'), findsOneWidget);

      await pickDate(tester, _F.validUntilId, _from);
      expect(await _validate(tester, state), isNotNull);
      expect(find.text('Valid until must not be in the past'), findsNothing);
    });
  });

  group('Issue 61: CreditTransferForm values and dirty check', () {
    testWidgets('Issue 61: validate returns exactly the four documented '
        'values, the penalty as a number and the reason trimmed', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _F.penaltyId, ' 2 ');
      await enterField(tester, _F.reasonId, '  Programme ended ');

      final values = await _validate(tester, state);

      expect(values, {
        _F.penaltyId: 2,
        _F.validFromId: _from,
        _F.validUntilId: _until,
        _F.reasonId: 'Programme ended',
      });
      expect(values![_F.penaltyId], isA<int>());
      expect(values[_F.validUntilId], isA<DateTime>());
    });

    testWidgets('Issue 61: left as seeded, it transfers without a penalty', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Programme ended');

      expect(
        (await _validate(tester, state))![_F.penaltyId],
        CreditFormFields.noPenalty,
      );
    });

    testWidgets('Issue 61: typing dirties it, and typing the old text back '
        'cleans it', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      await enterField(tester, _F.penaltyId, '2');
      expect(state.isDirty, isTrue);

      await enterField(tester, _F.penaltyId, '0');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: picking a date dirties it, and picking the old '
        'date back cleans it', (tester) async {
      final state = await _pump(tester);

      await pickDate(tester, _F.validFromId, DateTime(2026, 10));
      expect(state.isDirty, isTrue);

      await pickDate(tester, _F.validFromId, _from);
      expect(state.isDirty, isFalse);
    });
  });

  group('Issue 61: CreditTransferForm and its host', () {
    testWidgets('Issue 61: showErrors puts a message on a field and one '
        'inline', (tester) async {
      final state = await _pump(tester);

      await expectShowsServerErrors(tester, state, _F.penaltyId);
    });

    testWidgets('Issue 61: after a refusal it validates and returns its '
        'values again', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Programme ended');

      final values = await expectSavesAfterRefusal(
        tester,
        state,
        _F.validFromId,
      );
      expect(values[_F.reasonId], 'Programme ended');
    });

    testWidgets('Issue 61: with enabled false no field responds', (
      tester,
    ) async {
      await _pump(tester, enabled: false);

      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone', (tester) async {
      await expectFitsPhone(
        tester,
        CreditTransferForm(balance: 8, today: _today),
      );
    });
  });
}
