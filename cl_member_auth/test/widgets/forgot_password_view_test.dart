import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) => ProviderScope(
  child: ShadApp(
    home: ShadToaster(child: Scaffold(body: child)),
  ),
);

Finder _emailField() =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == 'email');

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets(
    'Issue 746: shows speculative confirmation after a successful request',
    (tester) async {
      await _setSurface(tester);
      String? requested;
      await tester.pumpWidget(
        _wrap(
          ForgotPasswordView(
            onNavigateToLogin: () {},
            onResetPassword: (email) async => requested = email,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(_emailField(), 'member@example.com');
      await tester.tap(find.widgetWithText(ShadButton, 'Send reset email'));
      await tester.pumpAndSettle();

      // The request was forwarded verbatim...
      expect(requested, 'member@example.com');
      // ...and the view swaps to the speculative confirmation that never
      // confirms the email exists.
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.textContaining('If your email is in our member list'),
        findsOneWidget,
      );
      expect(find.textContaining('24 hours'), findsOneWidget);
      // The form is gone.
      expect(_emailField(), findsNothing);
    },
  );

  testWidgets(
    'Issue 746: stays on the form and surfaces an error on failure',
    (tester) async {
      await _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          ForgotPasswordView(
            onNavigateToLogin: () {},
            onResetPassword: (_) async => throw Exception('network down'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(_emailField(), 'member@example.com');
      await tester.tap(find.widgetWithText(ShadButton, 'Send reset email'));
      await tester.pumpAndSettle();

      // No confirmation; the form remains for a retry.
      expect(find.text('Check your email'), findsNothing);
      expect(_emailField(), findsOneWidget);
      expect(
        find.textContaining('Could not send the reset email'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Issue 746: confirmation Back to sign in navigates to login', (
    tester,
  ) async {
    await _setSurface(tester);
    var navigatedToLogin = 0;
    await tester.pumpWidget(
      _wrap(
        ForgotPasswordView(
          onNavigateToLogin: () => navigatedToLogin++,
          onResetPassword: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_emailField(), 'member@example.com');
    await tester.tap(find.widgetWithText(ShadButton, 'Send reset email'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ShadButton, 'Back to sign in'));
    await tester.pumpAndSettle();

    expect(navigatedToLogin, 1);
  });
}
