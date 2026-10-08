// Auth / navigation helpers for integration tests.
//
// Owns:
//   * container, currentUser — read provider state from the live App.
//   * ensureLoggedOut, logout — tear down sessions between flows.
//   * go                       — set a workflow start point via the router
//                                (the only legitimate `go` per CLAUDE.md;
//                                everything downstream of it must be tap-
//                                driven).
//   * loginViaUi               — drive the login form to completion.
//   * attemptLoginExpectFailure — drive the form and assert the auth
//                                 notifier ends in a non-loading null state.
//
// Extracted from workflow1.

import 'package:cl_club_app/cl_club_app.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:flutter/widgets.dart' show EditableText, Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'forms.dart';
import 'pump.dart';

ProviderContainer container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(App)));

Object? currentUser(WidgetTester tester) =>
    container(tester).read(authStateProvider).valueOrNull;

Future<void> ensureLoggedOut(WidgetTester tester) async {
  if (currentUser(tester) != null) await logout(tester);
}

Future<void> logout(WidgetTester tester) async {
  await container(tester).read(authStateProvider.notifier).logout();
  await settle(tester);
}

/// Reads the router from the provider container rather than calling
/// `GoRouter.of(context)`, because the router lives below `App` in the
/// widget tree and `GoRouter.of` on the App element fails with
/// "No GoRouter found in context".
Future<void> go(WidgetTester tester, String location) async {
  container(tester).read(routerProvider).go(location);
  await settle(tester);
}

Future<void> loginViaUi(
  WidgetTester tester,
  String username,
  String password,
) async {
  await go(tester, '/auth/login');

  // Theme/asset config loads async on first pump, so the form may not
  // exist immediately after navigation.
  await waitFor(
    tester,
    () => find
        .byWidgetPredicate(
          (w) => w is ShadInputFormField && w.id == 'username',
        )
        .evaluate()
        .isNotEmpty,
    description: 'login form to mount',
  );

  await enterTextById(tester, 'username', username);
  await enterTextById(tester, 'password', password);
  // No Enter here: in the password field it signs in (#103), and the
  // button pressed below would then read "Signing in…".
  await tester.pump();

  // The public navbar shows its own "Sign in" ShadButton (which is a
  // no-op `context.go('/auth/login')` on this route). Walking from the
  // username field up to its enclosing ShadForm and back down to the
  // matching button is unambiguous and screen-size independent.
  await ensureTextById(tester, 'username', username);
  await ensureTextById(tester, 'password', password);
  final beforeSubmit = loginFormState(tester);
  await submitFormContaining(tester, fieldId: 'username', label: 'Sign in');

  try {
    await waitFor(
      tester,
      () => currentUser(tester) != null,
      description: 'login completion for $username',
    );
  } catch (e) {
    final auth = container(tester).read(authStateProvider);
    // Integration test diagnostic output written to stdout; `print` is the
    // intended channel here because logger setup isn't wired in tests.
    // ignore: avoid_print
    print(
      '[test] login failed for "$username": '
      'isLoading=${auth.isLoading} '
      'value=${auth.valueOrNull} '
      'error=${auth.error} '
      'passwordLength=${password.length}\n'
      '[test]   before submit: $beforeSubmit\n'
      '[test]   after timeout: ${loginFormState(tester)}',
    );
    rethrow;
  }
}

/// Where the router is and what the login form holds, for a login that
/// never completes: an emptied field or a moved route shows up here.
String loginFormState(WidgetTester tester) {
  try {
    return _loginFormState(tester);
  } on Object catch (e) {
    // Never let the diagnostic replace the failure it is describing.
    return '<state unavailable: $e>';
  }
}

String _loginFormState(WidgetTester tester) {
  String field(String id) {
    final editable = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is ShadInputFormField && w.id == id,
      ),
      matching: find.byType(EditableText),
    );
    final found = editable.evaluate();
    if (found.isEmpty) return '<absent>';
    final text = (found.first.widget as EditableText).controller.text;
    return '${text.length} chars';
  }

  final route = container(
    tester,
  ).read(routerProvider).routerDelegate.currentConfiguration.uri;
  final errors = find
      .textContaining('is required')
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .toList();
  return 'route=$route username=${field('username')} '
      'password=${field('password')} errors=$errors';
}

Future<void> attemptLoginExpectFailure(
  WidgetTester tester,
  String username,
  String password,
) async {
  await go(tester, '/auth/login');
  await waitFor(
    tester,
    () => find
        .byWidgetPredicate(
          (w) => w is ShadInputFormField && w.id == 'username',
        )
        .evaluate()
        .isNotEmpty,
    description: 'login form to mount',
  );

  await enterTextById(tester, 'username', username);
  await enterTextById(tester, 'password', password);
  // No Enter here: in the password field it signs in (#103), and the
  // button pressed below would then read "Signing in…".
  await tester.pump();

  await tester.tap(find.widgetWithText(ShadButton, 'Sign in').last);
  await settle(tester);

  // The auth notifier sets `state.error` on failure and `state.value`
  // stays null — the "non-loading null" state is the assertion target.
  await waitFor(
    tester,
    () {
      final auth = container(tester).read(authStateProvider);
      return !auth.isLoading && auth.valueOrNull == null;
    },
    description: 'login attempt for $username to be rejected',
  );
}
