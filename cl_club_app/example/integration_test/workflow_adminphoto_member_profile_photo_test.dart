// workflow_adminphoto: an admin changes a member's profile photo, and the
// member makes the current photo public (club_client#35, club_server#18).
//
// The photo an admin uploads is stored private in the member's name: the
// member and staff see it, other members do not. Making it public stays the
// member's choice, taken with the "Allow others to see my photo" tick on the
// current photo, without a new upload.
//
// The member whose photo changes is a coach with a public profile, because
// that profile is the one place an ordinary member is shown someone else's
// photo: `/memberzone/profile/:publicId`, reached from an event's coach row.
//
// Fixtures (all `workflow_adminphoto_` prefixed per the naming rule), seeded
// through the admin SDK in setUpAll (workflowcoach's pattern):
//   * workflow_adminphoto_admin   an admin (not the super admin).
//   * workflow_adminphoto_coach   the member whose photo changes.
//   * workflow_adminphoto_member  another, ordinary member.
//   * workflow_adminphoto_venue, workflow_adminphoto_event  the event whose
//     coach row opens the public profile.
//
// The picker cannot open a native file dialog under test, so
// `imagePickerProvider` returns a fixed PNG; the rest runs for real.
//
// Flow:
//   1. The other member opens the coach's public profile: no photo.
//   2. The admin opens the coach from the members page, taps the pencil; the
//      preview has no tick; uploads. The file is the coach's, private.
//   3. The other member still sees no photo.
//   4. The coach sees the photo on their own profile and ticks the box.
//   5. The other member now sees the photo.
//   6. The coach unticks: private again.
//   7. The coach replaces the photo the admin uploaded; the old file is
//      soft-deleted.
//   8. Cleanup: the super admin soft-deletes the three users.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//       workflow_adminphoto_member_profile_photo_test.dart

import 'package:cl_club_members/cl_club_members.dart' show PublicProfileView;
import 'package:cl_remote_store/cl_remote_store.dart'
    show avatarImageProvider, imagePickerProvider, kUserAvatarTag;
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show CredentialedNetworkImage, PickedImage;

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

const _kAdmin = 'workflow_adminphoto_admin';
const _kCoach = 'workflow_adminphoto_coach';
const _kMember = 'workflow_adminphoto_member';
const _kPwd = 'WfAdminPhotoPwd!2024';
const _kVenue = 'workflow_adminphoto_venue';
const _kEventTitle = 'workflow_adminphoto_event';
const _kCoachDisplayName = 'Photo Coach';
const _kCoachRow = '• $_kCoachDisplayName';

const _kTick = 'Allow others to see my photo';
const _kPrivateRoles = ['self', 'admin', 'coach'];
const _kPublicRoles = ['public'];

// A tiny VALID 8x8 PNG (the one workflow_imgupload uses): the server converts
// it to webp, which rejects malformed input.
const _pixelPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  8,
  0,
  0,
  0,
  8,
  1,
  3,
  0,
  0,
  0,
  254,
  193,
  44,
  200,
  0,
  0,
  0,
  32,
  99,
  72,
  82,
  77,
  0,
  0,
  122,
  38,
  0,
  0,
  128,
  132,
  0,
  0,
  250,
  0,
  0,
  0,
  128,
  232,
  0,
  0,
  117,
  48,
  0,
  0,
  234,
  96,
  0,
  0,
  58,
  152,
  0,
  0,
  23,
  112,
  156,
  186,
  81,
  60,
  0,
  0,
  0,
  6,
  80,
  76,
  84,
  69,
  34,
  102,
  170,
  255,
  255,
  255,
  219,
  25,
  64,
  108,
  0,
  0,
  0,
  1,
  98,
  75,
  71,
  68,
  1,
  255,
  2,
  45,
  222,
  0,
  0,
  0,
  7,
  116,
  73,
  77,
  69,
  7,
  234,
  5,
  31,
  14,
  8,
  46,
  165,
  0,
  240,
  48,
  0,
  0,
  0,
  37,
  116,
  69,
  88,
  116,
  100,
  97,
  116,
  101,
  58,
  99,
  114,
  101,
  97,
  116,
  101,
  0,
  50,
  48,
  50,
  54,
  45,
  48,
  53,
  45,
  51,
  49,
  84,
  49,
  52,
  58,
  48,
  56,
  58,
  52,
  54,
  43,
  48,
  48,
  58,
  48,
  48,
  20,
  238,
  139,
  9,
  0,
  0,
  0,
  37,
  116,
  69,
  88,
  116,
  100,
  97,
  116,
  101,
  58,
  109,
  111,
  100,
  105,
  102,
  121,
  0,
  50,
  48,
  50,
  54,
  45,
  48,
  53,
  45,
  51,
  49,
  84,
  49,
  52,
  58,
  48,
  56,
  58,
  52,
  54,
  43,
  48,
  48,
  58,
  48,
  48,
  101,
  179,
  51,
  181,
  0,
  0,
  0,
  40,
  116,
  69,
  88,
  116,
  100,
  97,
  116,
  101,
  58,
  116,
  105,
  109,
  101,
  115,
  116,
  97,
  109,
  112,
  0,
  50,
  48,
  50,
  54,
  45,
  48,
  53,
  45,
  51,
  49,
  84,
  49,
  52,
  58,
  48,
  56,
  58,
  52,
  54,
  43,
  48,
  48,
  58,
  48,
  48,
  50,
  166,
  18,
  106,
  0,
  0,
  0,
  11,
  73,
  68,
  65,
  84,
  8,
  215,
  99,
  96,
  64,
  5,
  0,
  0,
  16,
  0,
  1,
  161,
  197,
  33,
  193,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];

