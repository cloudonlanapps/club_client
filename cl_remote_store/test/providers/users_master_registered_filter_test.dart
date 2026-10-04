import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

class _FakeUsersSource extends Fake implements UserSource {
  _FakeUsersSource(this.items);

  final List<UserInfo> items;

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
    return PaginatedList<UserInfo>(
      items: items,
      total: items.length,
      offset: offset,
      limit: limit,
    );
  }
}

SecureClient _buildClient(UserSource users) {
  return fakeSecureClient(
    users: users,
  );
}

UserInfo _u(String username, UserStatus status) => UserInfo(
  username: username,
  displayName: username,
  status: status,
  isSuperAdmin: false,
  roles: const UserRoles(),
);

UserPrivate _admin() => UserPrivate(
  username: 'admin1',
  displayName: 'Admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

void main() {
  test(
    'Issue 402: clUsersMasterProvider filters out registered users for admins',
    () async {
      final users = _FakeUsersSource([
        _u('active1', UserStatus.active),
        _u('pending1', UserStatus.pending),
        _u('reg1', UserStatus.registered),
        _u('blocked1', UserStatus.blocked),
        _u('left1', UserStatus.left),
        _u('reg2', UserStatus.registered),
      ]);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => _admin()),
          secureClientProvider.overrideWith((ref) async => _buildClient(users)),
        ],
      );
      addTearDown(container.dispose);

      final map = await container.read(clUsersMasterProvider.future);

      expect(
        map.keys.toSet(),
        {'active1', 'pending1', 'blocked1', 'left1'},
      );
      expect(map.containsKey('reg1'), isFalse);
      expect(map.containsKey('reg2'), isFalse);
    },
  );
}
