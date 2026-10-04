import 'package:cl_club_members/cl_club_members.dart';
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

UserPrivate _viewer(String username) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
);

class _StubGroupsMasterNotifier extends ClGroupsMasterNotifier {
  _StubGroupsMasterNotifier(this._groups);
  final Map<int, Group> _groups;
  @override
  Future<Map<int, Group>> build() async => _groups;
}

class _StubMyGroupsMasterNotifier extends ClMyGroupsMasterNotifier {
  _StubMyGroupsMasterNotifier(this._groups);
  final List<Group> _groups;
  @override
  Future<List<Group>> build(String username) async => _groups;
}

class _StubMyJoinRequestsMasterNotifier extends ClMyJoinRequestsMasterNotifier {
  _StubMyJoinRequestsMasterNotifier(this._requests);
  final Map<int, JoinRequest> _requests;
  @override
  Future<Map<int, JoinRequest>> build(String username) async => _requests;
}

Group _group(int id, String name) => Group(
  id: id,
  name: name,
  kind: GroupKind.manual,
  createdAtUtc: DateTime.utc(2025),
);

JoinRequest _request({
  required int id,
  required int groupId,
  required JoinRequestStatus status,
  int requestedAt = 1,
}) => JoinRequest(
  id: id,
  groupId: groupId,
  groupName: 'G$groupId',
  username: 'u1',
  status: status,
  requestedAt: requestedAt,
);

Widget _wrap({
  required String username,
  required List<Group> eligible,
  required Map<int, JoinRequest> requests,
  List<Group> mine = const [],
  Map<int, Group> all = const {},
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(
        () => _StubAuthNotifier(_viewer(username)),
      ),
      clGroupsMasterProvider.overrideWith(() => _StubGroupsMasterNotifier(all)),
      // GroupCard now resolves a list image via groupImageProvider; stub it so
      // the card doesn't reach secureClientProvider (#711).
      groupImageProvider.overrideWith((ref, id) async => null),
      clMyGroupsMasterProvider.overrideWith(
        () => _StubMyGroupsMasterNotifier(mine),
      ),
      clMyEligibleGroupsProvider(
        username,
      ).overrideWith((ref) async => eligible),
      clMyJoinRequestsMasterProvider.overrideWith(
        () => _StubMyJoinRequestsMasterNotifier(requests),
      ),
    ],
    child: ShadApp(
      home: Scaffold(body: MyGroupsView(username: username)),
    ),
  );
}

Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets(
    'Issue 517: cancelled-only history renders one joinable card without '
    'a "Cancelled" caption',
    (tester) async {
      final g = _group(10, 'Alpha');
      await tester.pumpWidget(
        _wrap(
          username: 'u1',
          eligible: [g],
          all: {10: g},
          requests: {
            1: _request(
              id: 1,
              groupId: 10,
              status: JoinRequestStatus.cancelled,
            ),
          },
        ),
      );
      await _pump(tester);

      expect(find.byKey(const ValueKey('joinable-10')), findsOneWidget);
      expect(find.byKey(const ValueKey('request-1')), findsNothing);
      expect(
        find.text('Cancelled'),
        findsNothing,
        reason:
            'a cancelled-only history must not caption the joinable '
            'card with "Cancelled"',
      );
    },
  );

  testWidgets(
    'Issue 517: pending request renders as request card, not joinable',
    (tester) async {
      final g = _group(10, 'Alpha');
      await tester.pumpWidget(
        _wrap(
          username: 'u1',
          // Real server contract: the pending group is still in eligible,
          // flagged requested=true.
          eligible: [g.copyWith(requested: true)],
          all: {10: g},
          requests: {
            1: _request(id: 1, groupId: 10, status: JoinRequestStatus.pending),
          },
        ),
      );
      await _pump(tester);

      expect(find.byKey(const ValueKey('joinable-10')), findsNothing);
      expect(find.byKey(const ValueKey('request-1')), findsOneWidget);
      expect(
        find.textContaining('pending', findRichText: true),
        findsWidgets,
        reason: 'pending caption should be present on the request card',
      );
    },
  );

  testWidgets(
    'Issue 517: mixed pending + cancelled across two groups renders one '
    'card each, not four',
    (tester) async {
      final a = _group(10, 'Alpha'); // pending
      final b = _group(20, 'Bravo'); // cancelled (back in eligible)
      await tester.pumpWidget(
        _wrap(
          username: 'u1',
          // Real server contract: a pending group is in eligible flagged
          // requested=true; a terminal (cancelled) group is in eligible with
          // requested=false.
          eligible: [a.copyWith(requested: true), b],
          all: {10: a, 20: b},
          requests: {
            1: _request(id: 1, groupId: 10, status: JoinRequestStatus.pending),
            2: _request(
              id: 2,
              groupId: 20,
              status: JoinRequestStatus.cancelled,
            ),
          },
        ),
      );
      await _pump(tester);

      expect(find.byKey(const ValueKey('request-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('joinable-20')), findsOneWidget);
      expect(find.byKey(const ValueKey('joinable-10')), findsNothing);
      expect(find.byKey(const ValueKey('request-2')), findsNothing);
    },
  );

  testWidgets(
    'Issue 649: a pending request whose group is still returned in the '
    'eligible list (server flags requested=true) renders one request card, '
    'not also a joinable card',
    (tester) async {
      final g = _group(10, 'Alpha');
      await tester.pumpWidget(
        _wrap(
          username: 'u1',
          // Real server contract: list_eligible_groups returns a group with a
          // pending request flagged requested=true — it does NOT exclude it.
          eligible: [g.copyWith(requested: true)],
          all: {10: g},
          requests: {
            1: _request(id: 1, groupId: 10, status: JoinRequestStatus.pending),
          },
        ),
      );
      await _pump(tester);

      expect(find.byKey(const ValueKey('request-1')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('joinable-10')),
        findsNothing,
        reason:
            'Issue 649: a group with a pending request must not also '
            'render as a joinable card',
      );
    },
  );
}
