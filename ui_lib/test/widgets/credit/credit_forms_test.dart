import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

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
        ),
      );
      await tester.enterText(_field(CreditFormFields.creditsId), '10');
      await tester.enterText(_field(CreditFormFields.reasonId), ' season ');
      await tester.pump();

      final values = key.currentState!.validate(today: today);

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
}
