// workflow_joinid: Focused integration test for the "join-request notification
// shows the wrong user" bug.
//
// Repro spec (manual report):
//   Two members with similar-looking first names exist (Arvelo Testwood,
//   Arvena Testwood). The first member logs in and submits a join request
//   for a manual group. The admin must see a notification correctly
//   attributing the request to Arvelo (not Arvena).
//
// This test mirrors the user's clicks: sudo creates the fixtures via the
// SDK, then every step that follows is driven by the UI (login form,
// "Join" affordance on the my-groups page, navigation into the Pending
// Actions list, approve button). The body string and the underlying
// payload's `requesterUsername` are both asserted so a regression in
// either the registry formatter or the server payload fails the test.
//
// Recommended run (from the club_core root, once per conf):
//   just app-test-one app_test_server1.conf \
//       workflow_joinid_join_request_identity_test.dart

import 'package:cl_club_members/src/widgets/cards/group_card.dart'
    show GroupCard;
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import '_helpers/auth.dart';
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

const _kAdmin = 'workflow_joinid_admin';
const _kAdminPwd = 'WorkflowJoinIdAdmPwd!2024';

const _kArvelo = 'workflow_joinid_arvelo';
const _kArveloFirst = 'Arvelo';
const _kArveloLast = 'Testwood';

const _kArvena = 'workflow_joinid_arvena';
const _kArvenaFirst = 'Arvena';
const _kArvenaLast = 'Testwood';

const _kMemberPwd = 'WorkflowJoinIdMemPwd!2024';

const _kGroupManual = 'workflow_joinid_manual';

