// CreditGrantForm against the list of club_client#61. Every point applies:
// it has typed, picked, selected and switched fields, and one rule across
// fields (the validity window). No parameter hides a field. Its only button
// is the calendar trigger inside each date field.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<Map<String, dynamic>?> _validate(
  WidgetTester tester,
  CreditGrantFormState state,
) async {
  final values = state.validate();
  await tester.pumpAndSettle();
  return values;
}

void main() {
  group('Issue 61: CreditGrantForm.defaultValues', () {
    test('Issue 61: a fresh grant is general, not a trial, and valid for 90 '
        'days from the date of today', () {
      expect(
        CreditGrantForm.defaultValues(today: DateTime(2026, 9, 26, 17, 30)),
        {
          _F.creditsId: '',
          _F.validFromId: DateTime(2026, 9, 26),
          _F.validUntilId: DateTime(
            2026,
            9,
            26,
          ).add(CreditGrantForm.defaultValidity),
          _F.programmeId: _F.generalProgramme,
          _F.trialId: false,
          _F.reasonId: '',
        },
      );
      expect(CreditGrantForm.defaultValidity, const Duration(days: 90));
    });

    test('Issue 61: a programme and the trial flag are taken as given', () {
      final values = CreditGrantForm.defaultValues(
        today: _today,
        programmeId: 12,
        trial: true,
      );
      expect(values[_F.programmeId], 12);
      expect(values[_F.trialId], isTrue);
    });
  });

  group('Issue 61: CreditGrantForm fields', () {
    testWidgets('Issue 61: it shows its six fields, five as labelled rows '
        'with the required ones marked, and Trial as a switch', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), [
        'Credits *',
        'Valid from *',
        'Valid until *',
        'Programme',
        'Reason *',
      ]);
      expectLabelsAreRows(tester);
      expect(formOf(tester).fields.keys, {
        _F.creditsId,
        _F.validFromId,
        _F.validUntilId,
        _F.programmeId,
        _F.trialId,
        _F.reasonId,
      });
      expect(
        find.descendant(
          of: fieldWithId(_F.trialId),
          matching: find.text('Trial'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: it draws no heading and no button of its own', (
      tester,
    ) async {
      await _pump(tester);

      expectNoHostChrome(tester);
      // Nothing but the labels, the switch's label and the seeded values.
      expect(find.text(CreditGrantForm.generalLabel), findsOneWidget);
      expect(find.text('26 Sep 2026'), findsOneWidget);
      expect(find.text('25 Dec 2026'), findsOneWidget);
    });

    testWidgets('Issue 61: the programme select offers General and each '
        'programme, and returns the one picked', (tester) async {
      final state = await _pump(tester);
      await _fill(tester);

      await tester.tap(find.text(CreditGrantForm.generalLabel));
      await tester.pumpAndSettle();
      for (final title in ['Skating', 'Goalies']) {
        expect(find.text(title), findsOneWidget);
      }
      await tester.tap(find.text('Goalies').last);
      await tester.pumpAndSettle();

      expect((await _validate(tester, state))![_F.programmeId], 12);
    });

    testWidgets('Issue 61: a seeded programme that is not among the options '
        'shows as its number', (tester) async {
      final state = await _pump(
        tester,
        initialValues: CreditGrantForm.defaultValues(
          today: _today,
          programmeId: 77,
        ),
      );

      expect(find.text('#77'), findsOneWidget);
      expect(state.programmeTitle(_F.generalProgramme), 'General');
      expect(state.programmeTitle(9), 'Skating');
    });
  });

  group('Issue 61: CreditGrantForm field validation', () {
    testWidgets('Issue 61: credits that are not a whole number are refused '
        'on the field', (tester) async {
      final state = await _pump(tester);
      await _fill(tester);
      await enterField(tester, _F.creditsId, '2.5');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.creditsId, 'Enter a whole number');
    });

    testWidgets('Issue 61: fewer than one credit is refused on the field', (
      tester,
    ) async {
      final state = await _pump(tester);
      await _fill(tester);
      await enterField(tester, _F.creditsId, '0');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.creditsId, 'At least 1');
    });

    testWidgets('Issue 61: a blank reason is refused on the field', (
      tester,
    ) async {
      final state = await _pump(tester);
      await _fill(tester);
      await enterField(tester, _F.reasonId, '  ');

      expect(await _validate(tester, state), isNull);
      expectFieldError(_F.reasonId, 'A reason is required');
    });

    for (final (id, name) in [
      (_F.validFromId, 'start'),
      (_F.validUntilId, 'end'),
    ]) {
      testWidgets('Issue 61: a window without its $name is refused on that '
          'date', (tester) async {
        final state = await _pump(
          tester,
          initialValues: CreditGrantForm.defaultValues(today: _today)
            ..[id] = null,
        );
        await _fill(tester);

        expect(await _validate(tester, state), isNull);
        // The empty picker's placeholder reads the same as the message.
        expect(
          find.descendant(
            of: fieldWithId(id),
            matching: find.text('Pick a date'),
          ),
          findsNWidgets(2),
        );
        expect(find.text('Pick a date'), findsNWidgets(2));
      });
    }

    testWidgets('Issue 61: with every field valid nothing is refused', (
      tester,
    ) async {
      final state = await _pump(tester);
      await _fill(tester);

      expect(await _validate(tester, state), isNotNull);
      for (final message in [
        'Enter a whole number',
        'At least 1',
        'A reason is required',
        'Pick a date',
      ]) {
        expect(find.text(message), findsNothing);
      }
    });
  });

  group('Issue 61: CreditGrantForm rule across fields', () {
    testWidgets('Issue 61: an end picked before the start is refused inline, '
        'and accepted once it is moved to the start', (tester) async {
      final state = await _pump(tester);
      await _fill(tester);
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
      await _fill(tester);
      await pickDate(tester, _F.validFromId, DateTime(2026, 9));
      await pickDate(tester, _F.validUntilId, DateTime(2026, 9, 25));

      expect(await _validate(tester, state), isNull);
      expect(find.text('Valid until must not be in the past'), findsOneWidget);

      await pickDate(tester, _F.validUntilId, _today);
      expect(await _validate(tester, state), isNotNull);
      expect(find.text('Valid until must not be in the past'), findsNothing);
    });

    testWidgets('Issue 61: without a today the window is checked against '
        'now', (tester) async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 30);
      final state = await _pump(
        tester,
        useNow: true,
        initialValues: CreditGrantForm.defaultValues(today: start)
          ..[_F.validUntilId] = DateTime(now.year, now.month, now.day - 1),
      );
      await _fill(tester);

      expect(await _validate(tester, state), isNull);
      expect(find.text('Valid until must not be in the past'), findsOneWidget);

      await pickDate(
        tester,
        _F.validUntilId,
        DateTime(now.year, now.month, now.day),
      );
      expect(await _validate(tester, state), isNotNull);
    });

    testWidgets('Issue 61: a broken field is reported before the window', (
      tester,
    ) async {
      final state = await _pump(tester);
      await pickDate(tester, _F.validUntilId, DateTime(2026, 9, 25));

      expect(await _validate(tester, state), isNull);
      expect(find.text('Enter a whole number'), findsOneWidget);
      expect(find.text('Valid until must not be before from'), findsNothing);
    });
  });

  group('Issue 61: CreditGrantForm values', () {
    testWidgets('Issue 61: validate returns exactly the six documented '
        'values, credits as a number and the reason trimmed', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _F.creditsId, ' 10 ');
      await enterField(tester, _F.reasonId, '  Season pass ');

      final values = await _validate(tester, state);

      expect(values, {
        _F.creditsId: 10,
        _F.validFromId: DateTime(2026, 9, 26),
        _F.validUntilId: DateTime(2026, 12, 25),
        _F.programmeId: _F.generalProgramme,
        _F.trialId: false,
        _F.reasonId: 'Season pass',
      });
      expect(values![_F.creditsId], isA<int>());
      expect(values[_F.validFromId], isA<DateTime>());
      expect(values[_F.programmeId], isA<int>());
      expect(values[_F.trialId], isA<bool>());
    });

    testWidgets('Issue 61: seeded values come back unchanged', (tester) async {
      final seeded = {
        _F.creditsId: '4',
        _F.validFromId: DateTime(2026, 10),
        _F.validUntilId: DateTime(2026, 11),
        _F.programmeId: 9,
        _F.trialId: true,
        _F.reasonId: 'Trial week',
      };
      final state = await _pump(tester, initialValues: seeded);

      expect(find.text('Skating'), findsOneWidget);
      expect(state.isDirty, isFalse);
      expect(await _validate(tester, state), {...seeded, _F.creditsId: 4});
    });

    testWidgets('Issue 61: seeded without a trial flag, it returns false', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        initialValues: CreditGrantForm.defaultValues(today: _today)
          ..remove(_F.trialId),
      );
      await _fill(tester);

      expect((await _validate(tester, state))![_F.trialId], isFalse);
    });
  });
}
