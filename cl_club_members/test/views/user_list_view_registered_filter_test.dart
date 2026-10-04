import 'package:cl_club_members/cl_club_members.dart' show UserListView;
import 'package:cl_club_members/src/providers/user_list_filter.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
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

class _StubUsersMasterNotifier extends ClUsersMasterNotifier {
  _StubUsersMasterNotifier(this._users);
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
  required List<UserInfo> registered,
  UserListFilter filter = const UserListFilter(),
}) {
  return ProviderScope(
    overrides: [
      userListFilterProvider.overrideWith((ref) => filter),
      clRegisteredUsersProvider.overrideWith((ref) async => registered),
      // UserCard reads authStateProvider + avatarImageProvider; without these
      // overrides the chain reaches the default secureClientProvider, which
      // throws UnimplementedError and the card fails to build (issue #613).
      authStateProvider.overrideWith(() => _StubAuthNotifier(_admin())),
      clUsersMasterProvider.overrideWith(() => _StubUsersMasterNotifier(users)),
      avatarImageProvider.overrideWith((ref, username) async => null),
    ],
    child: ShadApp(
      home: Scaffold(
        body: UserListView(
          currentUser: _admin(),
          onUserTap: (_) {},
          onReviewUser: (_) {},
          onCreateUser: () {},
          onActNow: () {},
        ),
      ),
    ),
  );
}

void main() {
  group('Issue 91: registered users in the Members list', () {
    final users = {'activeC': _user('activeC', UserStatus.active)};
    final registered = [_user('regD', UserStatus.registered)];

    testWidgets('the default list leaves them out', (tester) async {
      await tester.pumpWidget(_wrap(users: users, registered: registered));
      await tester.pumpAndSettle();

      expect(find.text('activeC'), findsOneWidget);
      expect(find.text('regD'), findsNothing);
    });

    testWidgets('the registered filter lists them, and only them', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          users: users,
          registered: registered,
          filter: const UserListFilter(status: UserStatus.registered),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('regD'), findsOneWidget);
      expect(find.text('@regD · onboarding'), findsOneWidget);
      expect(find.text('activeC'), findsNothing);
    });
  });
}
