// CreditExtendForm against the list of club_client#61. Every point applies:
// a picked date, a typed reason, and one rule across fields (the new end is
// after the current one, which the form is seeded with). No parameter hides
// a field. Its only button is the calendar trigger inside the date field.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/credit/credit_form_validators.dart'
    show CreditFormValidators;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';

typedef _F = CreditFormFields;

final _end = DateTime(2026, 9, 26);
final _later = DateTime(2026, 9, 27);

Future<CreditExtendFormState> _pump(
  WidgetTester tester, {
  bool enabled = true,
}) async {
  final key = GlobalKey<CreditExtendFormState>();
  await pumpForm(
    tester,
    CreditExtendForm(key: key, currentValidUntil: _end, enabled: enabled),
  );
  return key.currentState!;
}

Future<Map<String, dynamic>?> _validate(
  WidgetTester tester,
  CreditExtendFormState state,
) async {
  final values = state.validate();
  await tester.pumpAndSettle();
  return values;
}

void main() {
  group('Issue 61: CreditExtendForm', () {
    testWidgets('Issue 61: it shows its two fields as required labelled '
        'rows, the date seeded with the current end', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), ['Valid until *', 'Reason *']);
      expectLabelsAreRows(tester);
      expect(formOf(tester).fields.keys, {_F.validUntilId, _F.reasonId});
      expect(find.text('26 Sep 2026'), findsOneWidget);
    });

    testWidgets('Issue 61: it draws no heading and no button of its own', (
      tester,
    ) async {
      await _pump(tester);

      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: a blank reason is refused on the field', (
      tester,
    ) async {
      final state = await _pump(tester);
      await pickDate(tester, _F.validUntilId, _later);
      await enterField(tester, _F.reasonId, '   ');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.reasonId, 'A reason is required');
      expect(find.text(CreditFormValidators.notExtendedMessage), findsNothing);
    });

    testWidgets('Issue 61: the current end left as it is refused inline', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Rink closed');

      expect(await _validate(tester, state), isNull);
      expect(find.text(CreditFormValidators.notExtendedMessage), findsOne);
    });

    testWidgets('Issue 61: an end before the current one is refused inline', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Rink closed');
      await pickDate(tester, _F.validUntilId, DateTime(2026, 9, 25));

      expect(await _validate(tester, state), isNull);
      expect(find.text(CreditFormValidators.notExtendedMessage), findsOne);
    });

    testWidgets('Issue 61: the day after the current end is accepted, and '
        'takes the inline message away', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.reasonId, 'Rink closed');
      expect(await _validate(tester, state), isNull);

      await pickDate(tester, _F.validUntilId, _later);

      expect(await _validate(tester, state), isNotNull);
      expect(find.text(CreditFormValidators.notExtendedMessage), findsNothing);
    });

    testWidgets('Issue 61: validate returns exactly the new end and the '
        'reason, trimmed', (tester) async {
      final state = await _pump(tester);
      await pickDate(tester, _F.validUntilId, _later);
      await enterField(tester, _F.reasonId, '  Rink closed ');

      final values = await _validate(tester, state);

      expect(values, {_F.validUntilId: _later, _F.reasonId: 'Rink closed'});
      expect(values![_F.validUntilId], isA<DateTime>());
      expect(values[_F.reasonId], isA<String>());
    });

    testWidgets('Issue 61: picking a date dirties it, and picking the '
        'current end back cleans it', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      await pickDate(tester, _F.validUntilId, _later);
      expect(state.isDirty, isTrue);

      await pickDate(tester, _F.validUntilId, _end);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: typing a reason dirties it, and emptying it '
        'cleans it', (tester) async {
      final state = await _pump(tester);

      await enterField(tester, _F.reasonId, 'Rink closed');
      expect(state.isDirty, isTrue);

      await enterField(tester, _F.reasonId, '');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: showErrors puts a message on a field and one '
        'inline', (tester) async {
      final state = await _pump(tester);

      await expectShowsServerErrors(tester, state, _F.validUntilId);
    });

    testWidgets('Issue 61: after a refusal it validates and returns its '
        'values again', (tester) async {
      final state = await _pump(tester);
      await pickDate(tester, _F.validUntilId, _later);
      await enterField(tester, _F.reasonId, 'Rink closed');

      expect(
        await expectSavesAfterRefusal(tester, state, _F.reasonId),
        {_F.validUntilId: _later, _F.reasonId: 'Rink closed'},
      );
    });

    testWidgets('Issue 61: with enabled false no field responds', (
      tester,
    ) async {
      await _pump(tester, enabled: false);

      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone', (tester) async {
      await expectFitsPhone(tester, CreditExtendForm(currentValidUntil: _end));
    });
  });
}