Future<SecureClient> _sudoClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env). '
      'Source: `pass club/dev/bootstrap/sudo`.',
    );
  }

  setUpAll(() async {
    final client = await _sudoClient();

    await client.users.createUser(
      username: _kAdmin,
      passwordHash: _kAdminPwd,
      firstName: 'WorkflowJoinId',
      lastName: 'Admin',
      phone: '9876500000',
      email: '$_kAdmin@example.com',
      gender: Gender.preferNotToSay,
      dateOfBirthUtc: DateTime.utc(1990, 1, 1),
    );
    await client.users.assignRole(_kAdmin, 'admin');

    await client.users.createUser(
      username: _kArvelo,
      passwordHash: _kMemberPwd,
      firstName: _kArveloFirst,
      lastName: _kArveloLast,
      phone: '9876500001',
      email: '$_kArvelo@example.com',
      gender: Gender.male,
      dateOfBirthUtc: DateTime.utc(2014, 6, 15),
    );

    await client.users.createUser(
      username: _kArvena,
      passwordHash: _kMemberPwd,
      firstName: _kArvenaFirst,
      lastName: _kArvenaLast,
      phone: '9876500002',
      email: '$_kArvena@example.com',
      gender: Gender.female,
      dateOfBirthUtc: DateTime.utc(2016, 4, 10),
    );

    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _sudoClient();
    for (final u in const [_kAdmin, _kArvelo, _kArvena]) {
      try {
        await client.users.deleteUser(u);
      } on Object catch (_) {
        /* best-effort */
      }
      try {
        await client.users.hardDeleteUser(u);
      } on Object catch (_) {
        /* best-effort */
      }
    }
    await client.auth.logout();
  });

  testWidgets(
    'admin notification attributes manual-group join request to the '
    'correct member (arvelo), not a similarly-named peer (arvena)',
    (tester) async {
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ---------------------------------------------------------------
      // Scene 1 — Admin creates a manual group via SDK (UI for group
      // creation is exercised by workflow_grp; here we keep the focus on
      // the join-request identity surface).
      // ---------------------------------------------------------------
      final sudo = await _sudoClient();
      final group = await sudo.groups.createGroup(
        name: _kGroupManual,
        description: 'Manual group for join-id repro',
      );
      expect(group.kind, GroupKind.manual);
      await sudo.auth.logout();

      // ---------------------------------------------------------------
      // Scene 2 — Arvelo logs in via the UI, navigates to his my-groups
      // page, confirms the manual group is joinable, and taps Join.
      // ---------------------------------------------------------------
      await loginViaUi(tester, _kArvelo, _kMemberPwd);
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'arvelo should be the authenticated user',
      );
      // Sanity: the auth provider holds arvelo's username, not arvena's.
      final me = container(tester).read(authStateProvider).valueOrNull!;
      expect(
        me.username,
        _kArvelo,
        reason: 'login session must carry arvelo, not arvena',
      );

      await go(tester, '/memberzone/my-groups/$_kArvelo');
      await _waitForJoinableGroup(tester, _kGroupManual);
      await _tapJoinForGroup(tester, _kGroupManual);
      await _waitForRequestRowPending(tester, _kGroupManual);

      await logout(tester);

      // ---------------------------------------------------------------
      // Scene 3 — Admin logs in, opens the Pending Actions list, and
      // sees the join-request row attributed to ARVELO.
      // ---------------------------------------------------------------
      await loginViaUi(tester, _kAdmin, _kAdminPwd);

      await go(tester, '/memberzone/pending-actions');

      // The registry formatter renders the body verbatim as
      // "<requesterUsername> asked to join <groupName>." — so we look
      // for arvelo's body and explicitly check that arvena's body
      // is NOT present anywhere on screen.
      const arveloBody = '$_kArvelo asked to join $_kGroupManual.';
      const arvenaBody = '$_kArvena asked to join $_kGroupManual.';

      await waitFor(
        tester,
        () => find.text(arveloBody).evaluate().isNotEmpty,
        description: 'pending action body for arvelo',
      );
      expect(
        find.text(arvenaBody),
        findsNothing,
        reason:
            'Pending Actions must not show arvena as the requester — '
            'this is the exact bug being investigated.',
      );

      // Double-verify by reading the master state. The notification
      // payload must carry arvelo in `data.requesterUsername`.
      final pendingMaster = container(
        tester,
      ).read(clPendingActionsMasterProvider).valueOrNull;
      expect(pendingMaster, isNotNull);
      final matches = pendingMaster!.values.where(
        (n) =>
            n.type == 'group.join_request' &&
            (_data(n)['groupName'] as String?) == _kGroupManual,
      );
      expect(
        matches,
        isNotEmpty,
        reason: 'master state must surface a join_request for the group',
      );
      for (final n in matches) {
        expect(
          _data(n)['requesterUsername'],
          _kArvelo,
          reason: 'payload.data.requesterUsername must be arvelo',
        );
        expect(
          _data(n)['requesterUsername'],
          isNot(_kArvena),
          reason: 'payload must not name arvena as the requester',
        );
      }

      // ---------------------------------------------------------------
      // Scene 4 — Admin approves the pending action via the UI, and
      // arvelo (not arvena) becomes a member.
      // ---------------------------------------------------------------
      await _approvePendingActionFor(tester, body: arveloBody);

      // Server roundtrip: confirm membership via the groups master.
      final verify = await _sudoClient();
      final members = await verify.groups.getMembers(group.id);
      expect(
        members.any((m) => m.membername == _kArvelo),
        isTrue,
        reason: 'arvelo should be a member after approval',
      );
      expect(
        members.any((m) => m.membername == _kArvena),
        isFalse,
        reason: 'arvena was never the requester and must not be added',
      );

      // Cleanup: sudo soft-deletes the group (UI delete is covered by
      // workflow_grp; this test focuses on the identity assertion).
      try {
        await verify.groups.deleteGroup(group.id);
      } on Object catch (_) {
        /* best-effort */
      }
      await verify.auth.logout();

      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

// ---------------------------------------------------------------------------
// Local helpers — only used by this workflow.
// ---------------------------------------------------------------------------

Map<String, dynamic> _data(AppNotification n) {
  final raw = n.payload['data'];
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const <String, dynamic>{};
}

Future<void> _waitForJoinableGroup(
  WidgetTester tester,
  String groupName,
) async {
  await waitFor(
    tester,
    () {
      final nameText = find.descendant(
        of: find.byType(GroupCard),
        matching: find.text(groupName),
      );
      if (nameText.evaluate().isEmpty) return false;
      final card = find.ancestor(
        of: nameText,
        matching: find.byType(GroupCard),
      );
      return find
          .descendant(
            of: card,
            matching: find.widgetWithText(ActionButton, 'Request to Join'),
          )
          .evaluate()
          .isNotEmpty;
    },
    description: 'manual group "$groupName" to appear in joinable list',
  );
}

Future<void> _tapJoinForGroup(WidgetTester tester, String groupName) async {
  final nameText = find.descendant(
    of: find.byType(GroupCard),
    matching: find.text(groupName),
  );
  final card = find.ancestor(of: nameText, matching: find.byType(GroupCard));
  final joinBtn = find.descendant(
    of: card,
    matching: find.widgetWithText(ActionButton, 'Request to Join'),
  );
  expect(
    joinBtn,
    findsOneWidget,
    reason: 'expected one joinable GroupCard for "$groupName"',
  );
  tester.widget<ActionButton>(joinBtn).onPressed!.call();
  await settle(tester);
}

Future<void> _waitForRequestRowPending(
  WidgetTester tester,
  String groupName,
) async {
  await waitFor(
    tester,
    () {
      final nameText = find.descendant(
        of: find.byType(GroupCard),
        matching: find.text(groupName),
      );
      if (nameText.evaluate().isEmpty) return false;
      final card = find.ancestor(
        of: nameText,
        matching: find.byType(GroupCard),
      );
      return find
          .descendant(
            of: card,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Text &&
                  (w.data?.toLowerCase().contains('pending') ?? false),
            ),
          )
          .evaluate()
          .isNotEmpty;
    },
    description: 'pending request row for "$groupName"',
  );
}

Future<void> _approvePendingActionFor(
  WidgetTester tester, {
  required String body,
}) async {
  await waitFor(
    tester,
    () => find.text(body).evaluate().isNotEmpty,
    description: 'pending action body "$body" to render',
  );

  // The Approve button sits inside the same Row as the body text.
  final approve = find.descendant(
    of: find.ancestor(
      of: find.text(body),
      matching: find.byType(Row),
    ),
    matching: find.widgetWithText(ShadButton, 'Approve'),
  );
  expect(
    approve,
    findsAtLeastNWidgets(1),
    reason: 'expected an Approve button on the row for "$body"',
  );
  tester.widget<ShadButton>(approve.first).onPressed!.call();
  await settle(tester);
}