Future<PickedImage?> _stubPicker() async => const PickedImage(
  bytes: _pixelPng,
  filename: 'workflow_adminphoto_photo.png',
  mimeType: 'image/png',
);

late int _venueId;
late int _eventId;

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

    final venue = await sudo.venues.createVenue(
      name: _kVenue,
      address: 'workflow_adminphoto address line 1',
    );
    _venueId = venue.id;

    var phone = 7400500310;
    for (final (username, first, last) in [
      (_kAdmin, 'Photo', 'Admin'),
      (_kCoach, 'Photo', 'Coach'),
      (_kMember, 'Photo', 'Member'),
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
    await sudo.users.assignRole(_kCoach, 'coach');

    // The coach opts into a public profile themselves (an admin cannot).
    final coach = await _sdkClient(_kCoach, _kPwd);
    await coach.users.updateUser(
      _kCoach,
      useNamePublicly: true,
      isPublicProfile: true,
    );
    await coach.auth.logout();

    final start = DateTime.now().toUtc().add(const Duration(hours: 1));
    final event = await sudo.events.createEvent(
      title: _kEventTitle,
      description: 'workflow_adminphoto test event',
      type: EventType.oneOff,
      visibility: sdk.Visibility.public,
      venueId: _venueId,
      startTimeUtc: start,
      endTimeUtc: start.add(const Duration(minutes: 30)),
      coachNames: const [_kCoach],
    );
    _eventId = event.id;

    await sudo.auth.logout();
  });

  tearDownAll(() async {
    // The users are soft-deleted through the UI by the test itself.
    final sudo = await _sdkClient(_kSudoUsername, _kSudoPassword);
    try {
      await sudo.events.deleteEvent(_eventId);
      await sudo.venues.deleteVenue(_venueId);
    } finally {
      await sudo.auth.logout();
    }
  });

  testWidgets(
    "an admin changes a member's photo; the member makes it public, private "
    'again, then replaces it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Server-side reads, to assert what the UI wrote: who owns the file,
      // its access roles, and who may download it.
      final sudoSdk = await _sdkClient(_kSudoUsername, _kSudoPassword);
      final memberSdk = await _sdkClient(_kMember, _kPwd);
      final coachSdk = await _sdkClient(_kCoach, _kPwd);
      final adminSdk = await _sdkClient(_kAdmin, _kPwd);
      addTearDown(sudoSdk.auth.logout);

      await pumpApp(
        tester,
        apiBaseUrl: _kApiBaseUrl,
        extraOverrides: [imagePickerProvider.overrideWithValue(_stubPicker)],
      );
      await ensureLoggedOut(tester);

      // ─── 1. Another member: the coach has no photo ─────────────────────
      await loginViaUi(tester, _kMember, _kPwd);
      await _openCoachPublicProfile(tester);
      expect(_publicProfilePhoto, findsNothing);
      await logout(tester);

      // ─── 2. The admin uploads a photo for the coach ────────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await go(tester, '/memberzone/users');
      final coachCard = find.byKey(const ValueKey(_kCoach));
      await waitFor(
        tester,
        () => coachCard.evaluate().isNotEmpty,
        description: "the coach's card in the members list",
      );
      await tester.tap(coachCard);
      await settle(tester);
      await waitFor(
        tester,
        () => find.byTooltip('Change photo').evaluate().isNotEmpty,
        description: "the pencil on the coach's photo, for an admin",
      );
      expect(
        find.text(_kTick),
        findsNothing,
        reason: "the tick on the current photo is the member's alone",
      );

      await tester.tap(find.byTooltip('Change photo'));
      await settle(tester);
      expect(find.text('Update profile photo'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ShadDialog),
          matching: find.byType(ShadCheckbox),
        ),
        findsNothing,
        reason: 'an admin is not offered "Allow others to see my photo"',
      );
      expect(find.text(_kTick), findsNothing);
      _confirmPreview(tester);
      await settle(tester);

      await waitFor(
        tester,
        () => _avatarUrl(tester) != null,
        description: "the admin to see the coach's new photo",
        timeout: const Duration(seconds: 30),
      );
      expect(firstErrorToastMessage(tester), isNull);

      final adminUpload = await _currentAvatar(sudoSdk);
      expect(
        adminUpload.uploadedBy,
        _kCoach,
        reason: "uploaded on the member's behalf, so the member owns it",
      );
      expect(adminUpload.accessRoles, unorderedEquals(_kPrivateRoles));
      // Staff may fetch it, another member may not.
      expect(await adminSdk.media.download(adminUpload.uuid), isNotEmpty);
      await expectLater(
        memberSdk.media.download(adminUpload.uuid),
        throwsA(isA<ServerException>()),
      );
      await logout(tester);

      // ─── 3. The other member still sees no photo ───────────────────────
      await loginViaUi(tester, _kMember, _kPwd);
      await _openCoachPublicProfile(tester);
      expect(_publicProfilePhoto, findsNothing);
      await logout(tester);

      // ─── 4. The coach sees it and ticks the box ────────────────────────
      await loginViaUi(tester, _kCoach, _kPwd);
      await go(tester, '/memberzone/profile');
      await waitFor(
        tester,
        () => _avatarUrl(tester) != null,
        description: 'the coach to see the photo on their own profile',
      );
      expect(_avatarUrl(tester), contains(adminUpload.uuid));
      await waitFor(
        tester,
        () => _tick.evaluate().isNotEmpty,
        description: "the tick on the coach's current photo",
      );
      expect(tester.widget<ShadCheckbox>(_tick).value, isFalse);

      tester.widget<ShadCheckbox>(_tick).onChanged!(true);
      await waitFor(
        tester,
        () => tester.widget<ShadCheckbox>(_tick).value,
        description: 'the tick to show the photo as public',
      );
      expect(firstErrorToastMessage(tester), isNull);

      final madePublic = await _currentAvatar(sudoSdk);
      expect(madePublic.uuid, adminUpload.uuid, reason: 'no new upload');
      expect(madePublic.accessRoles, _kPublicRoles);
      await logout(tester);

      // ─── 5. The other member now sees the photo ────────────────────────
      await loginViaUi(tester, _kMember, _kPwd);
      await _openCoachPublicProfile(tester);
      await waitFor(
        tester,
        () => _publicProfilePhoto.evaluate().isNotEmpty,
        description: "the coach's photo on the public profile",
      );
      expect(
        tester.widget<CredentialedNetworkImage>(_publicProfilePhoto).imageUrl,
        contains(adminUpload.uuid),
      );
      expect(await memberSdk.media.download(adminUpload.uuid), isNotEmpty);
      await logout(tester);

      // ─── 6. The coach unticks: private again ───────────────────────────
      await loginViaUi(tester, _kCoach, _kPwd);
      await go(tester, '/memberzone/profile');
      await waitFor(
        tester,
        () =>
            _tick.evaluate().isNotEmpty &&
            tester.widget<ShadCheckbox>(_tick).value,
        description: 'the tick to come back ticked',
      );
      tester.widget<ShadCheckbox>(_tick).onChanged!(false);
      await waitFor(
        tester,
        () => !tester.widget<ShadCheckbox>(_tick).value,
        description: 'the tick to show the photo as private',
      );
      expect(firstErrorToastMessage(tester), isNull);

      final madePrivate = await _currentAvatar(sudoSdk);
      expect(madePrivate.uuid, adminUpload.uuid);
      expect(madePrivate.accessRoles, unorderedEquals(_kPrivateRoles));
      await expectLater(
        memberSdk.media.download(adminUpload.uuid),
        throwsA(isA<ServerException>()),
      );

      // ─── 7. The coach replaces the photo the admin uploaded ────────────
      await tester.tap(find.byTooltip('Change photo'));
      await settle(tester);
      expect(
        find.descendant(
          of: find.byType(ShadDialog),
          matching: find.byType(ShadCheckbox),
        ),
        findsOneWidget,
        reason: "the member's own preview keeps the tick",
      );
      _confirmPreview(tester);
      await settle(tester);
      await waitFor(
        tester,
        () {
          final url = _avatarUrl(tester);
          return url != null && !url.contains(adminUpload.uuid);
        },
        description: "the coach's profile to show the replacement photo",
        timeout: const Duration(seconds: 30),
      );
      expect(firstErrorToastMessage(tester), isNull);

      final replacement = await _currentAvatar(sudoSdk);
      expect(replacement.uuid, isNot(adminUpload.uuid));
      expect(replacement.uploadedBy, _kCoach);
      final links = await sudoSdk.userMedia.listByTag(_kCoach, kUserAvatarTag);
      expect(
        links.map((l) => l.mediaUuid),
        [replacement.uuid],
        reason: 'the previous photo was detached',
      );
      expect(
        (await sudoSdk.media.getById(adminUpload.id)).isDeleted,
        isTrue,
        reason: 'the previous photo was soft-deleted',
      );
      await logout(tester);

      // The users' own SDK sessions end before the users are deleted: a
      // deleted user can no longer log out.
      for (final c in [memberSdk, coachSdk, adminSdk]) {
        await c.auth.logout();
      }

      // ─── 8. Cleanup through the UI ─────────────────────────────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await softDeleteUserViaUi(tester, _kCoach);
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

