// CreditGrantForm against the list of club_client#61, continued from
// credit_grant_form_test.dart: the dirty check, what the server refused,
// enabled false and the phone width.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';

typedef _F = CreditFormFields;

final _today = DateTime(2026, 9, 26);
const _programmes = [
  CreditProgrammeOption(id: 9, title: 'Skating'),
  CreditProgrammeOption(id: 12, title: 'Goalies'),
];

Widget _form({
  Key? key,
  Map<String, dynamic>? initialValues,
  DateTime? today,
  bool useNow = false,
  bool enabled = true,
}) => CreditGrantForm(
  key: key,
  programmes: _programmes,
  initialValues: initialValues ?? CreditGrantForm.defaultValues(today: _today),
  today: useNow ? null : today ?? _today,
  enabled: enabled,
);

Future<CreditGrantFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
  bool useNow = false,
  bool enabled = true,
}) async {
  final key = GlobalKey<CreditGrantFormState>();
  await pumpForm(
    tester,
    _form(
      key: key,
      initialValues: initialValues,
      useNow: useNow,
      enabled: enabled,
    ),
  );
  return key.currentState!;
}

/// Fills the two fields a fresh grant leaves empty.
Future<void> _fill(WidgetTester tester) async {
  await enterField(tester, _F.creditsId, '10');
  await enterField(tester, _F.reasonId, 'Season pass');
}

void main() {
  group('Issue 61: CreditGrantForm dirty check', () {
    testWidgets('Issue 61: typing dirties it, and typing the old text back '
        'cleans it', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      await enterField(tester, _F.reasonId, 'Gift');
      expect(state.isDirty, isTrue);

      await enterField(tester, _F.reasonId, '');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: picking a date dirties it, and picking the old '
        'date back cleans it', (tester) async {
      final state = await _pump(tester);

      await pickDate(tester, _F.validUntilId, DateTime(2027));
      expect(state.isDirty, isTrue);

      await pickDate(tester, _F.validUntilId, DateTime(2026, 12, 25));
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: choosing a programme dirties it, and choosing '
        'General back cleans it', (tester) async {
      final state = await _pump(tester);

      await pickOption(tester, from: 'General', to: 'Skating');
      expect(state.isDirty, isTrue);

      await pickOption(tester, from: 'Skating', to: 'General');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the Trial switch dirties it, and switching back '
        'cleans it', (tester) async {
      final state = await _pump(tester);

      await tester.tap(find.byType(ShadSwitch));
      await tester.pumpAndSettle();
      expect(state.isDirty, isTrue);
      expect(formOf(tester).value[_F.trialId], isTrue);

      await tester.tap(find.byType(ShadSwitch));
      await tester.pumpAndSettle();
      expect(state.isDirty, isFalse);
    });
  });

  group('Issue 61: CreditGrantForm and its host', () {
    testWidgets('Issue 61: showErrors puts a message on a field and one '
        'inline', (tester) async {
      final state = await _pump(tester);

      await expectShowsServerErrors(tester, state, _F.creditsId);
    });

    testWidgets('Issue 61: after a refusal it validates and returns its '
        'values again', (tester) async {
      final state = await _pump(tester);
      await _fill(tester);

      final values = await expectSavesAfterRefusal(
        tester,
        state,
        _F.validUntilId,
      );
      expect(values[_F.creditsId], 10);
    });

    testWidgets('Issue 61: with enabled false no field responds', (
      tester,
    ) async {
      await _pump(tester, enabled: false);

      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone', (tester) async {
      await expectFitsPhone(tester, _form());
    });
  });
}
