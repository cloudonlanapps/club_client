// The three field widgets the credit forms share, each mounted alone under a
// bare ShadForm. They hold no rule across fields; the forms' own tests cover
// those.
import 'package:cl_calendar/cl_calendar.dart'
    show CLDatePicker, CLDatePickerFormField;
import 'package:cl_club_forms/cl_club_forms.dart' show CreditFormFields;
import 'package:cl_club_forms/src/widgets/credit/credit_date_field.dart';
import 'package:cl_club_forms/src/widgets/credit/credit_number_field.dart';
import 'package:cl_club_forms/src/widgets/credit/credit_reason_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';

const _id = 'amount';

Future<ShadFormState> _pump(
  WidgetTester tester,
  Widget field, {
  Map<String, dynamic> initialValue = const {},
}) async {
  final key = GlobalKey<ShadFormState>();
  await pumpForm(
    tester,
    ClusterHost(
      formKey: key,
      initialValue: initialValue,
      builder: (_) => field,
    ),
  );
  return key.currentState!;
}

Future<bool> _validate(WidgetTester tester, ShadFormState form) async {
  final valid = form.saveAndValidate();
  await tester.pumpAndSettle();
  return valid;
}

void main() {
  group('Issue 61: CreditNumberField', () {
    testWidgets('Issue 61: it is a required row under its label, with a '
        'number keyboard', (tester) async {
      await _pump(tester, const CreditNumberField(id: _id, label: 'Credits'));

      expect(rowLabels(tester), ['Credits *']);
      expectLabelsAreRows(tester);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
        TextInputType.number,
      );
    });

    testWidgets('Issue 61: a cap is added to the label', (tester) async {
      await _pump(
        tester,
        const CreditNumberField(id: _id, label: 'Penalty', max: 8),
      );

      expect(rowLabels(tester), ['Penalty (max 8) *']);
    });

    testWidgets(
      'Issue 61: it shows the initial value of the form and registers '
      'under its id',
      (tester) async {
        final form = await _pump(
          tester,
          const CreditNumberField(id: _id, label: 'Credits'),
          initialValue: const {_id: '7'},
        );

        expect(find.text('7'), findsOneWidget);
        expect(form.fields.keys, [_id]);
        expect(form.value, {_id: '7'});
      },
    );

    testWidgets('Issue 61: text that is not a whole number is refused on '
        'the field', (tester) async {
      final form = await _pump(
        tester,
        const CreditNumberField(id: _id, label: 'Credits'),
      );

      await enterField(tester, _id, 'ten');

      expect(await _validate(tester, form), isFalse);
      expectFieldError(_id, 'Enter a whole number');
    });

    testWidgets('Issue 61: it refuses below its minimum and above its cap, '
        'and accepts both ends', (tester) async {
      final form = await _pump(
        tester,
        const CreditNumberField(id: _id, label: 'Penalty', min: 2, max: 5),
      );

      await enterField(tester, _id, '1');
      expect(await _validate(tester, form), isFalse);
      expectFieldError(_id, 'At least 2');

      await enterField(tester, _id, '6');
      expect(await _validate(tester, form), isFalse);
      expectFieldError(_id, 'At most 5');

      for (final end in ['2', '5']) {
        await enterField(tester, _id, end);
        expect(await _validate(tester, form), isTrue, reason: end);
      }
    });

    testWidgets('Issue 61: enabled false leaves it unresponsive', (
      tester,
    ) async {
      await _pump(
        tester,
        const CreditNumberField(id: _id, label: 'Credits', enabled: false),
        initialValue: const {_id: '3'},
      );

      await expectNoFieldResponds(tester);
    });
  });

  group('Issue 61: CreditDateField', () {
    final day = DateTime(2026, 9, 26);

    testWidgets('Issue 61: it is a required row under its label, showing '
        'the date the form holds', (tester) async {
      final form = await _pump(
        tester,
        const CreditDateField(id: _id, label: 'Valid until'),
        initialValue: {_id: day},
      );

      expect(rowLabels(tester), ['Valid until *']);
      expectLabelsAreRows(tester);
      expect(find.byType(CLDatePickerFormField), findsOneWidget);
      expect(find.text('26 Sep 2026'), findsOneWidget);
      expect(form.value, {_id: day});
    });

    testWidgets('Issue 61: without a date it is refused on the field, and '
        'accepted once one is picked', (tester) async {
      final form = await _pump(
        tester,
        const CreditDateField(id: _id, label: 'Valid until'),
      );
      // The empty picker's placeholder reads the same as the message.
      final message = find.descendant(
        of: fieldWithId(_id),
        matching: find.text('Pick a date'),
      );
      expect(message, findsOneWidget);

      expect(await _validate(tester, form), isFalse);
      expect(message, findsNWidgets(2));

      tester
          .widget<CLDatePicker>(find.byType(CLDatePicker))
          .onDateSelected(day);
      await tester.pumpAndSettle();
      expect(await _validate(tester, form), isTrue);
      expect(find.text('Pick a date'), findsNothing);
      expect(form.value, {_id: day});
    });

    testWidgets('Issue 61: enabled false takes the calendar away and '
        'leaves the date as it was', (tester) async {
      final form = await _pump(
        tester,
        const CreditDateField(id: _id, label: 'Valid until', enabled: false),
        initialValue: {_id: day},
      );

      expect(find.byType(CLDatePicker), findsNothing);
      await expectNoFieldResponds(tester);
      expect(form.value, {_id: day});
    });
  });

  group('Issue 61: CreditReasonField', () {
    testWidgets('Issue 61: it is the required Reason row, registered under '
        'the shared reason id', (tester) async {
      final form = await _pump(tester, const CreditReasonField());

      expect(rowLabels(tester), ['${CreditReasonField.label} *']);
      expect(CreditReasonField.label, 'Reason');
      expectLabelsAreRows(tester);
      expect(form.fields.keys, [CreditFormFields.reasonId]);
    });

    testWidgets('Issue 61: a blank reason is refused on the field, a '
        'written one accepted', (tester) async {
      final form = await _pump(tester, const CreditReasonField());

      await enterField(tester, CreditFormFields.reasonId, '   ');
      expect(await _validate(tester, form), isFalse);
      expectFieldError(CreditFormFields.reasonId, 'A reason is required');

      await enterField(tester, CreditFormFields.reasonId, 'Season pass');
      expect(await _validate(tester, form), isTrue);
      expect(form.value[CreditFormFields.reasonId], 'Season pass');
    });

    testWidgets('Issue 61: enabled false leaves it unresponsive', (
      tester,
    ) async {
      await _pump(tester, const CreditReasonField(enabled: false));

      await expectNoFieldResponds(tester);
    });
  });
}
