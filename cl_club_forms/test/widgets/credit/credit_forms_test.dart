import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/credit/credit_form_validators.dart'
    show CreditFormValidators;
import 'package:cl_club_forms/src/widgets/form/form_body.dart' show FormBody;
import 'package:cl_club_forms/src/widgets/form/labeled_form_row.dart'
    show LabeledFormRow;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<void> _pump(WidgetTester tester, Widget form) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(body: SingleChildScrollView(child: form)),
    ),
  );
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

void main() {
  group('Issue 101: CreditFormValidators', () {
    test('Issue 101: credits are whole numbers in range', () {
      expect(CreditFormValidators.credits('3'), isNull);
      expect(CreditFormValidators.credits('0'), isNotNull);
      expect(CreditFormValidators.credits('0', min: 0), isNull);
      expect(CreditFormValidators.credits('1.5'), isNotNull);
      expect(CreditFormValidators.credits('6', max: 5), isNotNull);
    });

    test('Issue 101: a reason is required', () {
      expect(CreditFormValidators.reason('  '), isNotNull);
      expect(CreditFormValidators.reason('season'), isNull);
    });

    test('Issue 101: a window ends after it starts and not in the past', () {
      final today = DateTime(2026, 9, 26);
      expect(
        CreditFormValidators.window(
          from: today,
          until: today.add(const Duration(days: 1)),
          today: today,
        ),
        isNull,
      );
      expect(
        CreditFormValidators.window(
          from: today,
          until: today.subtract(const Duration(days: 1)),
          today: today,
        ),
        isNotNull,
      );
      expect(
        CreditFormValidators.window(
          from: DateTime(2026, 9),
          until: DateTime(2026, 9, 10),
          today: today,
        ),
        isNotNull,
      );
    });
  });

  group('Issue 101: CreditGrantForm', () {
    testWidgets('Issue 101: returns typed values, pre-filled', (tester) async {
      final key = GlobalKey<CreditGrantFormState>();
      final today = DateTime.now();
      await _pump(
        tester,
        CreditGrantForm(
          key: key,
          programmes: const [CreditProgrammeOption(id: 9, title: 'Skating')],
          initialValues: CreditGrantForm.defaultValues(
            today: today,
            programmeId: 9,
            trial: true,
          ),
          today: today,
        ),
      );
      await tester.enterText(_field(CreditFormFields.creditsId), '10');
      await tester.enterText(_field(CreditFormFields.reasonId), ' season ');
      await tester.pump();

      final values = key.currentState!.validate();

      expect(values, isNotNull);
      expect(values![CreditFormFields.creditsId], 10);
      expect(values[CreditFormFields.programmeId], 9);
      expect(values[CreditFormFields.trialId], isTrue);
      expect(values[CreditFormFields.reasonId], 'season');
    });

    testWidgets('Issue 101: refuses without credits or a reason', (
      tester,
    ) async {
      final key = GlobalKey<CreditGrantFormState>();
      await _pump(
        tester,
        CreditGrantForm(
          key: key,
          programmes: const [],
          initialValues: CreditGrantForm.defaultValues(today: DateTime.now()),
        ),
      );

      expect(key.currentState!.validate(), isNull);
    });
  });

  group('Issue 101: CreditReverseForm', () {
    testWidgets('Issue 101: caps the reversal at what is unspent', (
      tester,
    ) async {
      final key = GlobalKey<CreditReverseFormState>();
      await _pump(tester, CreditReverseForm(key: key, unspent: 4));
      await tester.enterText(_field(CreditFormFields.creditsId), '5');
      await tester.enterText(_field(CreditFormFields.reasonId), 'mistake');
      await tester.pump();
      expect(key.currentState!.validate(), isNull);

      await tester.enterText(_field(CreditFormFields.creditsId), '4');
      await tester.pump();
      expect(key.currentState!.validate(), {
        CreditFormFields.creditsId: 4,
        CreditFormFields.reasonId: 'mistake',
      });
    });
  });

  group('Issue 101: CreditTransferForm', () {
    testWidgets('Issue 101: the penalty is 0..balance', (tester) async {
      final key = GlobalKey<CreditTransferFormState>();
      await _pump(
        tester,
        CreditTransferForm(key: key, balance: 8, today: DateTime.now()),
      );
      await tester.enterText(_field(CreditFormFields.reasonId), 'settle');
      await tester.enterText(_field(CreditFormFields.penaltyId), '9');
      await tester.pump();
      expect(key.currentState!.validate(), isNull);

      await tester.enterText(_field(CreditFormFields.penaltyId), '2');
      await tester.pump();
      final values = key.currentState!.validate();
      expect(values?[CreditFormFields.penaltyId], 2);
    });
  });

  group('Issue 54: the credit forms follow the form contract', () {
    final today = DateTime(2026, 9, 26);

    Widget grant({
      GlobalKey<CreditGrantFormState>? key,
      Map<String, dynamic>? initialValues,
      bool enabled = true,
    }) => CreditGrantForm(
      key: key,
      programmes: const [],
      initialValues:
          initialValues ?? CreditGrantForm.defaultValues(today: today),
      today: today,
      enabled: enabled,
    );

    testWidgets('Issue 54: every field is a labelled row, the required ones '
        'marked', (tester) async {
      await _pump(tester, grant());

      for (final label in [
        'Credits *',
        'Valid from *',
        'Valid until *',
        'Programme',
        'Reason *',
      ]) {
        expect(
          find.descendant(
            of: find.byType(LabeledFormRow),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
      expect(find.byType(FormBody), findsOneWidget);
    });

    testWidgets('Issue 54: the cap of a reversal is part of its label', (
      tester,
    ) async {
      await _pump(tester, const CreditReverseForm(unspent: 4));

      expect(find.text('Credits (max 4) *'), findsOneWidget);
    });

    testWidgets('Issue 54: a window that ends before it starts is refused '
        'inline', (tester) async {
      final key = GlobalKey<CreditGrantFormState>();
      await _pump(
        tester,
        grant(
          key: key,
          initialValues: CreditGrantForm.defaultValues(today: today)
            ..[CreditFormFields.validUntilId] = today.subtract(
              const Duration(days: 1),
            ),
        ),
      );
      await tester.enterText(_field(CreditFormFields.creditsId), '3');
      await tester.enterText(_field(CreditFormFields.reasonId), 'gift');
      await tester.pump();

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('Valid until must not be before from'), findsOneWidget);
    });

    testWidgets('Issue 54: an extension must end after the current end', (
      tester,
    ) async {
      final key = GlobalKey<CreditExtendFormState>();
      await _pump(tester, CreditExtendForm(key: key, currentValidUntil: today));
      await tester.enterText(_field(CreditFormFields.reasonId), 'late start');
      await tester.pump();

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text(CreditFormValidators.notExtendedMessage), findsOne);
    });

    testWidgets('Issue 54: a refusal of the server shows on the field it is '
        'about', (tester) async {
      final key = GlobalKey<CreditReverseFormState>();
      await _pump(tester, CreditReverseForm(key: key, unspent: 4));

      key.currentState!.showErrors(
        fieldErrors: const {
          CreditFormFields.creditsId: 'More than remains unspent.',
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('More than remains unspent.'), findsOneWidget);
    });

    testWidgets('Issue 54: enabled false turns every field off', (
      tester,
    ) async {
      await _pump(tester, grant(enabled: false));

      for (final id in [
        CreditFormFields.creditsId,
        CreditFormFields.reasonId,
      ]) {
        expect(tester.widget<ShadInputFormField>(_field(id)).enabled, isFalse);
      }
    });

    testWidgets('Issue 54: a credit form is dirty once a field changes', (
      tester,
    ) async {
      final key = GlobalKey<CreditTransferFormState>();
      await _pump(
        tester,
        CreditTransferForm(key: key, balance: 8, today: today),
      );
      expect(key.currentState!.isDirty, isFalse);

      await tester.enterText(_field(CreditFormFields.penaltyId), '2');
      await tester.pump();
      expect(key.currentState!.isDirty, isTrue);
    });
  });
}
