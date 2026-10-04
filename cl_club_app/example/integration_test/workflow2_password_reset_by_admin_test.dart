// workflow2: super-admin can reset a member's password via the admin UI.
//
// Flow:
//   1. Login as bootstrap super-admin (sudo).
//   2. Drive the admin Add User form at /memberzone/users/new to create
//      `workflow2_user` with a known password.
//   3. Logout sudo, login as workflow2_user with the original password.
//   4. Logout, login as sudo, navigate to the user's admin profile and
//      tap "Reset Password". Read the server-generated password from
//      AdminResetPasswordResultDialog. Exercise the "Copy" button and
//      verify the clipboard payload matches. Dismiss with "OK".
//   5. Logout. Confirm the original password no longer logs the user in.
//   6. Login with the new password — assert success.
//   7. Login as sudo, soft-delete workflow2_user via the admin profile,
//      then verify the user can no longer log in.
//
// Resource-naming convention: every entity created by an integration test
// (users, events, venues, etc.) MUST be prefixed with the test's workflow
// number — e.g. `workflow2_user`, `workflow2_event`. This guarantees
// per-test namespacing and prevents collisions when several integration
// tests run against the same server.
//
// The test relies on a freshly reset DB. The recommended way to run it:
//
//   just app-test-one app_test_server1.conf \
//       workflow2_password_reset_by_admin_test.dart
//
// Manual run:
//
//   flutter test integration_test/workflow2_password_reset_by_admin_test.dart \
//     --dart-define=CLUB_API_BASE_URL=http://127.0.0.1:8155/v1 \
//     --dart-define=SUDO_PASSWORD=... \
//     --dart-define=SUDO_USERNAME=sudo

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
// All test-created resources are prefixed `workflow2_` per the integration
// test naming convention.
const _kTestUsername = 'workflow2_user';
const _kTestPassword = 'Workflow2Pwd!2024';

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
    'super-admin can reset a member password via the admin UI',
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

      // 3. Sanity-check: the original password works for the new user.
      await logout(tester);
      await loginViaUi(tester, _kTestUsername, _kTestPassword);
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'admin-created user should be active and able to log in',
      );

      // 4. Login as sudo and reset the user's password through the UI.
      await logout(tester);
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      final newPassword = await _adminResetPasswordViaUi(
        tester,
        _kTestUsername,
      );
      expect(
        newPassword,
        isNotEmpty,
        reason: 'server should generate a non-empty new password',
      );
      expect(
        newPassword,
        isNot(equals(_kTestPassword)),
        reason: 'server should generate a password different from the old one',
      );

      // 5. Old password must no longer work.
      await logout(tester);
      await attemptLoginExpectFailure(tester, _kTestUsername, _kTestPassword);
      expect(
        currentUser(tester),
        isNull,
        reason: 'old password must be rejected after admin reset',
      );

      // 6. New password must work.
      await loginViaUi(tester, _kTestUsername, newPassword);
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'login with the server-generated password should succeed',
      );

      // 7. Cleanup: soft-delete the test user via the admin UI and confirm
      //    they can no longer log in.
      await logout(tester);
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'sudo login (for cleanup) should succeed',
      );

      await softDeleteUserViaUi(tester, _kTestUsername);

      await logout(tester);
      await attemptLoginExpectFailure(tester, _kTestUsername, newPassword);
      expect(
        currentUser(tester),
        isNull,
        reason: 'soft-deleted user must not be able to log in',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

// ---------------------------------------------------------------------------
// Domain UI flow specific to workflow2. The admin password-reset dialog will
// move into a shared _helpers/profile.dart helper when a second test needs
// it.
// ---------------------------------------------------------------------------

/// Drives the super-admin "Reset Password" UI for [username] and returns
/// the server-generated password shown in the result dialog.
///
/// Path: /memberzone/users → tap user card → "Reset Password" →
/// AdminResetPasswordResultDialog → read SelectableText → tap "Copy"
/// (verify clipboard) → tap "OK".
Future<String> _adminResetPasswordViaUi(
  WidgetTester tester,
  String username,
) async {
  await go(tester, '/memberzone/users');
  final userCard = find.byKey(ValueKey(username));
  await waitFor(
    tester,
    () => userCard.evaluate().isNotEmpty,
    description: 'user card "$username" to appear in the admin list',
  );
  await tester.tap(userCard);
  await settle(tester);

  await waitFor(
    tester,
    () => find
        .widgetWithText(ActionButton, 'Reset Password')
        .evaluate()
        .isNotEmpty,
    description: 'admin user-profile screen with Reset Password button',
  );

  // Off-screen tap workaround: the profile is a long page and the action
  // button can sit below the viewport. Invoking onPressed directly avoids
  // both the tap miss and the need to bake scroll behaviour into the test.
  final resetFinder = find.widgetWithText(ActionButton, 'Reset Password');
  expect(
    resetFinder,
    findsOneWidget,
    reason:
        'expected exactly one Reset Password ActionButton on the profile '
        '(super-admin only)',
  );
  final resetButton = tester.widget<ActionButton>(resetFinder);
  expect(
    resetButton.onPressed,
    isNotNull,
    reason:
        'Reset Password ActionButton should be enabled when sudo is '
        'viewing a non-super-admin user',
  );
  resetButton.onPressed!.call();
  await settle(tester);

  // The dialog ("AdminResetPasswordResultDialog") is rendered as an
  // AlertDialog with title "Password Reset" and the new password as a
  // SelectableText below the prompt "New temporary password:".
  await waitFor(
    tester,
    () {
      final toast = firstErrorToastMessage(tester);
      if (toast != null) {
        throw TestFailure('admin reset failed. Toast: "$toast"');
      }
      return find.text('Password Reset').evaluate().isNotEmpty &&
          find.text('New temporary password:').evaluate().isNotEmpty;
    },
    description: 'AdminResetPasswordResultDialog to appear',
  );

  final passwordTextFinder = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(SelectableText),
  );
  expect(
    passwordTextFinder,
    findsOneWidget,
    reason:
        'expected one SelectableText carrying the generated password '
        'inside the result dialog',
  );
  final selectable = tester.widget<SelectableText>(passwordTextFinder);
  final newPassword = selectable.data;
  expect(
    newPassword,
    isNotNull,
    reason: 'SelectableText should carry the generated password as data',
  );

  // Exercise the Copy button — admins rely on it to relay the password
  // out-of-band to the user. Read the clipboard back and assert it matches
  // the displayed password.
  await Clipboard.setData(const ClipboardData(text: ''));
  final copyFinder = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextButton, 'Copy'),
  );
  expect(
    copyFinder,
    findsOneWidget,
    reason: 'expected one Copy button inside the result dialog',
  );
  await tester.tap(copyFinder);
  await settle(tester);
  final clip = await Clipboard.getData(Clipboard.kTextPlain);
  expect(
    clip?.text,
    equals(newPassword),
    reason: 'Copy button should put the generated password on the clipboard',
  );

  // Dismiss the dialog.
  final okFinder = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextButton, 'OK'),
  );
  expect(
    okFinder,
    findsOneWidget,
    reason: 'expected one OK button inside the result dialog',
  );
  await tester.tap(okFinder);
  await settle(tester);

  await waitFor(
    tester,
    () => find.text('New temporary password:').evaluate().isEmpty,
    description: 'AdminResetPasswordResultDialog to dismiss',
  );

  return newPassword!;
}
