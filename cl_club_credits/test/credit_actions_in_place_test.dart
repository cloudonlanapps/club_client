import 'package:cl_club_credits/cl_club_credits.dart';
import 'package:cl_club_credits/src/widgets/credit_account_row.dart';
import 'package:cl_club_credits/src/widgets/credit_action_dialog.dart';
import 'package:cl_club_credits/src/widgets/credit_action_panel.dart';
import 'package:cl_club_credits/src/widgets/credit_entry_row.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        CreditExtendForm,
        CreditFormFields,
        CreditGrantForm,
        CreditReverseForm,
        CreditTransferForm;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show CreditCountChip;

import 'support/credit_test_scope.dart';

const _member = 'view_member';
const _programmeAccount = 'PRG00001';

final Map<String, List<CreditAccount>> _accounts = {
  _member: [
    account(_programmeAccount, membername: _member, balance: 8, eventId: 9),
  ],
};

final Map<String, List<CreditEntry>> _entries = {
  _member: [
    CreditEntry(
      id: 1,
      accountId: _programmeAccount,
      membername: _member,
      amount: 8,
      entryType: CreditEntryType.grant,
      reason: 'season',
      createdAtUtc: DateTime.utc(2026, 9, 1, 12),
      totalAfter: 8,
    ),
  ],
};

final UserPrivate _admin = viewer('an_admin', admin: true);

/// The forms each package action shows, by the menu entry that opens it.
const Map<String, Type> _packageForms = {
  'Extend': CreditExtendForm,
  'Reverse': CreditReverseForm,
  'Transfer': CreditTransferForm,
};

Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpView(
  WidgetTester tester, {
  RouteStack? routes,
  StubAccounts Function()? accountsNotifier,
}) async {
  await _useTallSurface(tester);
  await tester.pumpWidget(
    creditScope(
      user: _admin,
      accounts: _accounts,
      entries: _entries,
      routes: routes,
      accountsNotifier: accountsNotifier,
      child: CreditView(currentUser: _admin, username: _member),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openPackageAction(WidgetTester tester, String action) async {
  await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ShadButton, action));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String id, String text) =>
    tester.enterText(
      find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id),
      text,
    );

void _expectStatementShown() {
  expect(find.byType(CreditAccountRow), findsOneWidget);
  expect(find.byType(CreditEntryRow), findsOneWidget);
  expect(find.byType(CreditActionPanel), findsNothing);
}

