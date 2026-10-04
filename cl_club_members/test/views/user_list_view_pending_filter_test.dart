import 'package:cl_club_members/cl_club_members.dart' show UserListView;
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
  required VoidCallback onActNow,
}) {
  return ProviderScope(
    overrides: [
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
          onActNow: onActNow,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Issue 400: admin user list hides pending users and shows banner',
    (tester) async {
      var actNowTaps = 0;
      await tester.pumpWidget(
        _wrap(
          users: {
            'pendingA': _user('pendingA', UserStatus.pending),
            'pendingB': _user('pendingB', UserStatus.pending),
            'activeC': _user('activeC', UserStatus.active),
          },
          onActNow: () => actNowTaps++,
        ),
      );
      await tester.pumpAndSettle();

      // Pending users are not in the rendered list.
      expect(find.text('pendingA'), findsNothing);
      expect(find.text('pendingB'), findsNothing);
      // Active user is still shown.
      expect(find.text('activeC'), findsOneWidget);

      // Banner is visible.
      expect(
        find.text('You have 2 registrations waiting for approval.'),
        findsOneWidget,
      );

      // Act Now wired through.
      await tester.tap(find.text('Act Now'));
      await tester.pumpAndSettle();
      expect(actNowTaps, 1);
    },
  );

  testWidgets(
    'Issue 400: admin user list hides the banner when there are no '
    'pending users',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          users: {'activeC': _user('activeC', UserStatus.active)},
          onActNow: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Act Now'), findsNothing);
      expect(find.textContaining('waiting for approval'), findsNothing);
      expect(find.text('activeC'), findsOneWidget);
    },
  );
}
