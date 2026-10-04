import 'package:cl_club_members/src/views/user_profile_view.dart'
    show UserProfileView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show avatarImageProvider, clUserPrivateProvider;
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
      authStateProvider.overrideWith(() => _StubAuthNotifier(viewer)),
      avatarImageProvider(target.username).overrideWith((_) async => null),
    ],
    child: ShadApp(
      home: Scaffold(
        body: UserProfileView(targetUsername: target.username),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Issue 247: admin viewing a pending user sees the profile, not the gate',
    (tester) async {
      final pending = _user(username: 'newbie', status: UserStatus.pending);
      final admin = _user(
        username: 'admin1',
        status: UserStatus.active,
        isAdmin: true,
      );

      await tester.pumpWidget(_wrap(target: pending, viewer: admin));
      await tester.pumpAndSettle();

      expect(find.text('Profile Unavailable'), findsNothing);
    },
  );

  testWidgets(
    'Issue 247: non-admin viewing a pending user still sees the gate',
    (tester) async {
      final pending = _user(username: 'newbie', status: UserStatus.pending);
      final member = _user(username: 'member1', status: UserStatus.active);

      await tester.pumpWidget(_wrap(target: pending, viewer: member));
      await tester.pumpAndSettle();

      expect(find.text('Profile Unavailable'), findsOneWidget);
    },
  );

  testWidgets('Issue 247: admin viewing a blocked user also sees the profile', (
    tester,
  ) async {
    final blocked = _user(username: 'blockie', status: UserStatus.blocked);
    final admin = _user(
      username: 'admin1',
      status: UserStatus.active,
      isAdmin: true,
    );

    await tester.pumpWidget(_wrap(target: blocked, viewer: admin));
    await tester.pumpAndSettle();

    expect(find.text('Profile Unavailable'), findsNothing);
  });
}