void main() {
  group('Issue 41: credit actions open inside the credit view', () {
    testWidgets('Issue 41: the view opens nothing when it mounts', (
      tester,
    ) async {
      final routes = RouteStack();
      await _pumpView(tester, routes: routes);

      expect(routes.pushed, 0);
      _expectStatementShown();
    });

    testWidgets('Issue 41: Add credit opens inside the view; no dialog is '
        'pushed over it', (tester) async {
      final routes = RouteStack();
      await _pumpView(tester, routes: routes);

      await tester.tap(find.widgetWithText(ShadButton, 'Add credit'));
      await tester.pumpAndSettle();

      expect(routes.pushed, 0);
      expect(find.byType(CreditActionDialog), findsNothing);
      final panel = find.byType(CreditActionPanel);
      expect(
        find.descendant(of: panel, matching: find.byType(CreditGrantForm)),
        findsOneWidget,
      );
      for (final label in ['Cancel', 'Save']) {
        expect(
          find.descendant(
            of: panel,
            matching: find.widgetWithText(ShadButton, label),
          ),
          findsOneWidget,
        );
      }
      // The form takes the place of the packages and the statement.
      expect(find.byType(CreditAccountRow), findsNothing);
      expect(find.byType(CreditEntryRow), findsNothing);
    });

    for (final MapEntry(key: action, value: form) in _packageForms.entries) {
      testWidgets('Issue 41: $action opens inside the view; no dialog is '
          'pushed over it', (tester) async {
        final routes = RouteStack();
        await _pumpView(tester, routes: routes);

        await _openPackageAction(tester, action);

        expect(routes.pushed, 0);
        expect(find.byType(CreditActionDialog), findsNothing);
        expect(
          find.descendant(
            of: find.byType(CreditActionPanel),
            matching: find.byType(form),
          ),
          findsOneWidget,
        );
        expect(find.byType(CreditEntryRow), findsNothing);
      });
    }

    testWidgets('Issue 41: Cancel brings the packages and the statement '
        'back', (tester) async {
      await _pumpView(tester);
      await _openPackageAction(tester, 'Extend');

      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();

      _expectStatementShown();
    });

    testWidgets('Issue 41: Save in place adds the credit and brings the '
        'statement back', (tester) async {
      late StubAccounts stub;
      await _pumpView(
        tester,
        accountsNotifier: () => stub = StubAccounts(_accounts),
      );
      await tester.tap(find.widgetWithText(ShadButton, 'Add credit'));
      await tester.pumpAndSettle();

      await _enter(tester, CreditFormFields.creditsId, '4');
      await _enter(tester, CreditFormFields.reasonId, 'top up');
      await tester.tap(find.widgetWithText(ShadButton, 'Save'));
      await tester.pumpAndSettle();

      expect(stub.opened, ['$_member 4 null false top up']);
      _expectStatementShown();
    });

    testWidgets('Issue 41: Save in place reverses the package it was opened '
        'on', (tester) async {
      late StubAccounts stub;
      await _pumpView(
        tester,
        accountsNotifier: () => stub = StubAccounts(_accounts),
      );
      await _openPackageAction(tester, 'Reverse');

      await _enter(tester, CreditFormFields.reasonId, 'mistake');
      await tester.tap(find.widgetWithText(ShadButton, 'Save'));
      await tester.pumpAndSettle();

      expect(stub.actions, ['reverse $_programmeAccount mistake']);
      _expectStatementShown();
    });

    testWidgets('Issue 41: an invalid form stays open in place', (
      tester,
    ) async {
      late StubAccounts stub;
      await _pumpView(
        tester,
        accountsNotifier: () => stub = StubAccounts(_accounts),
      );
      await _openPackageAction(tester, 'Reverse');

      await tester.tap(find.widgetWithText(ShadButton, 'Save'));
      await tester.pumpAndSettle();

      expect(stub.actions, isEmpty);
      expect(find.byType(CreditActionPanel), findsOneWidget);
    });

    testWidgets('Issue 41: opened from a chip inside a dialog, the deepest '
        'stack is that dialog and the sheet', (tester) async {
      final routes = RouteStack();
      await _useTallSurface(tester);
      await tester.pumpWidget(
        creditScope(
          user: _admin,
          accounts: _accounts,
          entries: _entries,
          routes: routes,
          child: Builder(
            builder: (context) => ShadButton(
              onPressed: () => showShadDialog<void>(
                context: context,
                builder: (context) => const ShadDialog(
                  title: Text('A picker'),
                  child: CreditChip(username: _member),
                ),
              ),
              child: const Text('Open picker'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();
      expect(routes.depth, 1);

      await tester.tap(find.byType(CreditCountChip));
      await tester.pumpAndSettle();
      expect(find.byType(CreditView), findsOneWidget);
      expect(routes.depth, 2);

      await tester.tap(find.widgetWithText(ShadButton, 'Add credit'));
      await tester.pumpAndSettle();
      expect(find.byType(CreditActionPanel), findsOneWidget);
      expect(routes.depth, 2);
      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();

      for (final action in _packageForms.keys) {
        await _openPackageAction(tester, action);
        expect(find.byType(CreditActionPanel), findsOneWidget);
        expect(routes.depth, 2, reason: '$action must not push a route');
        await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
        await tester.pumpAndSettle();
      }
      expect(routes.pushed, 2);
    });
  });
}
