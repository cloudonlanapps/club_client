import 'package:cl_club_members/src/views/user_profile_view.dart'
    show UserProfileView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show avatarImageProvider, clUserGroupsProvider, clUserPrivateProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._user);
  final UserPrivate? _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

UserPrivate _user({
  required String username,
  required UserStatus status,
  bool isAdmin = false,
}) {
  return UserPrivate(
    username: username,
    displayName: username,
    status: status,
    isSuperAdmin: false,
    roles: UserRoles(isAdmin: isAdmin),
    createdAtUtc: DateTime.utc(2024, 6, 15),
  );
}

Widget _wrap({
  required UserPrivate target,
  required UserPrivate? viewer,
}) {
  return ProviderScope(
    overrides: [
      clUserPrivateProvider(target.username).overrideWith((_) async => target),
      clUserGroupsProvider(
        target.username,
      ).overrideWith((_) async => const <Group>[]),
      authStateProvider.overrideWith(() => _StubAuthNotifier(viewer)),
      avatarImageProvider(target.username).overrideWith((_) async => null),
    ],
    child: ShadApp(
      home: Scaffold(
        body: UserProfileView(
          targetUsername: target.username,
          onRoleToggle: (_, {required selected}) {},
          onStatusAction: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Issue 380: pending user shows single Review entry instead of Approve/Block',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final pending = _user(username: 'newbie', status: UserStatus.pending);
      final admin = _user(
        username: 'admin1',
        status: UserStatus.active,
        isAdmin: true,
      );

      await tester.pumpWidget(_wrap(target: pending, viewer: admin));
      await tester.pumpAndSettle();

      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject (block)'), findsNothing);
      expect(find.text('Mark as Left'), findsNothing);
      expect(find.widgetWithText(InkWell, 'Block'), findsNothing);
    },
  );

  testWidgets('Issue 248: blocked user shows Unblock, not Block', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final blocked = _user(username: 'blockie', status: UserStatus.blocked);
    final admin = _user(
      username: 'admin1',
      status: UserStatus.active,
      isAdmin: true,
    );

    await tester.pumpWidget(_wrap(target: blocked, viewer: admin));
    await tester.pumpAndSettle();

    expect(find.text('Unblock'), findsOneWidget);
    expect(find.text('Mark as Left'), findsNothing);
  });

  testWidgets('Issue 248: Roles section visible but disabled with reason for '
      'non-active', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pending = _user(username: 'newbie', status: UserStatus.pending);
    final admin = _user(
      username: 'admin1',
      status: UserStatus.active,
      isAdmin: true,
    );

    await tester.pumpWidget(_wrap(target: pending, viewer: admin));
    await tester.pumpAndSettle();

    expect(find.text('Roles'), findsOneWidget);
    expect(
      find.text("Roles can't be modified for non-active users."),
      findsOneWidget,
    );
    expect(find.text('Make this user an Admin'), findsOneWidget);
    final adminCheckbox = tester.widget<ShadCheckbox>(
      find.ancestor(
        of: find.text('Make this user an Admin'),
        matching: find.byType(ShadCheckbox),
      ),
    );
    expect(adminCheckbox.enabled, isFalse);
    expect(adminCheckbox.onChanged, isNull);
  });

  testWidgets('Issue 248: Roles section visible for active users', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final active = _user(username: 'memberx', status: UserStatus.active);
    final admin = _user(
      username: 'admin1',
      status: UserStatus.active,
      isAdmin: true,
    );

    await tester.pumpWidget(_wrap(target: active, viewer: admin));
    await tester.pumpAndSettle();

    expect(find.text('Roles'), findsOneWidget);
    expect(find.text('Make this user an Admin'), findsOneWidget);
  });

  testWidgets('Issue 248: contact edit pencil hidden for non-active users', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pending = _user(username: 'newbie', status: UserStatus.pending);
    final admin = _user(
      username: 'admin1',
      status: UserStatus.active,
      isAdmin: true,
    );

    await tester.pumpWidget(_wrap(target: pending, viewer: admin));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edit'), findsNothing);
  });

  testWidgets('Issue 248: Add to Group hidden for non-active users', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pending = _user(username: 'newbie', status: UserStatus.pending);
    final admin = _user(
      username: 'admin1',
      status: UserStatus.active,
      isAdmin: true,
    );

    await tester.pumpWidget(_wrap(target: pending, viewer: admin));
    await tester.pumpAndSettle();

    expect(find.text('+ Add to Group'), findsNothing);
  });

  testWidgets('Issue 248: Add to Group visible for active users', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final active = _user(username: 'memberx', status: UserStatus.active);
    final admin = _user(
      username: 'admin1',
      status: UserStatus.active,
      isAdmin: true,
    );

    await tester.pumpWidget(_wrap(target: active, viewer: admin));
    await tester.pumpAndSettle();

    expect(find.text('+ Add to Group'), findsOneWidget);
  });
}
