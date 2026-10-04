import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

class _FakeUsersSource extends Fake implements UserSource {
  _FakeUsersSource(this.items);

  final List<UserInfo> items;
  final List<UserStatus?> statusesAsked = [];

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
    statusesAsked.add(status);
    final matching = items.where((u) => u.status == status).toList();
    return PaginatedList<UserInfo>(
      items: matching,
      total: matching.length,
      offset: offset,
      limit: limit,
    );
  }
}

UserInfo _u(String username, UserStatus status, {UserRoles? roles}) => UserInfo(
  username: username,
  displayName: username,
  status: status,
  isSuperAdmin: false,
  roles: roles ?? const UserRoles(),
);

ProviderContainer _container(_FakeUsersSource users, UserInfo viewer) {
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWith((ref) => viewer),
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(users: users),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Issue 91: clRegisteredUsersProvider', () {
    final users = [
      _u('active1', UserStatus.active),
      _u('reg1', UserStatus.registered),
      _u('reg2', UserStatus.registered),
    ];

    test('asks the server for registered users only', () async {
      final source = _FakeUsersSource(users);
      final container = _container(
        source,
        _u('admin1', UserStatus.active, roles: const UserRoles(isAdmin: true)),
      );

      final got = await container.read(clRegisteredUsersProvider.future);

      expect(got.map((u) => u.username), ['reg1', 'reg2']);
      expect(source.statusesAsked, everyElement(UserStatus.registered));
    });

    test('a coach may see them too', () async {
      final source = _FakeUsersSource(users);
      final container = _container(
        source,
        _u('coach1', UserStatus.active, roles: const UserRoles(isCoach: true)),
      );

      final got = await container.read(clRegisteredUsersProvider.future);

      expect(got, hasLength(2));
    });

    test('a member gets none, and nothing is fetched', () async {
      final source = _FakeUsersSource(users);
      final container = _container(source, _u('m1', UserStatus.active));

      final got = await container.read(clRegisteredUsersProvider.future);

      expect(got, isEmpty);
      expect(source.statusesAsked, isEmpty);
    });
  });
}
