import 'package:cl_club_members/src/widgets/avatar_visibility_toggle.dart';
import 'package:cl_club_members/src/widgets/profile_avatar_area.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

const _tick = 'Allow others to see my photo';
const _photoUrl = 'https://example.test/avatar.png';

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._user);
  final UserPrivate? _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

/// Records what the widgets ask of the avatar notifier.
class _RecordingAvatarMutationNotifier extends AvatarMutationNotifier {
  _RecordingAvatarMutationNotifier({this.throwOnSetVisibility = false});

  final bool throwOnSetVisibility;

  final List<bool> ownUploads = [];
  final List<String> onBehalfUploads = [];
  final List<bool> visibilityChanges = [];

  @override
  Future<void> build(String username) async {}

  @override
  Future<void> upload({
    required List<int> bytes,
    required String filename,
    required String contentType,
    required bool allowOthersToSee,
  }) async => ownUploads.add(allowOthersToSee);

  @override
  Future<void> uploadOnBehalf({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async => onBehalfUploads.add(filename);

  @override
  Future<void> setVisibility({required bool allowOthersToSee}) async {
    visibilityChanges.add(allowOthersToSee);
    if (throwOnSetVisibility) throw Exception('server refused the change');
  }
}

// 1x1 transparent PNG to satisfy Image.memory in the preview.
const _pixelPngBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

Future<PickedImage?> _stubPicker() async => const PickedImage(
  bytes: _pixelPngBytes,
  filename: 'photo.png',
  mimeType: 'image/png',
);

UserPrivate _user(
  String username, {
  bool isAdmin = false,
  bool isCoach = false,
  DateTime? deletedAtUtc,
}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: isAdmin, isCoach: isCoach),
  createdAtUtc: DateTime.utc(2024, 6, 15),
  deletedAtUtc: deletedAtUtc,
);

Widget _wrap({
  required UserPrivate target,
  required UserPrivate? viewer,
  required _RecordingAvatarMutationNotifier notifier,
  String? photoUrl,
  bool photoIsPublic = false,
}) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => _StubAuthNotifier(viewer)),
    avatarImageProvider(target.username).overrideWith((_) async => photoUrl),
    avatarVisibilityProvider(
      target.username,
    ).overrideWith((_) async => photoIsPublic),
    avatarMutationProvider.overrideWith(() => notifier),
    imagePickerProvider.overrideWithValue(_stubPicker),
  ],
  child: ShadApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 260,
          height: 400,
          child: ProfileAvatarArea(user: target),
        ),
      ),
    ),
  ),
);

void main() {
  final member = _user('robin');

  testWidgets(
    'Issue 35: an admin viewing another member sees the pencil',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          target: member,
          viewer: _user('admin1', isAdmin: true),
          notifier: _RecordingAvatarMutationNotifier(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Change photo'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 35: a coach viewing another member does not see the pencil',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          target: member,
          viewer: _user('coach1', isCoach: true),
          notifier: _RecordingAvatarMutationNotifier(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Change photo'), findsNothing);
    },
  );

  testWidgets(
    'Issue 35: an ordinary member viewing another member does not see the '
    'pencil',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          target: member,
          viewer: _user('sam'),
          notifier: _RecordingAvatarMutationNotifier(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Change photo'), findsNothing);
    },
  );

  testWidgets(
    'Issue 35: an admin does not see the pencil on a deleted member',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          target: _user('gone', deletedAtUtc: DateTime.utc(2025)),
          viewer: _user('admin1', isAdmin: true),
          notifier: _RecordingAvatarMutationNotifier(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Change photo'), findsNothing);
    },
  );

  testWidgets(
    'Issue 35: the admin\'s preview dialog has no "Allow others to see my '
    'photo" tick, and OK uploads on the member\'s behalf',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      await tester.pumpWidget(
        _wrap(
          target: member,
          viewer: _user('admin1', isAdmin: true),
          notifier: notifier,
          // Even when the member's current photo is public.
          photoUrl: _photoUrl,
          photoIsPublic: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();

      expect(find.text('Update profile photo'), findsOneWidget);
      expect(find.text(_tick), findsNothing);
      expect(find.byType(ShadCheckbox), findsNothing);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(notifier.onBehalfUploads, const ['photo.png']);
      expect(notifier.ownUploads, isEmpty);
    },
  );

  testWidgets(
    "Issue 35: the member's own preview dialog keeps the tick and uploads "
    'as themselves',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      await tester.pumpWidget(
        _wrap(target: member, viewer: member, notifier: notifier),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();

      expect(find.text(_tick), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(notifier.ownUploads, const [false]);
      expect(notifier.onBehalfUploads, isEmpty);
    },
  );

  testWidgets(
    'Issue 35: the member ticks "Allow others to see my photo" on the '
    'current photo, without uploading',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      await tester.pumpWidget(
        _wrap(
          target: member,
          viewer: member,
          notifier: notifier,
          photoUrl: _photoUrl,
        ),
      );
      await tester.pumpAndSettle();

      final tick = find.descendant(
        of: find.byType(AvatarVisibilityToggle),
        matching: find.byType(ShadCheckbox),
      );
      expect(tester.widget<ShadCheckbox>(tick).value, isFalse);

      await tester.tap(find.text(_tick));
      await tester.pumpAndSettle();

      expect(notifier.visibilityChanges, const [true]);
      expect(notifier.ownUploads, isEmpty);
      expect(find.text('Update profile photo'), findsNothing);
    },
  );

  testWidgets(
    'Issue 35: the member unticks a public current photo to make it private',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      await tester.pumpWidget(
        _wrap(
          target: member,
          viewer: member,
          notifier: notifier,
          photoUrl: _photoUrl,
          photoIsPublic: true,
        ),
      );
      await tester.pumpAndSettle();

      final tick = find.descendant(
        of: find.byType(AvatarVisibilityToggle),
        matching: find.byType(ShadCheckbox),
      );
      expect(tester.widget<ShadCheckbox>(tick).value, isTrue);

      await tester.tap(find.text(_tick));
      await tester.pumpAndSettle();

      expect(notifier.visibilityChanges, const [false]);
    },
  );

  testWidgets(
    'Issue 35: a member with no photo is offered no tick',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          target: member,
          viewer: member,
          notifier: _RecordingAvatarMutationNotifier(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_tick), findsNothing);
    },
  );

  testWidgets(
    "Issue 35: an admin is offered no tick on a member's current photo",
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          target: member,
          viewer: _user('admin1', isAdmin: true),
          notifier: _RecordingAvatarMutationNotifier(),
          photoUrl: _photoUrl,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_tick), findsNothing);
    },
  );

  testWidgets(
    'Issue 35: a refused visibility change shows a fixed message',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier(
        throwOnSetVisibility: true,
      );
      await tester.pumpWidget(
        _wrap(
          target: member,
          viewer: member,
          notifier: notifier,
          photoUrl: _photoUrl,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(_tick));
      await tester.pumpAndSettle();

      expect(notifier.visibilityChanges, const [true]);
      // Issue 138: a write that may have landed says so, in fixed text.
      expect(find.text(uncertainWriteMessage), findsOne);
      expect(find.textContaining('server refused the change'), findsNothing);
    },
  );
}
