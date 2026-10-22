// workflow_manyfiles: a member's current photo is found by its uuid when
// it is not among their newest 100 files (club_client#86, club_client#127;
// club_server#27).
//
// A page of a member's files holds 100 at most, newest first. A photo older
// than that is on no first page, so code that looked for it there would
// neither read its visibility, nor change it, nor delete its file.
//
// Fixtures (all `workflow_manyfiles_` prefixed per the naming rule), made
// through the SDK in setUpAll:
//   * workflow_manyfiles_member  the member, created by the super admin.
//   * As the member: a private photo attached as the avatar, then 101 more
//     private files, each newer than the photo.
//
// Flow, as the member on their own profile:
//   1. The profile shows the photo and its "Allow others to see my photo"
//      tick, unticked: the visibility was read.
//   2. Ticking makes that file public, and no other; unticking makes it
//      private again.
//   3. The photo is cleared through `avatarMutationProvider`, as the app's
//      code would (no screen offers it): the avatar link is gone and the
//      file is soft-deleted; the 101 other files are untouched.
//   4. Cleanup: the member's other files are soft-deleted through the SDK,
//      then the super admin soft-deletes the member through the UI.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//       workflow_manyfiles_avatar_visibility_clear_test.dart

import 'package:cl_remote_store/cl_remote_store.dart'
    show
        avatarImageProvider,
        avatarMutationProvider,
        avatarVisibilityProvider,
        kUserAvatarTag;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
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

const _kMember = 'workflow_manyfiles_member';
const _kPwd = 'WfManyFilesPwd!2024';

const _kTick = 'Allow others to see my photo';
const _kPrivateRoles = ['self', 'admin', 'coach'];
const _kPublicRoles = ['public'];

/// The most files one page of a listing holds.
const _kPageSize = 100;

/// How many files the member is given after the photo: one more than a page.
const int _kNewerFiles = _kPageSize + 1;

late Media _photo;
final List<int> _newerFileIds = [];

Future<SecureClient> _sdkClient(String username, String password) async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
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
    await sudo.users.createUser(
      username: _kMember,
      passwordHash: _kPwd,
      firstName: 'Manyfiles',
      lastName: 'Member',
      phone: '7400500610',
      email: '$_kMember@example.com',
      gender: Gender.preferNotToSay,
      dateOfBirthUtc: DateTime.utc(1990),
    );
    await sudo.auth.logout();

    final member = await _sdkClient(_kMember, _kPwd);
    _photo = await member.media.upload(
      fileBytes: pixelPng,
      filename: 'workflow_manyfiles_photo.png',
      contentType: 'image/png',
      accessRoles: _kPrivateRoles,
    );
    await member.userMedia.attach(
      _kMember,
      tag: kUserAvatarTag,
      mediaUuid: _photo.uuid,
    );
    for (var i = 0; i < _kNewerFiles; i++) {
      final file = await member.media.upload(
        fileBytes: pixelPng,
        filename: 'workflow_manyfiles_file_$i.png',
        contentType: 'image/png',
        accessRoles: _kPrivateRoles,
      );
      _newerFileIds.add(file.id);
    }
    await member.auth.logout();
  });

  testWidgets(
    "Issue 127: with a member's photo older than their newest 100 files, "
    'its visibility is read and changed and the photo is cleared, each on '
    'that file',
    (tester) async {
      await useTestSurface(tester, const Size(1600, 4000));

      // Server-side reads, to assert what the app wrote.
      final sudoSdk = await _sdkClient(_kSudoUsername, _kSudoPassword);
      final memberSdk = await _sdkClient(_kMember, _kPwd);
      addTearDown(sudoSdk.auth.logout);

      // The case under test: the photo is not on the first page of the
      // member's files.
      final newest = await _newestFiles(memberSdk);
      expect(newest.total, _kNewerFiles + 1);
      expect(newest.items, hasLength(_kPageSize));
      expect(newest.items.map((m) => m.uuid), isNot(contains(_photo.uuid)));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── 1. The member sees the photo, private ─────────────────────────
      await loginViaUi(tester, _kMember, _kPwd);
      await go(tester, '/memberzone/profile');
      await waitFor(
        tester,
        () => _avatarUrl(tester)?.contains(_photo.uuid) ?? false,
        description: 'the member to see the photo on their own profile',
      );
      await waitFor(
        tester,
        () => _tick.evaluate().isNotEmpty,
        description: "the tick on the member's current photo",
      );
      expect(tester.widget<ShadCheckbox>(_tick).value, isFalse);
      expect(
        container(tester).read(avatarVisibilityProvider(_kMember)).value,
        isFalse,
      );

      // ─── 2. Public, then private again ─────────────────────────────────
      tester.widget<ShadCheckbox>(_tick).onChanged!(true);
      await waitFor(
        tester,
        () => tester.widget<ShadCheckbox>(_tick).value,
        description: 'the tick to show the photo as public',
      );
      expect(firstErrorToastMessage(tester), isNull);
      expect(
        (await sudoSdk.media.getById(_photo.id)).accessRoles,
        _kPublicRoles,
      );
      for (final file in (await _newestFiles(memberSdk)).items) {
        expect(
          file.accessRoles,
          unorderedEquals(_kPrivateRoles),
          reason: 'no other file of the member was made public',
        );
      }

      tester.widget<ShadCheckbox>(_tick).onChanged!(false);
      await waitFor(
        tester,
        () => !tester.widget<ShadCheckbox>(_tick).value,
        description: 'the tick to show the photo as private',
      );
      expect(firstErrorToastMessage(tester), isNull);
      expect(
        (await sudoSdk.media.getById(_photo.id)).accessRoles,
        unorderedEquals(_kPrivateRoles),
      );

      // ─── 3. The photo is cleared ───────────────────────────────────────
      await container(
        tester,
      ).read(avatarMutationProvider(_kMember).notifier).clear();
      await waitFor(
        tester,
        () {
          final avatar = container(tester).read(avatarImageProvider(_kMember));
          return !avatar.isLoading && avatar.value == null;
        },
        description: 'the profile to show no photo',
      );
      expect(_tick, findsNothing);
      expect(
        await sudoSdk.userMedia.listByTag(_kMember, kUserAvatarTag),
        isEmpty,
        reason: 'the avatar link is gone',
      );
      expect(
        (await sudoSdk.media.getById(_photo.id)).isDeleted,
        isTrue,
        reason: "the photo's file was soft-deleted",
      );
      expect(
        (await _newestFiles(memberSdk)).total,
        _kNewerFiles,
        reason: 'no other file of the member was deleted',
      );
      await logout(tester);

      // ─── 4. Cleanup ────────────────────────────────────────────────────
      for (final id in _newerFileIds) {
        await memberSdk.media.softDelete(id);
      }
      expect((await _newestFiles(memberSdk)).total, 0);
      // The member's own SDK session ends before the member is deleted: a
      // deleted user can no longer log out.
      await memberSdk.auth.logout();

      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await softDeleteUserViaUi(tester, _kMember);
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

/// The "Allow others to see my photo" tick on the current photo.
Finder get _tick => find.widgetWithText(ShadCheckbox, _kTick);

/// The first page of the member's own files that are not deleted, newest
/// first, with their total.
Future<PaginatedList<Media>> _newestFiles(SecureClient member) =>
    member.media.listMyFiles(limit: _kPageSize);
