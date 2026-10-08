import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart' show LoginFormFields;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_auth/src/widgets/login_view.dart' show LoginViewState;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Signed out, and stays so.
class _SignedOut extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => null;
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

/// The test font is wider than any real one, so the sign-up link row
/// overflows its 420-pixel column here. That is layout noise, not what these
/// tests assert; every other error still fails the test.
void _ignoreOverflow() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

void main() {
  testWidgets('Issue 53: LoginView owns the heading, the links and Sign in, '
      'which validates the form before signing in', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _ignoreOverflow();
    final logins = <(String, String)>[];
    var forgot = 0;
    var signUp = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStateProvider.overrideWith(_SignedOut.new)],
        child: ShadApp(
          home: ShadToaster(
            child: Scaffold(
              body: LoginView(
                onLoginSuccess: () {},
                onNavigateToForgotPassword: () => forgot++,
                onNavigateToSignup: () => signUp++,
                onLogin: (username, password) async =>
                    logins.add((username, password)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Heading and action share the text.
    expect(find.text('Sign in'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(ShadButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(logins, isEmpty);
    expect(find.text('Username is required'), findsOneWidget);

    await tester.enterText(_field(LoginFormFields.usernameId), ' asha ');
    await tester.enterText(_field(LoginFormFields.passwordId), 'secret');
    await tester.tap(find.widgetWithText(ShadButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(logins, [('asha', 'secret')]);

    // Invoked, not tapped: in the wide test font the sign-up link sits
    // past the column's edge.
    for (final label in ['Forgot password?', 'Sign up']) {
      tester
          .widget<ShadButton>(find.widgetWithText(ShadButton, label))
          .onPressed!();
    }
    expect((forgot, signUp), (1, 1));
  });

  testWidgets('Issue 103: Enter in the password field signs in, once, and '
      'does nothing while a sign-in is in flight', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _ignoreOverflow();
    final logins = <(String, String)>[];
    final inFlight = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStateProvider.overrideWith(_SignedOut.new)],
        child: ShadApp(
          home: ShadToaster(
            child: Scaffold(
              body: LoginView(
                onLoginSuccess: () {},
                onNavigateToForgotPassword: () {},
                onNavigateToSignup: () {},
                onLogin: (username, password) {
                  logins.add((username, password));
                  return inFlight.future;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_field(LoginFormFields.usernameId), ' asha ');
    await tester.enterText(_field(LoginFormFields.passwordId), 'secret');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(logins, [('asha', 'secret')]);
    expect(find.text('Signing in…'), findsOneWidget);

    // In flight: Enter again, and the Sign in action itself, do nothing.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.state<LoginViewState>(find.byType(LoginView)).submit();
    await tester.pump();
    expect(logins, hasLength(1));

    inFlight.complete();
    await tester.pumpAndSettle();
    expect(find.text('Signing in…'), findsNothing);
    expect(logins, hasLength(1));
  });
}
