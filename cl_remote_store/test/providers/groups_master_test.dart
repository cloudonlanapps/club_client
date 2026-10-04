import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

class _FakeGroups extends Fake implements GroupSource {
  _FakeGroups({
    this.activeGroups = const [],
    this.deletedGroups = const [],
  });

  final Set<String> members = {};
  final Map<int, JoinRequest> requests = {};
  int getMembersCalls = 0;
  int addMemberCalls = 0;
  int removeMemberCalls = 0;
  int addBulkCalls = 0;
  int approveRequestCalls = 0;

  /// Groups returned by `getGroups` (admin/coach). The deleted set models the
  /// admin-only `/groups/deleted`, which 403s for non-admins on the server.
  final List<Group> activeGroups;
  final List<Group> deletedGroups;
  int getGroupsCalls = 0;
  int getDeletedGroupsCalls = 0;

  GroupMember _member(String username) => GroupMember(membername: username);

  @override
  Future<List<GroupMember>> getMembers(
    int groupId, {
    String? sortBy,
    bool descending = false,
  }) async {
    getMembersCalls++;
    return members.map(_member).toList();
  }

  @override
  Future<void> addMember(int groupId, String username) async {
    addMemberCalls++;
    members.add(username);
  }

  @override
  Future<void> removeMember(int groupId, String username) async {
    removeMemberCalls++;
    members.remove(username);
  }

  @override
  Future<BulkMembersResult> addMembersBulk(
    int groupId,
    List<String> membernames,
  ) async {
    addBulkCalls++;
    members.addAll(membernames);
    return BulkMembersResult(
      added: membernames,
      alreadyMembers: const [],
      notFound: const [],
      notEligible: const [],
    );
  }

  @override
  Future<JoinRequest> approveRequest(int groupId, int requestId) async {
    approveRequestCalls++;
    final existing = requests[requestId]!;
    final approved = existing.copyWith(status: JoinRequestStatus.approved);
    requests[requestId] = approved;
    members.add(existing.username);
    return approved;
  }

  @override
  Future<List<JoinRequest>> listRequests(
    int groupId, {
    JoinRequestStatus? status,
  }) async {
    return requests.values.toList();
  }

  // Master-provider build() also calls getGroups/getDeletedGroups.
  @override
  Future<PaginatedList<Group>> getGroups({
    int offset = 0,
    int limit = 20,
  }) async {
    getGroupsCalls++;
    return PaginatedList<Group>(
      items: activeGroups,
      total: activeGroups.length,
      offset: 0,
      limit: limit,
    );
  }

  // Admin-only on the server: a coach session 403s here.
  @override
  Future<PaginatedList<Group>> getDeletedGroups({
    int offset = 0,
    int limit = 20,
  }) async {
    getDeletedGroupsCalls++;
    return PaginatedList<Group>(
      items: deletedGroups,
      total: deletedGroups.length,
      offset: 0,
      limit: limit,
    );
  }
}

Group _group(int id, {String? name, bool deleted = false}) => Group(
  id: id,
  name: name ?? 'group_$id',
  kind: GroupKind.manual,
  createdAtUtc: DateTime.utc(2026),
  deletedAtUtc: deleted ? DateTime.utc(2026, 2) : null,
);

UserInfo _userInfo(String username, {required UserRoles roles}) => UserInfo(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: roles,
);

SecureClient _buildClient(GroupSource groups) {
  return fakeSecureClient(
    groups: groups,
  );
}

ProviderContainer _makeContainer(GroupSource groups, {UserInfo? currentUser}) {
  return ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith((ref) async => _buildClient(groups)),
      currentUserProvider.overrideWith((ref) => currentUser),
    ],
  );
}

