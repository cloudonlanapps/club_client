import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

// UsersScreen receives navigation callbacks from the host (app/lib/router.dart)
// and must not construct any route strings itself (issue #654). These tests pin
// the callback contract: the screen extracts the username from the tapped/
// selected user and delegates routing to the host callbacks.

class _StubAuth extends AuthNotifier {
  _StubAuth(this._user);
  final UserPrivate? _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

class _StubUsersMaster extends ClUsersMasterNotifier {
  _StubUsersMaster(this._users);
  final Map<String, UserInfo> _users;
  @override
  Future<Map<String, UserInfo>> build() async => _users;
}

UserPrivate _admin() => UserPrivate(
  username: 'admin1',
  displayName: 'Admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

UserInfo _user(String username, UserStatus status) => UserInfo(
  username: username,
  displayName: username,
  status: status,
  isSuperAdmin: false,
  roles: const UserRoles(),
);

Widget _wrap({
  required Map<String, UserInfo> users,
  required void Function(String) onUserTap,
  required void Function(String) onReviewUser,
  required VoidCallback onCreateUser,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => _StubAuth(_admin())),
      clUsersMasterProvider.overrideWith(() => _StubUsersMaster(users)),
      avatarImageProvider.overrideWith((ref, username) async => null),
    ],
    child: ShadApp(
      home: Scaffold(
        body: UsersScreen(
          onUserTap: onUserTap,
          onReviewUser: onReviewUser,
          onCreateUser: onCreateUser,
          onHome: () {},
        ),
      ),
    ),
  );
}

void main() {
  group('Issue 654: UsersScreen forwards username-keyed nav callbacks', () {
    testWidgets(
      'Issue 654: Act Now forwards first pending username to onReviewUser',
      (tester) async {
        String? reviewedUsername;
        await tester.pumpWidget(
          _wrap(
            users: {'pendinguser': _user('pendinguser', UserStatus.pending)},
            onUserTap: (_) {},
            onReviewUser: (u) => reviewedUsername = u,
            onCreateUser: () {},
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ShadButton, 'Act Now'));
        await tester.pump();

        expect(reviewedUsername, 'pendinguser');
      },
    );

    testWidgets(
      'Issue 654: tapping a user forwards its username to onUserTap',
      (tester) async {
        String? tappedUsername;
        await tester.pumpWidget(
          _wrap(
            users: {'activeuser': _user('activeuser', UserStatus.active)},
            onUserTap: (u) => tappedUsername = u,
            onReviewUser: (_) {},
            onCreateUser: () {},
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('activeuser'));
        await tester.pump();

        expect(tappedUsername, 'activeuser');
      },
    );
  });
}
