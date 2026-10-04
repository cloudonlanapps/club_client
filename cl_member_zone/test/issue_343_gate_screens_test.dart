import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _member() => UserPrivate(
  username: 'm1',
  displayName: 'Plain Member',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
);

class _StubAuth extends AuthNotifier {
  _StubAuth(this._user);
  final UserPrivate? _user;

  @override
  Future<UserPrivate?> build() async => _user;
}

Widget _wrap(Widget child, {required UserPrivate? user}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => _StubAuth(user)),
    ],
    child: ShadApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('Issue 343: admin/coach gate renders in screen, not view', () {
    testWidgets('UsersScreen denies non-coach/admin users with Access Denied', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          UsersScreen(
            onUserTap: (_) {},
            onReviewUser: (_) {},
            onCreateUser: () {},
            onHome: () {},
          ),
          user: _member(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets(
      'GroupsScreen denies non-coach/admin users with Access Denied',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            GroupsScreen(
              onGroupTap: (_) {},
              onCreateGroup: () {},
              onHome: () {},
            ),
            user: _member(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Access Denied'), findsOneWidget);
      },
    );

    testWidgets(
      'GroupJoinRequestsScreen denies non-coach/admin users with Access Denied',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            GroupJoinRequestsScreen(groupId: 1, onHome: () {}),
            user: _member(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Access Denied'), findsOneWidget);
      },
    );
  });
}
