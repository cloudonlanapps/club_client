import 'package:cl_club_members/src/widgets/cards/group_card.dart';
import 'package:cl_club_members/src/widgets/user_groups_section.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show NoLongerEligibleLabel;

const _member = 'workflow_member';

class _Auth extends AuthNotifier {
  _Auth(this.user);
  final UserPrivate user;
  @override
  Future<UserPrivate?> build() async => user;
}

class _Groups extends ClGroupsMasterNotifier {
  _Groups(this.groups);
  final Map<int, Group> groups;
  @override
  Future<Map<int, Group>> build() async => groups;
}

UserPrivate _user(String username, {bool admin = false, bool coach = false}) =>
    UserPrivate(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: UserRoles(isAdmin: admin, isCoach: coach),
      createdAtUtc: DateTime.utc(2024, 6, 15),
    );

Group _group(int id, String name, {int ineligibleMemberCount = 0}) => Group(
  id: id,
  name: name,
  kind: GroupKind.semiAuto,
  ineligibleMemberCount: ineligibleMemberCount,
  createdAtUtc: DateTime.utc(2025),
);

/// Pumps the section for [_member] as [viewer]. [members] is what each
/// group's member list answers; reading one bumps [memberReads].
Future<void> _pump(
  WidgetTester tester, {
  required UserPrivate viewer,
  required List<Group> groups,
  Map<int, List<GroupMember>> members = const {},
  List<int>? memberReads,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _Auth(viewer)),
        clUserPrivateProvider(
          _member,
        ).overrideWith((_) async => _user(_member)),
        clUserGroupsProvider(_member).overrideWith((_) async => groups),
        clGroupMembersProvider.overrideWith((ref, id) async {
          memberReads?.add(id);
          return members[id] ?? const [];
        }),
        clGroupsMasterProvider.overrideWith(
          () => _Groups({for (final g in groups) g.id: g}),
        ),
        for (final g in groups)
          groupImageProvider(g.id).overrideWith((ref) async => null),
      ],
      child: const ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UserGroupsSection(username: _member),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _cardOf(String name) => find.ancestor(
  of: find.text(name),
  matching: find.byType(GroupCard),
);

const _flagged = [
  GroupMember(membername: 'workflow_other'),
  GroupMember(membername: _member, eligible: false),
];

void main() {
  group("Issue 43: the Groups section on a member's profile", () {
    testWidgets('Issue 43: a group the member no longer matches carries the '
        'outlined label; a group the member matches has none', (tester) async {
      await _pump(
        tester,
        viewer: _user('workflow_admin', admin: true),
        groups: [
          _group(1, 'Seniors'),
          _group(2, 'Juniors', ineligibleMemberCount: 1),
        ],
        members: {2: _flagged},
      );

      expect(find.byType(NoLongerEligibleLabel), findsOneWidget);
      final label = find.descendant(
        of: _cardOf('Juniors'),
        matching: find.byType(NoLongerEligibleLabel),
      );
      expect(label, findsOneWidget);
      expect(
        find.descendant(
          of: label,
          matching: find.text(NoLongerEligibleLabel.text),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _cardOf('Seniors'),
          matching: find.byType(NoLongerEligibleLabel),
        ),
        findsNothing,
      );
    });

    testWidgets('Issue 43: such groups come first and are counted above the '
        'rows', (tester) async {
      await _pump(
        tester,
        viewer: _user('workflow_admin', admin: true),
        groups: [
          _group(1, 'Seniors'),
          _group(2, 'Juniors', ineligibleMemberCount: 1),
          _group(3, 'Veterans'),
          _group(4, 'Minis', ineligibleMemberCount: 3),
        ],
        members: {2: _flagged, 4: _flagged},
      );

      final ids = tester
          .widgetList<GroupCard>(find.byType(GroupCard))
          .map((c) => c.groupId)
          .toList();
      expect(ids, [2, 4, 1, 3]);
      final count = find.text('2 groups no longer match this member');
      expect(count, findsOneWidget);
      expect(
        tester.getTopLeft(count).dy,
        lessThan(tester.getTopLeft(find.text('Juniors')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Juniors')).dy,
        lessThan(tester.getTopLeft(find.text('Seniors')).dy),
      );
    });

    testWidgets('Issue 43: one such group reads in the singular', (
      tester,
    ) async {
      await _pump(
        tester,
        viewer: _user('workflow_coach', coach: true),
        groups: [_group(2, 'Juniors', ineligibleMemberCount: 1)],
        members: {2: _flagged},
      );

      expect(
        find.text('1 group no longer matches this member'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 43: a group whose ineligible member is someone else '
        'is not marked, and nothing is counted', (tester) async {
      await _pump(
        tester,
        viewer: _user('workflow_admin', admin: true),
        groups: [_group(2, 'Juniors', ineligibleMemberCount: 1)],
        members: {
          2: const [
            GroupMember(membername: 'workflow_other', eligible: false),
            GroupMember(membername: _member),
          ],
        },
      );

      expect(find.byType(NoLongerEligibleLabel), findsNothing);
      expect(find.textContaining('no longer match'), findsNothing);
    });

    testWidgets("Issue 43: a member's own view reads no member list and "
        'shows no mark', (tester) async {
      final reads = <int>[];
      await _pump(
        tester,
        viewer: _user(_member),
        groups: [_group(2, 'Juniors', ineligibleMemberCount: 1)],
        members: {2: _flagged},
        memberReads: reads,
      );

      expect(find.text('Juniors'), findsOneWidget);
      expect(reads, isEmpty);
      expect(find.byType(NoLongerEligibleLabel), findsNothing);
      expect(find.textContaining('no longer match'), findsNothing);
    });
  });
}
