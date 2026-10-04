// workflow_leftlogin: a member who has left the club tries to sign in and is
// told so in plain words, never shown the raw server refusal
// (club_core#157).
//
// Flow:
//   1. Setup (SDK, as the super admin): create an active member, then mark
//      them left — the server's leave flow.
//   2. From /auth/login, sign in as that member.
//   3. The server refuses with 401 ACCOUNT_LEFT; the login screen shows the
//      account-left card with the fixed message, and no exception text.
//   4. "Back to sign in" returns to the login form.
//
// Cleanup: the member is soft-deleted through the SDK in tearDownAll. A
// member who has left has no user card to open, so there is no UI path to
// their delete action.
//
// Recommended run:
//
//   just app-test-one app_test_server1.conf \
//       workflow_leftlogin_account_left_test.dart

import 'package:cl_member_auth/src/utils/login_error_messages.dart'
    show LoginErrorMessages;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
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
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

const _kMember = 'workflow_leftlogin_member';
const _kPwd = 'WorkflowLeftLogin!2024';

Future<SecureClient> _adminClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  setUpAll(() async {
    final client = await _adminClient();
    await client.users.createUser(
      username: _kMember,
      passwordHash: _kPwd,
      firstName: 'Leftlogin',
      lastName: 'Member',
      phone: '9876543210',
      email: '$_kMember@example.com',
      gender: Gender.preferNotToSay,
      dateOfBirthUtc: DateTime.utc(1990, 1, 1),
    );
    final left = await client.users.markLeft(_kMember);
    expect(left.status, UserStatus.left);
    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _adminClient();
    await client.users.deleteUser(_kMember);
    await client.auth.logout();
  });

  testWidgets(
    'a member who has left signs in and is told the account has left the club',
    (tester) async {
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      await attemptLoginExpectFailure(tester, _kMember, _kPwd);

      await waitFor(
        tester,
        () =>
            find.byType(ShadCard).evaluate().isNotEmpty &&
            find.text('Account inactive').evaluate().isNotEmpty,
        description: 'account-left card to appear',
      );
      expect(
        find.text(LoginErrorMessages.accountLeft),
        findsWidgets,
        reason: 'the card (and its toast) say the account has left the club',
      );
      expect(find.textContaining('ServerException'), findsNothing);
      expect(find.textContaining('ACCOUNT_LEFT'), findsNothing);
      expect(find.textContaining('Sign in failed'), findsNothing);
      expect(currentUser(tester), isNull);

      invokeShadButton(
        tester,
        find.widgetWithText(ShadButton, 'Back to sign in'),
        reason: '"Back to sign in" on the account-left card',
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
