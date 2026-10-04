import 'package:cl_club_members/cl_club_members.dart' show UserListView;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _StubUsersMasterNotifier extends ClUsersMasterNotifier {
  _StubUsersMasterNotifier(this._users);
  final Map<String, UserInfo> _users;
  @override
  Future<Map<String, UserInfo>> build() async => _users;
}

UserPrivate _user(UserRoles roles) => UserPrivate(
  username: 'u1',
  displayName: 'U One',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: roles,
  createdAtUtc: DateTime.utc(2024),
);

Widget _wrap(UserPrivate currentUser) => ProviderScope(
  overrides: [
    clUsersMasterProvider.overrideWith(
      () => _StubUsersMasterNotifier(const {}),
    ),
  ],
  child: ShadApp(
    home: Scaffold(
      body: UserListView(
        currentUser: currentUser,
        onUserTap: (_) {},
        onReviewUser: (_) {},
        onCreateUser: () {},
        onActNow: () {},
      ),
    ),
  ),
);

void main() {
  group('Issue 494: UserListView precondition assert', () {
    testWidgets('renders for a coach/admin user (gate satisfied)', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_user(const UserRoles(isCoach: true))));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('asserts for a non-coach/admin user (gate violated)', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_user(const UserRoles())));

      expect(tester.takeException(), isAssertionError);
    });
  });
}
