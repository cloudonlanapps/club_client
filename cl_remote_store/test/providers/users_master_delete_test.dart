import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

final _deletedAt = DateTime.utc(2026, 10, 22, 6);

UserInfo _u(String username, {DateTime? deletedAtUtc, UserRoles? roles}) =>
    UserInfo(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: roles ?? const UserRoles(),
      deletedAtUtc: deletedAtUtc,
    );

/// Lists one member; DELETE answers with that member soft-deleted. Any
/// GET of a single user fails, as a 503 would.
class _FakeUsersSource extends Fake implements UserSource {
  int getUserInfoCalls = 0;

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
    final items = [_u('member1')];
    return PaginatedList<UserInfo>(
      items: items,
      total: items.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<UserInfo> deleteUser(String username) async =>
      _u(username, deletedAtUtc: _deletedAt);

  @override
  Future<UserPrivate> getUserInfo(String username) async {
    getUserInfoCalls++;
    throw Exception('503 Service Unavailable');
  }
}

void main() {
  test(
    'Issue 236: deleteUser stores the returned user with deletedAtUtc set '
    'and makes no getUserInfo call',
    () async {
      final source = _FakeUsersSource();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => _u('admin1', roles: const UserRoles(isAdmin: true)),
          ),
          secureClientProvider.overrideWith(
            (ref) async => fakeSecureClient(users: source),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(clUsersMasterProvider.future);
      await container
          .read(clUsersMasterProvider.notifier)
          .deleteUser('member1');

      final users = container.read(clUsersMasterProvider).requireValue;
      expect(users['member1'], isNotNull);
      expect(users['member1']!.deletedAtUtc, _deletedAt);
      expect(source.getUserInfoCalls, 0);
    },
  );
}
