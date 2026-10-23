// workflow_privphoto: an admin who is not a super admin replaces a member's
// private profile photo (club_client#87, club_client#126; club_server#28).
//
// A member keeps one avatar. The app uploads the new photo and attaches it;
// the server removes the previous link and soft-deletes its file, a file
// the admin may not view included.
//
// Fixtures (all `workflow_privphoto_` prefixed per the naming rule), seeded
// through the admin SDK in setUpAll (workflow_adminphoto's pattern):
//   * workflow_privphoto_member  the member whose photo changes.
//   * workflow_privphoto_admin   an admin (not the super admin).
//
// The picker cannot open a native file dialog under test, so
// `imagePickerProvider` returns a fixed PNG; the rest runs for real.
//
// Flow:
//   1. The member uploads a photo with "Allow others to see my photo" off.
//   2. The admin opens the member from the members page and replaces the
//      photo. Read back as the super admin: one avatar link, the new file,
//      and the member's file soft-deleted.
//   3. The member keeps the current photo to themselves alone (through the
//      SDK: the app offers no such choice), so the admin is shown none. The
//      admin uploads again. Read back: one avatar link, the new file, and
//      the hidden file soft-deleted.
//   4. Cleanup: the super admin soft-deletes the two users.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//       workflow_privphoto_admin_replaces_private_photo_test.dart

import 'package:cl_club_members/cl_club_members.dart' show UserListView;
import 'package:cl_remote_store/cl_remote_store.dart'
    show avatarImageProvider, imagePickerProvider, kUserAvatarTag;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '_helpers/auth.dart';
import '_helpers/forms.dart';
import '_helpers/photos.dart';
import '_helpers/pump.dart';
import '_helpers/surface.dart';
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

const _kMember = 'workflow_privphoto_member';
const _kAdmin = 'workflow_privphoto_admin';
const _kPwd = 'WfPrivPhotoPwd!2024';

const _kPrivateRoles = ['self', 'admin', 'coach'];
const _kSelfAlone = ['self'];

