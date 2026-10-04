import 'package:cl_club_members/src/widgets/cards/user_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier, avatarImageProvider, clUsersMasterProvider;
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

UserInfo _pendingMember() => const UserInfo(
  username: 'newbie',
  displayName: 'New Bie',
  status: UserStatus.pending,
  isSuperAdmin: false,
  roles: UserRoles(),
);

UserInfo _activeMember() => const UserInfo(
  username: 'activeguy',
  displayName: 'Active Guy',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(),
);

UserInfo _blockedMember() => const UserInfo(
  username: 'blockedguy',
  displayName: 'Blocked Guy',
  status: UserStatus.blocked,
  isSuperAdmin: false,
  roles: UserRoles(),
);

UserInfo _leftMember() => const UserInfo(
  username: 'leftguy',
  displayName: 'Left Guy',
  status: UserStatus.left,
  isSuperAdmin: false,
  roles: UserRoles(),
);

Widget _wrap({required Widget child, required UserInfo user}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => _StubAuthNotifier(_admin())),
      clUsersMasterProvider.overrideWith(
        () => _StubUsersMasterNotifier({user.username: user}),
      ),
      avatarImageProvider(user.username).overrideWith((_) async => null),
    ],
    child: ShadApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets(
    'Issue 380: admin viewing a pending user row sees a single Review action',
    (tester) async {
      final pending = _pendingMember();
      var profileTaps = 0;
      var reviewTaps = 0;
      await tester.pumpWidget(
        _wrap(
          user: pending,
          child: UserCard(
            username: pending.username,
            onTap: () => profileTaps++,
            onReview: () => reviewTaps++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Block'), findsNothing);
      expect(find.text('Delete'), findsNothing);

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(reviewTaps, 1);
      expect(profileTaps, 0);
    },
  );

  testWidgets(
    'Issue 305: admin viewing an active user row sees no kebab actions',
    (tester) async {
      final active = _activeMember();
      var tapCount = 0;
      await tester.pumpWidget(
        _wrap(
          user: active,
          child: UserCard(
            username: active.username,
            onTap: () => tapCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Block'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Review'), findsNothing);

      await tester.tap(find.text('Active Guy'));
      await tester.pumpAndSettle();
      expect(tapCount, 1);
    },
  );

  testWidgets(
    'Issue 501: admin viewing a blocked user sees Unblock + Delete via the '
    'typed action slot',
    (tester) async {
      final blocked = _blockedMember();
      await tester.pumpWidget(
        _wrap(
          user: blocked,
          child: UserCard(username: blocked.username),
        ),
      );
      await tester.pumpAndSettle();

      // AdminUserActions now resolves a List<ActionItem> that UserCard feeds to
      // EntityCard.trailingActions; on the default (desktop) width both render
      // inline via ActionGroup.
      expect(find.text('Unblock'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 501: admin viewing a left user sees Reactivate + Delete via the '
    'typed action slot',
    (tester) async {
      final left = _leftMember();
      await tester.pumpWidget(
        _wrap(
          user: left,
          child: UserCard(username: left.username),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reactivate'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    },
  );
}
