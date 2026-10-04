// workflow1: admin-created user can self-service reset their password.
//
// Flow:
//   1. Login as bootstrap super-admin (sudo).
//   2. Drive the admin Add User form at /memberzone/users/new to create
//      `workflow1_user` with a known password (auto-approved as active).
//   3. Logout sudo, login as workflow1_user.
//   4. Open the change-password form, set a new password, submit.
//   5. Logout, login again with the new password — assert success.
//   6. Logout, login as sudo, soft-delete workflow1_user via the admin
//      profile screen, then verify the user can no longer log in.
//
// Resource-naming convention: every entity created by an integration test
// (users, events, venues, etc.) MUST be prefixed with the test's workflow
// number — e.g. `workflow1_user`, `workflow1_event`. This guarantees
// per-test namespacing and prevents collisions when several integration
// tests run against the same server.
//
// The test relies on a freshly reset DB. The recommended way to run it:
//
//   just app-test-one app_test_server1.conf \
//       workflow1_password_reset_by_user_test.dart
//
// Manual run:
//
//   flutter test integration_test/workflow1_password_reset_by_user_test.dart \
//     --dart-define=CLUB_API_BASE_URL=http://127.0.0.1:8155/v1 \
//     --dart-define=SUDO_PASSWORD=... \
//     --dart-define=SUDO_USERNAME=sudo

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import '_helpers/auth.dart';
import '_helpers/forms.dart';
import '_helpers/pump.dart';
import '_helpers/users.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

// Test-user identity (created during the test, lives only on a fresh DB).
// All test-created resources are prefixed `workflow1_` per the integration
// test naming convention.
const _kTestUsername = 'workflow1_user';
const _kTestPassword = 'Workflow1Pwd!2024';
const _kTestNewPassword = 'Workflow1Pwd!Reset9876';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env). '
      'Source: `pass club/dev/bootstrap/sudo`.',
    );
  }

  testWidgets(
    'admin-created user can self-service reset their password',
    (tester) async {
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // 1. Login as super-admin.
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'sudo login should succeed against a fresh test DB',
      );

      // 2. Create a fresh member via the admin Add User form.
      await createUserViaUi(
        tester,
        username: _kTestUsername,
        password: _kTestPassword,
      );

      // 3. Logout sudo, then login as the new member.
      await logout(tester);
      await loginViaUi(tester, _kTestUsername, _kTestPassword);
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'admin-created user should be active and able to log in',
      );

      // 4. Self-service password reset.
      await _changePasswordViaUi(
        tester,
        currentPassword: _kTestPassword,
        newPassword: _kTestNewPassword,
      );
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'session should remain valid after password change',
      );

      // 5. Logout and log back in with the new password.
      await logout(tester);
      await loginViaUi(tester, _kTestUsername, _kTestNewPassword);
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'login with new password should succeed',
      );

      // 6. Soft-delete the test user via the admin profile screen and confirm
      //    they can no longer log in. This also exercises the admin
      //    delete-user UI flow.
      await logout(tester);
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'sudo login (for cleanup) should succeed',
      );

      await softDeleteUserViaUi(tester, _kTestUsername);

      await logout(tester);
      await attemptLoginExpectFailure(
        tester,
        _kTestUsername,
        _kTestNewPassword,
      );

      expect(
        currentUser(tester),
        isNull,
        reason: 'soft-deleted user must not be able to log in',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

// ---------------------------------------------------------------------------
// Domain UI flow specific to workflow1. The password-change form will move
// into a shared _helpers/profile.dart helper when a second test needs it.
// ---------------------------------------------------------------------------

Future<void> _changePasswordViaUi(
  WidgetTester tester, {
  required String currentPassword,
  required String newPassword,
}) async {
  // Sub-flow start: open the member's own profile, then tap "Change
  // Password" to open the change-password dialog (ChangePasswordView, which
  // wraps the ui_lib ChangePasswordForm).
  await go(tester, '/memberzone/profile');

  final changePwButton = find.widgetWithText(ActionButton, 'Change Password');
  await waitFor(
    tester,
    () => changePwButton.evaluate().isNotEmpty,
    description: '"Change Password" button on the profile screen',
  );
  // The button can sit below the viewport on a long profile; invoking
  // onPressed directly avoids both the off-screen tap failure and the
  // need to bake scroll behaviour into the test. (Same pattern as the
  // Delete button — see _softDeleteUserViaUi.)
  final changePwWidget = tester.widget<ActionButton>(changePwButton);
  expect(
    changePwWidget.onPressed,
    isNotNull,
    reason: '"Change Password" should be enabled on the self profile',
  );
  changePwWidget.onPressed!.call();
  await settle(tester);

  // ChangePasswordForm has ShadInputFormField with ids 'current', 'next',
  // 'confirm', and a ShadButton labelled "Update password".
  await waitFor(
    tester,
    () => find
        .byWidgetPredicate(
          (w) => w is ShadInputFormField && w.id == 'current',
        )
        .evaluate()
        .isNotEmpty,
    description: 'change-password form to mount',
  );

  await enterTextById(tester, 'current', currentPassword);
  await enterTextById(tester, 'next', newPassword);
  await enterTextById(tester, 'confirm', newPassword);
  await tester.pump();

  // Invoke the submit's onPressed directly rather than tapping: on the
  // 1280x720 Linux desktop window the "Update password" button sits below
  // the fold, where a synthesized tap lands off-screen and no-ops.
  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Update password'),
    reason: '"Update password" submit button',
  );
  await settle(tester);

  await waitFor(
    tester,
    () => find.widgetWithText(ShadButton, 'Update password').evaluate().isEmpty,
    description: 'change-password form to close',
  );
}
