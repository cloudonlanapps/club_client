import 'package:cl_club_members/src/views/group_profile_view.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider, imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClGroupsMasterNotifier,
        clGroupMembersProvider,
        clGroupsMasterProvider,
        groupImageProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final _group = Group(
  id: 7,
  name: 'Juniors',
  kind: GroupKind.auto,
  createdAtUtc: DateTime.utc(2025),
);

class _Groups extends ClGroupsMasterNotifier {
  @override
  Future<Map<int, Group>> build() async => {_group.id: _group};
}

class _Auth extends AuthNotifier {
  _Auth(this.user);
  final UserPrivate user;
  @override
  Future<UserPrivate?> build() async => user;
}

UserPrivate _user({bool admin = false, bool coach = false}) => UserPrivate(
  username: 'viewer',
  displayName: 'Viewer',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin, isCoach: coach),
  createdAtUtc: DateTime.utc(2024),
);

final Finder _broadcastButton = find.byTooltip('Broadcast');

/// Mounts the group page for [viewer]; returns how often the Broadcast
/// button opened the screen.
Future<List<int>> _pump(WidgetTester tester, UserPrivate viewer) async {
  final opened = <int>[];
  await tester.binding.setSurfaceSize(const Size(1200, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _Auth(viewer)),
        clGroupsMasterProvider.overrideWith(_Groups.new),
        clGroupMembersProvider.overrideWith((ref, id) async => const []),
        groupImageProvider(_group.id).overrideWith((ref) async => null),
        imageAuthHeadersProvider.overrideWith((ref) async => const {}),
      ],
      child: ShadApp(
        home: Scaffold(
          body: GroupProfileView(
            groupId: _group.id,
            onRemoved: () {},
            onBroadcast: () => opened.add(1),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  group("Issue 252: the group page's Broadcast button", () {
    testWidgets('Issue 252: an admin sees it, it opens the Broadcast '
        'screen, and the inline message section is gone', (tester) async {
      final opened = await _pump(tester, _user(admin: true));

      expect(find.text('Message this group'), findsNothing);
      expect(find.text('Type a message for this group…'), findsNothing);
      expect(_broadcastButton, findsOneWidget);

      await tester.tap(_broadcastButton);
      await tester.pump();
      expect(opened, hasLength(1));
    });

    testWidgets('Issue 252: a coach who is not an admin does not see it', (
      tester,
    ) async {
      await _pump(tester, _user(coach: true));

      expect(find.text('Juniors'), findsWidgets);
      expect(_broadcastButton, findsNothing);
    });
  });
}
