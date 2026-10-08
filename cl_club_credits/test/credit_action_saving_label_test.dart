// Issue 108: while a credit action is in flight its Save button is off and
// reads "Saving…".
import 'dart:async';

import 'package:cl_club_credits/src/models/credit_action_kind.dart';
import 'package:cl_club_credits/src/widgets/credit_action_dialog.dart';
import 'package:cl_club_credits/src/widgets/credit_action_form.dart';
import 'package:cl_club_credits/src/widgets/credit_action_panel.dart';
import 'package:cl_club_forms/cl_club_forms.dart' show CreditFormFields;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'support/credit_test_scope.dart';

const _member = 'view_member';
const _accountId = 'PRG00001';

final CreditAccount _account = account(
  _accountId,
  membername: _member,
  balance: 8,
  eventId: 9,
);

final UserPrivate _admin = viewer('an_admin', admin: true);

/// Accounts whose every action waits on [held] before it answers.
class _HeldAccounts extends StubAccounts {
  _HeldAccounts(this.held) : super({});

  final Completer<void> held;

  @override
  Future<CreditAccount> openAccount({
    required int credits,
    required DateTime validFromUtc,
    required DateTime validUntilUtc,
    required String reason,
    int? eventId,
    bool isTrial = false,
  }) async {
    await held.future;
    return account('NEW00001', membername: username, balance: credits);
  }

  @override
  Future<CreditAccount> extendValidity(
    String accountId, {
    required DateTime validUntilUtc,
    required String reason,
  }) async {
    await held.future;
    return account(accountId, membername: username, balance: 1);
  }

  @override
  Future<CreditAccount> reverseGrant(
    String accountId, {
    required int credits,
    required String reason,
  }) async {
    await held.future;
    return account(accountId, membername: username, balance: 0);
  }

  @override
  Future<CreditTransferResult> transfer(
    String accountId, {
    required int penalty,
    required DateTime validFromUtc,
    required DateTime validUntilUtc,
    required String reason,
  }) async {
    await held.future;
    return CreditTransferResult(
      source: account(accountId, membername: username, balance: 0),
    );
  }
}

Future<void> _enter(WidgetTester tester, String id, String text) =>
    tester.enterText(
      find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id),
      text,
    );

/// Fills what [kind]'s form needs beyond what it opens with.
Future<void> _fill(WidgetTester tester, CreditActionKind kind) async {
  if (kind == CreditActionKind.grant) {
    await _enter(tester, CreditFormFields.creditsId, '4');
  }
  if (kind == CreditActionKind.extend) {
    tester
        .state<ShadFormState>(find.byType(ShadForm))
        .setFieldValue<DateTime?>(
          CreditFormFields.validUntilId,
          DateUtils.dateOnly(
            _account.validUntilUtc.toLocal(),
          ).add(const Duration(days: 30)),
        );
  }
  await _enter(tester, CreditFormFields.reasonId, 'a reason');
  await tester.pump();
}

ShadButton _button(WidgetTester tester, String label) =>
    tester.widget<ShadButton>(find.widgetWithText(ShadButton, label));

void main() {
  group('Issue 108: a credit action in flight', () {
    for (final kind in CreditActionKind.values) {
      testWidgets('Issue 108: ${kind.title} in place reads "Saving…" on a '
          'Save that is off, and "Save" before', (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final held = Completer<void>();
        var closed = 0;
        await tester.pumpWidget(
          creditScope(
            user: _admin,
            accountsNotifier: () => _HeldAccounts(held),
            child: CreditActionForm.inPlace(
              kind: kind,
              username: _member,
              account: kind == CreditActionKind.grant ? null : _account,
              onClose: () => closed++,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CreditActionPanel), findsOneWidget);
        expect(_button(tester, 'Save').onPressed, isNotNull);
        expect(find.text('Saving…'), findsNothing);

        await _fill(tester, kind);
        await tester.tap(find.widgetWithText(ShadButton, 'Save'));
        await tester.pump();

        expect(find.text('Save'), findsNothing);
        expect(_button(tester, 'Saving…').onPressed, isNull);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(closed, 0);

        held.complete();
        await tester.pumpAndSettle();
        expect(closed, 1);
      });
    }

    testWidgets('Issue 108: Add credit in a dialog reads "Saving…" on a '
        'Save that is off', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final held = Completer<void>();
      await tester.pumpWidget(
        creditScope(
          user: _admin,
          accountsNotifier: () => _HeldAccounts(held),
          child: Builder(
            builder: (context) => ShadButton(
              onPressed: () => showShadDialog<bool>(
                context: context,
                builder: (_) => const CreditActionForm.dialog(
                  kind: CreditActionKind.grant,
                  username: _member,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(CreditActionDialog), findsOneWidget);
      expect(_button(tester, 'Save').onPressed, isNotNull);

      await _fill(tester, CreditActionKind.grant);
      await tester.tap(find.widgetWithText(ShadButton, 'Save'));
      await tester.pump();

      expect(find.text('Save'), findsNothing);
      expect(_button(tester, 'Saving…').onPressed, isNull);

      held.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CreditActionDialog), findsNothing);
    });
  });
}
