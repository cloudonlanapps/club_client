// A row written while its master is loading is in the master once the load
// ends (club_client#137). Each test holds the master's first listing back,
// writes, then lets the listing through with no rows.
import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_evaluation_sources.dart';
import '../support/fake_secure_client.dart';

PaginatedList<T> _noRows<T>(int limit) =>
    PaginatedList<T>(items: const [], total: 0, offset: 0, limit: limit);

class _Venues extends Fake implements VenueSource {
  final gate = Completer<void>();

  @override
  Future<PaginatedList<Venue>> getVenues({
    int offset = 0,
    int limit = 20,
  }) async {
    await gate.future;
    return _noRows(limit);
  }
}

class _Groups extends Fake implements GroupSource {
  final gate = Completer<void>();

  @override
  Future<PaginatedList<Group>> getGroups({
    int offset = 0,
    int limit = 20,
  }) async {
    await gate.future;
    return _noRows(limit);
  }

  @override
  Future<List<JoinRequest>> listRequests(
    int groupId, {
    JoinRequestStatus? status,
  }) async {
    await gate.future;
    return const [];
  }

  @override
  Future<JoinRequest> rejectRequest(
    int groupId,
    int requestId, {
    String? reason,
  }) async => _request(requestId, JoinRequestStatus.rejected);
}

class _Users extends Fake implements UserSource {
  final gate = Completer<void>();

  @override
  Future<PaginatedList<UserInfo>> getUsers({
    int offset = 0,
    int limit = 20,
    UserStatus? status,
    String? role,
    int? minAge,
    int? maxAge,
    String? searchTerm,
    String? sortBy,
    bool descending = false,
  }) async {
    await gate.future;
    return _noRows(limit);
  }
}

class _MyGroups extends Fake implements MyGroupsSource {
  final gate = Completer<void>();

  @override
  Future<List<JoinRequest>> listMyRequests(String username) async {
    await gate.future;
    return const [];
  }
}

JoinRequest _request(int id, JoinRequestStatus status) => JoinRequest(
  id: id,
  groupId: 7,
  groupName: 'g',
  username: 'alice',
  status: status,
  requestedAt: DateTime.utc(2026).millisecondsSinceEpoch,
);

UserPrivate _admin() => UserPrivate(
  username: 'admin1',
  displayName: 'Admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

ProviderContainer _container(SecureClient client, {UserPrivate? user}) {
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWith((ref) => user),
      secureClientProvider.overrideWith((ref) async => client),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('Issue 137: a venue written during the first load of the venues '
      'master is in it once it loads', () async {
    final venues = _Venues();
    final c = _container(fakeSecureClient(venues: venues));
    final load = c.read(clVenuesMasterProvider.future);
    await pumpEventQueue();

    c
        .read(clVenuesMasterProvider.notifier)
        .replaceLocally(
          Venue(
            id: 1,
            name: 'v',
            createdAtUtc: DateTime.utc(2026),
            updatedAtUtc: DateTime.utc(2026),
          ),
        );
    venues.gate.complete();

    expect((await load).keys, [1]);
  });

  test('Issue 137: a group written during the first load of the groups '
      'master is in it once it loads', () async {
    final groups = _Groups();
    final c = _container(fakeSecureClient(groups: groups));
    final load = c.read(clGroupsMasterProvider.future);
    await pumpEventQueue();

    c
        .read(clGroupsMasterProvider.notifier)
        .replaceLocally(
          Group(
            id: 1,
            name: 'g',
            kind: GroupKind.manual,
            createdAtUtc: DateTime.utc(2026),
          ),
        );
    groups.gate.complete();

    expect((await load).keys, [1]);
  });

  test('Issue 137: a user written during the first load of the users master '
      'is in it once it loads, and one removed is not', () async {
    final users = _Users();
    final c = _container(fakeSecureClient(users: users), user: _admin());
    final load = c.read(clUsersMasterProvider.future);
    await pumpEventQueue();

    UserInfo user(String username) => UserInfo(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: const UserRoles(),
    );
    c.read(clUsersMasterProvider.notifier)
      ..replaceLocally(user('alice'))
      ..replaceLocally(user('bob'))
      ..removeLocally('bob');
    users.gate.complete();

    expect((await load).keys, ['alice']);
  });

  test('Issue 137: a join request written during the first load of the '
      "member's requests is in them once they load", () async {
    final myGroups = _MyGroups();
    final c = _container(fakeSecureClient(myGroups: myGroups));
    final load = c.read(clMyJoinRequestsMasterProvider('alice').future);
    await pumpEventQueue();

    c
        .read(clMyJoinRequestsMasterProvider('alice').notifier)
        .replaceLocally(_request(100, JoinRequestStatus.pending));
    myGroups.gate.complete();

    expect((await load).keys, [100]);
  });

  test('Issue 137: a request rejected during the first load of the '
      "group's requests is in them, rejected, once they load", () async {
    final groups = _Groups();
    final c = _container(fakeSecureClient(groups: groups));
    final load = c.read(clGroupRequestsMasterProvider(7).future);
    await pumpEventQueue();

    await c.read(clGroupRequestsMasterProvider(7).notifier).reject(100);
    groups.gate.complete();

    expect((await load)[100]?.status, JoinRequestStatus.rejected);
  });

  // The evaluation masters are held back at the client, which their load
  // waits for before it lists.
  ProviderContainer evaluationContainer(Completer<void> gate) {
    final container = ProviderContainer(
      overrides: [
        evaluationsProvider.overrideWithValue(true),
        secureClientProvider.overrideWith((ref) async {
          await gate.future;
          return fakeSecureClient(evaluations: FakeEvaluations());
        }),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('Issue 137: an evaluation written during the first load of the '
      'evaluations master is in it once it loads, and one removed is '
      'not', () async {
    final gate = Completer<void>();
    final c = evaluationContainer(gate);
    final load = c.read(clEvaluationsMasterProvider.future);
    await pumpEventQueue();

    c.read(clEvaluationsMasterProvider.notifier)
      ..replaceLocally(fakeStaffView(1))
      ..replaceLocally(fakeStaffView(2))
      ..removeLocally(2);
    gate.complete();

    expect((await load).keys, [1]);
  });

  test('Issue 137: a template written during the first load of the '
      'templates master is in it once it loads', () async {
    final gate = Completer<void>();
    final c = evaluationContainer(gate);
    final load = c.read(clEvaluationTemplatesMasterProvider.future);
    await pumpEventQueue();

    c
        .read(clEvaluationTemplatesMasterProvider.notifier)
        .replaceLocally(fakeTemplate(1));
    gate.complete();

    expect((await load).keys, [1]);
  });
}
