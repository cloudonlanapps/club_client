import 'package:cl_club_credits/cl_club_credits.dart';
import 'package:cl_club_credits/src/widgets/credit_action_panel.dart';
import 'package:cl_club_forms/cl_club_forms.dart' show CreditFormFields;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'support/credit_test_scope.dart';

const _member = 'sheet_member';

/// A phone's screen, in logical pixels.
const Size _phone = Size(390, 844);

/// How much of the screen the on-screen keyboard covers.
const double _keyboard = 300;

final UserPrivate _admin = viewer('an_admin', admin: true);

Future<void> _openSheetOnPhone(WidgetTester tester) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = _phone;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    creditScope(
      user: _admin,
      accounts: {
        _member: [account('GEN00001', membername: _member, balance: 5)],
      },
      child: Builder(
        builder: (context) => ShadButton(
          onPressed: () => showCreditSheet(context, username: _member),
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// Raises the keyboard over the lower [_keyboard] pixels of the screen.
Future<void> _raiseKeyboard(WidgetTester tester) async {
  tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 165: the credit sheet makes room for the keyboard', () {
    testWidgets('Issue 165: with the keyboard up, Add credit scrolls so the '
        'reason and Save show above it', (tester) async {
      await _openSheetOnPhone(tester);
      await tester.tap(find.widgetWithText(ShadButton, 'Add credit'));
      await tester.pumpAndSettle();
      await _raiseKeyboard(tester);

      final keyboardTop = _phone.height - _keyboard;
      final panel = find.byType(CreditActionPanel);
      final reason = find.descendant(
        of: panel,
        matching: find.byWidgetPredicate(
          (w) => w is ShadInputFormField && w.id == CreditFormFields.reasonId,
        ),
      );
      final save = find.descendant(
        of: panel,
        matching: find.widgetWithText(ShadButton, 'Save'),
      );
      for (final target in [reason, save]) {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(target).bottom,
          lessThanOrEqualTo(keyboardTop),
          reason: 'scrolled into view, it must sit above the keyboard',
        );
      }
    });

    testWidgets('Issue 165: the sheet still reaches the bottom of the screen '
        'with no keyboard', (tester) async {
      await _openSheetOnPhone(tester);

      expect(
        tester.getRect(find.byType(CreditView)).bottom,
        moreOrLessEquals(_phone.height),
      );
    });
  });
}
