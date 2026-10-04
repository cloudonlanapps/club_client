import 'package:cl_club_credits/cl_club_credits.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show CreditCountChip;

import 'support/credit_test_scope.dart';

const _member = 'chip_member';

void main() {
  group('Issue 102: CreditChip follows the credit capability', () {
    for (final state in [false, null]) {
      testWidgets('Issue 102: renders nothing when credit is $state', (
        tester,
      ) async {
        await tester.pumpWidget(
          creditScope(
            creditSystem: state,
            user: viewer(_member),
            child: const CreditChip(username: _member),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CreditCountChip), findsNothing);
      });
    }

    testWidgets('Issue 102: shows the usable total when credit is on', (
      tester,
    ) async {
      await tester.pumpWidget(
        creditScope(
          user: viewer(_member),
          accounts: {
            _member: [
              account('GEN00001', membername: _member, balance: 5),
              account('PRG00001', membername: _member, balance: 7, eventId: 9),
            ],
          },
          child: const CreditChip(username: _member),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Credit 12'), findsOneWidget);
    });

    testWidgets('Issue 102: a given number replaces the total', (
      tester,
    ) async {
      await tester.pumpWidget(
        creditScope(
          user: viewer(_member),
          child: const CreditChip(username: _member, credits: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Credit 0'), findsOneWidget);
    });

    testWidgets('Issue 102: tapping opens the member credit view', (
      tester,
    ) async {
      await tester.pumpWidget(
        creditScope(
          user: viewer(_member),
          accounts: {
            _member: [account('GEN00001', membername: _member, balance: 5)],
          },
          child: const CreditChip(username: _member),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CreditCountChip));
      await tester.pumpAndSettle();

      expect(find.byType(CreditView), findsOneWidget);
    });
  });
}
