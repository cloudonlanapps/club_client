import 'package:cl_club_credits/cl_club_credits.dart';
import 'package:cl_club_credits/src/widgets/credit_action_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show CreditCountChip, CreditFormFields, CreditGrantForm;

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

  group('Issue 41: the "+" chip opens Add credit alone', () {
    const programme = 9;

    Future<RouteStack> pumpAddChip(
      WidgetTester tester, {
      required bool trial,
      StubAccounts Function()? accountsNotifier,
    }) async {
      final routes = RouteStack();
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        creditScope(
          user: viewer('an_admin', admin: true),
          routes: routes,
          accountsNotifier: accountsNotifier,
          child: CreditChip.add(
            username: _member,
            grantPrefill: (programmeId: programme, trial: trial),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CreditCountChip));
      await tester.pumpAndSettle();
      return routes;
    }

    for (final trial in [false, true]) {
      testWidgets('Issue 41: Add credit opens in a dialog with no sheet '
          'behind it, pre-filled (trial: $trial)', (tester) async {
        final routes = await pumpAddChip(tester, trial: trial);

        expect(routes.depth, 1);
        expect(find.byType(CreditView), findsNothing);
        expect(find.byType(ShadSheet), findsNothing);
        expect(find.byType(CreditActionDialog), findsOneWidget);
        final values = tester
            .widget<CreditGrantForm>(find.byType(CreditGrantForm))
            .initialValues;
        expect(values[CreditFormFields.programmeId], programme);
        expect(values[CreditFormFields.trialId], trial);
      });
    }

    testWidgets('Issue 41: Save adds the pre-filled credit and closes the '
        'dialog', (tester) async {
      late StubAccounts stub;
      final routes = await pumpAddChip(
        tester,
        trial: true,
        accountsNotifier: () => stub = StubAccounts(const {}),
      );

      Future<void> enter(String id, String text) => tester.enterText(
        find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id),
        text,
      );
      await enter(CreditFormFields.creditsId, '2');
      await enter(CreditFormFields.reasonId, 'trial');
      await tester.tap(find.widgetWithText(ShadButton, 'Save'));
      await tester.pumpAndSettle();

      expect(stub.opened, ['$_member 2 $programme true trial']);
      expect(routes.depth, 0);
      expect(find.byType(CreditActionDialog), findsNothing);
    });

    testWidgets('Issue 41: a chip that shows a number opens the credit '
        'sheet', (tester) async {
      final routes = RouteStack();
      await tester.pumpWidget(
        creditScope(
          user: viewer(_member),
          routes: routes,
          child: const CreditChip(username: _member, credits: 3),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CreditCountChip));
      await tester.pumpAndSettle();

      expect(routes.depth, 1);
      expect(find.byType(ShadSheet), findsOneWidget);
      expect(find.byType(CreditView), findsOneWidget);
      expect(find.byType(CreditActionDialog), findsNothing);
    });
  });
}
