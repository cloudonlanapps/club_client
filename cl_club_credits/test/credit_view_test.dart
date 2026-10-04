import 'package:cl_club_credits/cl_club_credits.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'support/credit_test_scope.dart';

const _member = 'view_member';

CreditEntry _entry(
  int id, {
  required int amount,
  required CreditEntryType type,
  required int totalAfter,
  required DateTime createdAtUtc,
  DateTime? occurrenceTimeUtc,
  String reason = '',
}) => CreditEntry(
  id: id,
  accountId: 'PRG00001',
  membername: _member,
  amount: amount,
  entryType: type,
  reason: reason,
  createdAtUtc: createdAtUtc,
  occurrenceTimeUtc: occurrenceTimeUtc,
  totalAfter: totalAfter,
);

final Map<String, List<CreditAccount>> _accounts = {
  _member: [
    account('PRG00001', membername: _member, balance: 8, eventId: 9),
    account(
      'OLD00001',
      membername: _member,
      balance: 3,
      state: CreditAccountState.expired,
    ),
  ],
};

final Map<String, List<CreditEntry>> _entries = {
  _member: [
    _entry(
      3,
      amount: 1,
      type: CreditEntryType.sessionRefund,
      totalAfter: 10,
      createdAtUtc: DateTime.utc(2026, 9, 20, 12),
      occurrenceTimeUtc: DateTime.utc(2026, 9, 9, 12),
    ),
    _entry(
      2,
      amount: -1,
      type: CreditEntryType.sessionDeduction,
      totalAfter: 9,
      createdAtUtc: DateTime.utc(2026, 9, 9, 12),
      occurrenceTimeUtc: DateTime.utc(2026, 9, 9, 12),
    ),
    _entry(
      1,
      amount: 10,
      type: CreditEntryType.grant,
      totalAfter: 10,
      createdAtUtc: DateTime.utc(2026, 9, 1, 12),
      reason: 'season',
    ),
  ],
};

Future<void> _pump(WidgetTester tester, UserPrivate who) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    creditScope(
      user: who,
      accounts: _accounts,
      entries: _entries,
      child: CreditView(currentUser: who, username: _member),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 101: the credit view', () {
    testWidgets('Issue 101: header shows the usable total', (tester) async {
      await _pump(tester, viewer(_member));
      // 8 usable; the expired 3 is not counted.
      expect(find.bySemanticsLabel('Credit 8'), findsOneWidget);
    });

    testWidgets('Issue 101: packages show, the expired one included', (
      tester,
    ) async {
      await _pump(tester, viewer(_member));
      expect(find.text('8'), findsWidgets);
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(LucideIcons.hourglass), findsOneWidget);
      expect(find.byIcon(LucideIcons.pin), findsOneWidget);
      expect(find.byIcon(LucideIcons.globe), findsOneWidget);
    });

    testWidgets('Issue 101: a package shows its code on tap', (tester) async {
      await _pump(tester, viewer(_member));
      expect(find.text('PRG00001'), findsNothing);
      await tester.tap(find.byIcon(LucideIcons.pin));
      await tester.pump();
      expect(find.text('PRG00001'), findsOneWidget);
    });

    testWidgets('Issue 101: the statement shows server running totals and '
        'marks a correction', (tester) async {
      await _pump(tester, viewer(_member));
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('-1'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      // Only the refund was recorded on another day than its session.
      expect(find.byIcon(LucideIcons.history), findsOneWidget);
    });

    testWidgets('Issue 101: an admin reason shows on tap only', (
      tester,
    ) async {
      await _pump(tester, viewer(_member));
      expect(find.textContaining('season'), findsNothing);
      await tester.tap(find.text('+10'));
      await tester.pump();
      expect(find.textContaining('season'), findsOneWidget);
    });

    testWidgets('Issue 101: an admin gets Add credit and package menus', (
      tester,
    ) async {
      await _pump(tester, viewer('an_admin', admin: true));
      expect(find.text('Add credit'), findsOneWidget);
      expect(find.byIcon(LucideIcons.ellipsisVertical), findsNWidgets(2));
    });

    for (final who in [
      viewer('a_coach', coach: true),
      viewer(_member),
    ]) {
      testWidgets('Issue 101: ${who.username} sees no action', (
        tester,
      ) async {
        await _pump(tester, who);
        expect(find.text('Add credit'), findsNothing);
        expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
      });
    }

    testWidgets('Issue 105: a pre-filled grant opens Add credit at once', (
      tester,
    ) async {
      final admin = viewer('an_admin', admin: true);
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        creditScope(
          user: admin,
          child: CreditView(
            currentUser: admin,
            username: _member,
            grantPrefill: (programmeId: null, trial: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.text('Trial'), findsOneWidget);
    });
  });
}
