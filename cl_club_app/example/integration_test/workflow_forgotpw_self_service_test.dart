// workflow_forgotpw: an unauthenticated visitor can request a password reset
// from the login screen and is shown a speculative confirmation that never
// reveals whether the email matches a member.
//
// Flow:
//   1. From /auth/login, tap "Forgot password?".
//   2. Enter an email and submit.
//   3. Assert the speculative confirmation panel appears ("Check your email…",
//      "If your email is in our member list…", "24 hours").
//   4. Tap "Back to sign in" and assert the login form returns.
//
// The server's POST /v1/auth/reset-password returns 204 regardless of whether
// the email matches a member (no account-enumeration). We submit a deliberately
// non-member address so the server sends no email and creates no resource —
// nothing to clean up. The functional outcome (a matching member receives a new
// password by email) cannot be asserted here because the test harness has no
// access to the mailbox; that path is covered server-side. This test locks in
// the client wiring and the speculative-confirmation UX.
//
// Recommended run:
//
//   just app-test-one app_test_server1.conf \
//       workflow_forgotpw_self_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '_helpers/auth.dart';
import '_helpers/forms.dart';
import '_helpers/pump.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);

// A deliberately non-member address: the server returns 204 and sends nothing,
// so the test creates no resource. Prefixed per the naming convention.
const _kNonMemberEmail = 'workflow_forgotpw_nobody@example.com';

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'visitor requests a password reset and sees a speculative confirmation',
    (tester) async {
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // 1. Start at the login screen, then tap the "Forgot password?" link —
      //    the real user-facing entry point (no deep-link to the route).
      await go(tester, '/auth/login');
      await waitFor(
        tester,
        () => _field('username').evaluate().isNotEmpty,
        description: 'login form to mount',
      );

      invokeShadButton(
        tester,
        find.widgetWithText(ShadButton, 'Forgot password?'),
        reason: '"Forgot password?" link on the login screen',
      );
      await settle(tester);

      // 2. The reset form mounts with an email field.
      await waitFor(
        tester,
        () => _field('email').evaluate().isNotEmpty,
        description: 'forgot-password form to mount',
      );

      await enterTextById(tester, 'email', _kNonMemberEmail);
      await tester.pump();
      await submitFormContaining(
        tester,
        fieldId: 'email',
        label: 'Send reset email',
      );
      await settle(tester);

      // 3. The speculative confirmation replaces the form — and crucially does
      //    NOT confirm the email exists.
      await waitFor(
        tester,
        () => find.text('Check your email').evaluate().isNotEmpty,
        description: 'speculative confirmation panel to appear',
      );
      expect(
        find.textContaining('If your email is in our member list'),
        findsOneWidget,
      );
      expect(find.textContaining('24 hours'), findsOneWidget);
      expect(
        _field('email'),
        findsNothing,
        reason: 'the form should be replaced by the confirmation panel',
      );

      // 4. "Back to sign in" returns to the login form.
      invokeShadButton(
        tester,
        find.widgetWithText(ShadButton, 'Back to sign in'),
        reason: '"Back to sign in" on the confirmation panel',
      );
      await settle(tester);

      await waitFor(
        tester,
        () => _field('username').evaluate().isNotEmpty,
        description: 'login form to return after "Back to sign in"',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
