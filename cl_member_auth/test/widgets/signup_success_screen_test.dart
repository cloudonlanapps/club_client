import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) {
  return ShadApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('Issue 411: SignupSuccessView', () {
    testWidgets('renders the "Account created" headline', (tester) async {
      await tester.pumpWidget(_wrap(SignupSuccessView(onHome: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Account created'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Continue button calls onHome exactly once', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(SignupSuccessView(onHome: () => calls++)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ShadButton, 'Continue'));
      await tester.pump();

      expect(calls, 1);
    });
  });

  group('Issue 84: signup success follows identity verification', () {
    testWidgets('on: promises the document step', (tester) async {
      await tester.pumpWidget(
        _wrap(SignupSuccessView(onHome: () {}, identityVerification: true)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('document'), findsOneWidget);
    });

    for (final state in [false, null]) {
      testWidgets(
        '${state == null ? 'unknown' : 'off'}: mentions no document',
        (tester) async {
          await tester.pumpWidget(
            _wrap(
              SignupSuccessView(onHome: () {}, identityVerification: state),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('document'), findsNothing);
          expect(
            find.textContaining('review your application'),
            findsOneWidget,
          );
        },
      );
    }
  });
}