Future<SecureClient> _sdkClient(String username, String password) async {
  final c = await createTestClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(username, password);
  return c;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  setUpAll(() async {
    final sudo = await _sdkClient(_kSudoUsername, _kSudoPassword);
    var phone = 7400500510;
    for (final (username, first, last) in [
      (_kMember, 'Private', 'Member'),
      (_kAdmin, 'Private', 'Admin'),
    ]) {
      await sudo.users.createUser(
        username: username,
        passwordHash: _kPwd,
        firstName: first,
        lastName: last,
        phone: '${phone++}',
        email: '$username@example.com',
        gender: Gender.preferNotToSay,
        dateOfBirthUtc: DateTime.utc(1990),
      );
    }
    await sudo.users.assignRole(_kAdmin, 'admin');
    await sudo.auth.logout();
  });

  testWidgets(
    'Issue 126: an admin who is not a super admin replaces a photo a member '
    'stored private, and then one the admin may not view; each time the '
    'member is left with one avatar link and the old file is soft-deleted',
    (tester) async {
      await useTestSurface(tester, const Size(1600, 4000));

      // Server-side reads, to assert what the UI wrote.
      final sudoSdk = await _sdkClient(_kSudoUsername, _kSudoPassword);
      final memberSdk = await _sdkClient(_kMember, _kPwd);
      final adminSdk = await _sdkClient(_kAdmin, _kPwd);
      addTearDown(sudoSdk.auth.logout);

      await pumpApp(
        tester,
        apiBaseUrl: _kApiBaseUrl,
        extraOverrides: [
          imagePickerProvider.overrideWithValue(
            stubPicker('workflow_privphoto_photo.png'),
          ),
        ],
      );
      await ensureLoggedOut(tester);

      // ─── 1. The member uploads a photo, the tick off ───────────────────
      await loginViaUi(tester, _kMember, _kPwd);
      await go(tester, '/memberzone/profile');
      await _openPreview(tester);
      final tick = find.descendant(
        of: find.byType(ShadDialog),
        matching: find.byType(ShadCheckbox),
      );
      expect(tick, findsOneWidget, reason: 'the member is offered the tick');
      expect(
        tester.widget<ShadCheckbox>(tick).value,
        isFalse,
        reason: '"Allow others to see my photo" starts off',
      );
      _confirmPreview(tester);
      await settle(tester);
      await waitFor(
        tester,
        () => _avatarUrl(tester) != null,
        description: 'the member to see their photo',
        timeout: const Duration(seconds: 30),
      );
      expect(firstErrorToastMessage(tester), isNull);

      final membersOwn = await _onlyAvatar(sudoSdk);
      expect(membersOwn.uploadedBy, _kMember);
      expect(membersOwn.accessRoles, unorderedEquals(_kPrivateRoles));
      await logout(tester);

      // ─── 2. The admin replaces it ──────────────────────────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openMember(tester);
      await waitFor(
        tester,
        () => _avatarUrl(tester)?.contains(membersOwn.uuid) ?? false,
        description: "the admin to see the member's photo",
      );
      await _openPreview(tester);
      _confirmPreview(tester);
      await settle(tester);
      await waitFor(
        tester,
        () {
          final url = _avatarUrl(tester);
          return url != null && !url.contains(membersOwn.uuid);
        },
        description: "the member's profile to show the admin's photo",
        timeout: const Duration(seconds: 30),
      );
      expect(firstErrorToastMessage(tester), isNull);

      final adminsFirst = await _onlyAvatar(sudoSdk);
      expect(adminsFirst.uuid, isNot(membersOwn.uuid));
      expect(
        (await sudoSdk.media.getById(membersOwn.id)).isDeleted,
        isTrue,
        reason: "the member's own photo was soft-deleted",
      );
      await logout(tester);

      // ─── 3. The admin replaces a photo they may not view ───────────────
      // The file was uploaded in the member's name, so it is theirs to
      // narrow.
      await memberSdk.media.patch(adminsFirst.id, accessRoles: _kSelfAlone);
      expect(
        await adminSdk.userMedia.listByTag(_kMember, kUserAvatarTag),
        isEmpty,
        reason: 'the server leaves the link out of what the admin lists',
      );

      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openMember(tester);
      // Let the profile read the avatar: the admin is shown none.
      await settle(tester);
      expect(_avatarUrl(tester), isNull);
      await _openPreview(tester);
      _confirmPreview(tester);
      await settle(tester);
      await waitFor(
        tester,
        () => _avatarUrl(tester) != null,
        description: "the member's profile to show the admin's second photo",
        timeout: const Duration(seconds: 30),
      );
      expect(firstErrorToastMessage(tester), isNull);

      final adminsSecond = await _onlyAvatar(sudoSdk);
      expect(adminsSecond.uuid, isNot(adminsFirst.uuid));
      expect(
        (await sudoSdk.media.getById(adminsFirst.id)).isDeleted,
        isTrue,
        reason: 'the photo the admin could not view was soft-deleted',
      );
      await logout(tester);

      // The users' own SDK sessions end before the users are deleted: a
      // deleted user can no longer log out.
      for (final c in [memberSdk, adminSdk]) {
        await c.auth.logout();
      }

      // ─── 4. Cleanup through the UI ─────────────────────────────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await softDeleteUserViaUi(tester, _kMember);
      await softDeleteUserViaUi(tester, _kAdmin);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

// ---------------------------------------------------------------------------
// Local helpers.
// ---------------------------------------------------------------------------

/// The member's photo URL as the mounted profile's avatar reads it.
String? _avatarUrl(WidgetTester tester) =>
    container(tester).read(avatarImageProvider(_kMember)).value;

/// As the logged-in admin: the member's profile, from the members page.
Future<void> _openMember(WidgetTester tester) async {
  await go(tester, '/memberzone/users');
  final memberCard = find.byKey(const ValueKey(_kMember));
  await waitForInList(
    tester,
    memberCard,
    within: find.byType(UserListView),
    description: "the member's card in the members list",
  );
  await tapVisible(tester, memberCard);
  await settle(tester);
}

/// Taps the pencil on the photo of the open profile; the stub picker then
/// opens the preview.
Future<void> _openPreview(WidgetTester tester) async {
  await waitFor(
    tester,
    () => find.byTooltip('Change photo').evaluate().isNotEmpty,
    description: 'the pencil on the photo',
  );
  await tapVisible(tester, find.byTooltip('Change photo'));
  await settle(tester);
  expect(find.text('Update profile photo'), findsOneWidget);
}

/// Confirms the photo preview dialog.
void _confirmPreview(WidgetTester tester) => invokeShadButton(
  tester,
  find.descendant(
    of: find.byType(ShadDialog),
    matching: find.widgetWithText(ShadButton, 'OK'),
  ),
  reason: 'confirm the photo preview',
);

/// The file behind the member's one avatar link, as the super admin reads
/// it: the super admin is shown every link, whoever may view its file.
Future<Media> _onlyAvatar(SecureClient sudo) async {
  final links = await sudo.userMedia.listByTag(_kMember, kUserAvatarTag);
  expect(links, hasLength(1), reason: 'the member has one avatar link');
  return sudo.media.getByUuid(links.single.mediaUuid);
}
