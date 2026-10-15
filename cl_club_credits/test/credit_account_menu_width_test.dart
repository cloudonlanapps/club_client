import 'package:cl_club_credits/src/widgets/credit_account_menu.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show CreditAccountState;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'support/credit_test_scope.dart' show account;

const Size _tablet = Size(1024, 768);

void main() {
  testWidgets('Issue 143: the package menu is as wide as its entries', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(_tablet);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: CreditAccountMenu(
              account: account(
                'a1',
                membername: 'm1',
                balance: 3,
                eventId: 7,
                state: CreditAccountState.expired,
              ),
              onExtend: () {},
              onReverse: () {},
              onTransfer: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ShadIconButton));
    await tester.pumpAndSettle();

    final entries = [
      for (final label in ['Extend', 'Reverse', 'Transfer'])
        tester.getRect(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(ShadButton),
          ),
        ),
    ];
    for (final entry in entries) {
      expect(entry.width, lessThan(_tablet.width / 2));
      expect(entry.width, entries.first.width);
    }
  });
}
