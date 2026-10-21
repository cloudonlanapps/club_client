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

UserPrivate _admin() => UserPrivate(
  username: 'admin1',
  displayName: 'Admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

class _Auth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => _admin();
}

class _Users extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => {
    for (final (name, status) in [
      ('abby', UserStatus.active),
      ('abel', UserStatus.active),
      ('carl', UserStatus.active),
      ('dina', UserStatus.active),
      ('erin', UserStatus.active),
      // Pending users are not in an admin's list (they are reviewed
      // elsewhere), so they are not counted either.
      ('abner', UserStatus.pending),
    ])
      name: UserInfo(
        username: name,
        displayName: name,
        status: status,
        isSuperAdmin: false,
        roles: const UserRoles(),
      ),
  };
}

void main() {
  testWidgets('Issue 195: with a search, the count line shows the matches '
      'out of every user the list would show', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_Auth.new),
          clUsersMasterProvider.overrideWith(_Users.new),
          avatarImageProvider.overrideWith((ref, username) async => null),
          userListFilterProvider.overrideWith(
            (ref) => const UserListFilter(searchTerm: 'ab'),
          ),
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
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('abby'), findsOneWidget);
    expect(find.text('abel'), findsOneWidget);
    expect(find.text('Showing 2 of 5'), findsOneWidget);
  });
}