void main() {
  const groupId = 1;

  group('Issue 674: deleted-groups fetch is gated on the admin role', () {
    test(
      'Issue 674: a coach builds the master without calling the admin-only '
      'getDeletedGroups, and still gets the active groups',
      () async {
        final fake = _FakeGroups(activeGroups: [_group(1), _group(2)]);
        final container = _makeContainer(
          fake,
          currentUser: _userInfo(
            'coach',
            roles: const UserRoles(isCoach: true),
          ),
        );
        addTearDown(container.dispose);

        final map = await container.read(clGroupsMasterProvider.future);

        expect(
          map.keys,
          unorderedEquals([1, 2]),
          reason: 'coach must still see active groups',
        );
        expect(fake.getGroupsCalls, greaterThanOrEqualTo(1));
        expect(
          fake.getDeletedGroupsCalls,
          0,
          reason: 'coach must not call the admin-only /groups/deleted',
        );
      },
    );

    test(
      'Issue 674: an admin fetches both active and deleted groups into the map',
      () async {
        final fake = _FakeGroups(
          activeGroups: [_group(1)],
          deletedGroups: [_group(2, deleted: true)],
        );
        final container = _makeContainer(
          fake,
          currentUser: _userInfo(
            'admin',
            roles: const UserRoles(isAdmin: true),
          ),
        );
        addTearDown(container.dispose);

        final map = await container.read(clGroupsMasterProvider.future);

        expect(map.keys, unorderedEquals([1, 2]));
        expect(map[2]!.isActive, isFalse);
        expect(fake.getDeletedGroupsCalls, greaterThanOrEqualTo(1));
      },
    );

    test(
      'Issue 674: the master refetches the deleted set once the admin role '
      'lands (role transition recovers without a manual invalidate)',
      () async {
        final fake = _FakeGroups(
          activeGroups: [_group(1)],
          deletedGroups: [_group(2, deleted: true)],
        );
        // Start as a coach (the role the login race momentarily exposes).
        final coach = _userInfo('u', roles: const UserRoles(isCoach: true));
        final admin = _userInfo('u', roles: const UserRoles(isAdmin: true));
        var current = coach;
        final container = ProviderContainer(
          overrides: [
            secureClientProvider.overrideWith(
              (ref) async => _buildClient(fake),
            ),
            currentUserProvider.overrideWith((ref) => current),
          ],
        );
        addTearDown(container.dispose);
        final sub = container.listen(clGroupsMasterProvider, (_, _) {});
        addTearDown(sub.close);

        final first = await container.read(clGroupsMasterProvider.future);
        expect(first.keys, unorderedEquals([1]));
        expect(fake.getDeletedGroupsCalls, 0);

        // Admin role lands; the master watches currentUserProvider, so it
        // rebuilds and now pulls the deleted set in.
        current = admin;
        container.invalidate(currentUserProvider);
        final second = await container.read(clGroupsMasterProvider.future);
        expect(second.keys, unorderedEquals([1, 2]));
        expect(fake.getDeletedGroupsCalls, greaterThanOrEqualTo(1));
      },
    );
  });

  test(
    'Issue 540: addMember() awaits the clGroupMembersProvider refetch — '
    'synchronous read after await sees the new member',
    () async {
      final fake = _FakeGroups();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      // Pre-warm the members provider so it has a cached pre-mutation value.
      final sub = container.listen(clGroupMembersProvider(groupId), (_, _) {});
      addTearDown(sub.close);
      await container.read(clGroupMembersProvider(groupId).future);
      expect(fake.getMembersCalls, 1);

      await container
          .read(clGroupsMasterProvider.notifier)
          .addMember(groupId, 'alice');

      final sync = container.read(clGroupMembersProvider(groupId)).valueOrNull;
      expect(
        sync,
        isNotNull,
        reason:
            'clGroupMembersProvider must be settled (refetch awaited) before '
            'addMember future resolves',
      );
      expect(sync!.map((u) => u.membername), contains('alice'));
      expect(fake.getMembersCalls, 2);
    },
  );

  test(
    'Issue 540: removeMember() awaits the clGroupMembersProvider refetch',
    () async {
      final fake = _FakeGroups()..members.add('alice');
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final sub = container.listen(clGroupMembersProvider(groupId), (_, _) {});
      addTearDown(sub.close);
      final initial = await container.read(
        clGroupMembersProvider(groupId).future,
      );
      expect(initial.map((u) => u.membername), contains('alice'));

      await container
          .read(clGroupsMasterProvider.notifier)
          .removeMember(groupId, 'alice');

      final sync = container.read(clGroupMembersProvider(groupId)).valueOrNull;
      expect(sync, isNotNull);
      expect(sync!.map((u) => u.membername), isNot(contains('alice')));
      expect(fake.getMembersCalls, 2);
    },
  );

  test(
    'Issue 540: addMembersBulk() awaits the clGroupMembersProvider refetch',
    () async {
      final fake = _FakeGroups();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final sub = container.listen(clGroupMembersProvider(groupId), (_, _) {});
      addTearDown(sub.close);
      await container.read(clGroupMembersProvider(groupId).future);

      final result = await container
          .read(clGroupsMasterProvider.notifier)
          .addMembersBulk(groupId, ['alice', 'bob']);

      expect(result.added, ['alice', 'bob']);
      final sync = container.read(clGroupMembersProvider(groupId)).valueOrNull;
      expect(sync, isNotNull);
      expect(
        sync!.map((u) => u.membername).toSet(),
        containsAll(['alice', 'bob']),
      );
      expect(fake.getMembersCalls, 2);
    },
  );

  test(
    'Issue 540: ClGroupRequestsMasterNotifier.approve() awaits the '
    'clGroupMembersProvider refetch — approved user is visible in members on '
    'next synchronous read',
    () async {
      final fake = _FakeGroups()
        ..requests[100] = JoinRequest(
          id: 100,
          groupId: groupId,
          groupName: 'g',
          username: 'alice',
          status: JoinRequestStatus.pending,
          requestedAt: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
        );
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final sub = container.listen(clGroupMembersProvider(groupId), (_, _) {});
      addTearDown(sub.close);
      await container.read(clGroupMembersProvider(groupId).future);
      await container.read(clGroupRequestsMasterProvider(groupId).future);

      await container
          .read(clGroupRequestsMasterProvider(groupId).notifier)
          .approve(100);

      final members = container
          .read(clGroupMembersProvider(groupId))
          .valueOrNull;
      expect(
        members,
        isNotNull,
        reason: 'members list must be re-fetched before approve resolves',
      );
      expect(members!.map((u) => u.membername), contains('alice'));
      expect(fake.getMembersCalls, 2);
      expect(fake.approveRequestCalls, 1);
    },
  );
}