/// The coach's photo URL as the mounted profile's avatar reads it.
String? _avatarUrl(WidgetTester tester) =>
    container(tester).read(avatarImageProvider(_kCoach)).value;

/// The "Allow others to see my photo" tick on the current photo.
Finder get _tick => find.widgetWithText(ShadCheckbox, _kTick);

/// The photo on the open public profile; absent when it shows initials.
Finder get _publicProfilePhoto => find.descendant(
  of: find.byType(PublicProfileView),
  matching: find.byType(CredentialedNetworkImage),
);

/// Confirms the photo preview dialog.
void _confirmPreview(WidgetTester tester) => invokeShadButton(
  tester,
  find.descendant(
    of: find.byType(ShadDialog),
    matching: find.widgetWithText(ShadButton, 'OK'),
  ),
  reason: 'confirm the photo preview',
);

/// The media behind the coach's newest avatar link, as the server holds it.
Future<Media> _currentAvatar(SecureClient sudo) async {
  final links = await sudo.userMedia.listByTag(_kCoach, kUserAvatarTag);
  expect(links, isNotEmpty, reason: 'the coach has an avatar link');
  final newest = links.reduce(
    (a, b) => b.createdAtUtc.isAfter(a.createdAtUtc) ? b : a,
  );
  // A fresh database: every media row fits in one page.
  final all = await sudo.media.list(limit: 100);
  return all.items.singleWhere((m) => m.uuid == newest.mediaUuid);
}

/// As the logged-in member: the event, its coach row, the public profile.
Future<void> _openCoachPublicProfile(WidgetTester tester) async {
  await go(tester, '/memberzone/my-events/$_kMember/$_eventId');
  await waitFor(
    tester,
    () => find.text(_kCoachRow).evaluate().isNotEmpty,
    description: 'the coach row on the event',
  );
  await tester.scrollUntilVisible(
    find.text(_kCoachRow),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text(_kCoachRow));
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(PublicProfileView).evaluate().isNotEmpty,
    description: "the coach's public profile to open",
  );
  // Let the profile's photo, if it has one, mount.
  await settle(tester);
}
