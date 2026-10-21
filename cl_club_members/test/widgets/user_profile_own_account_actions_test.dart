import 'package:cl_club_members/src/utils/admin_user_actions.dart';
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
  final UserPrivate _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

UserPrivate _admin(String username) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024, 6, 15),
);

Future<void> _pumpProfile(
  WidgetTester tester, {
  required UserPrivate viewer,
  required UserPrivate target,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clUserPrivateProvider(
          target.username,
        ).overrideWith((_) async => target),
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
    ),
  );
  await tester.pumpAndSettle();
}

const _forbiddenOnSelf = ['Block', 'Mark as Left', 'Delete'];

void main() {
  group('Issue 225: no Block, Mark as Left or Delete on your own '
      'account', () {
    test('Issue 225: adminActionsFor leaves them out for the viewer', () {
      final me = _admin('admin1');
      final keys = adminActionsFor(
        me,
        isSuperAdmin: false,
        viewerUsername: 'admin1',
      ).map((a) => a.key);
      expect(keys, isNot(contains('block')));
      expect(keys, isNot(contains('markLeft')));
      expect(keys, isNot(contains('delete')));

      expect(
        adminActionsFor(
          me,
          isSuperAdmin: false,
          viewerUsername: 'admin2',
        ).map((a) => a.key),
        containsAll(['block', 'markLeft', 'delete']),
      );
    });

    testWidgets('Issue 225: your own profile does not offer them', (
      tester,
    ) async {
      final me = _admin('admin1');
      await _pumpProfile(tester, viewer: me, target: me);

      for (final label in _forbiddenOnSelf) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });

    testWidgets('Issue 225: another admin profile still offers them', (
      tester,
    ) async {
      await _pumpProfile(
        tester,
        viewer: _admin('admin1'),
        target: _admin('admin2'),
      );

      for (final label in _forbiddenOnSelf) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });
  });
}
