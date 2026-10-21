// A failed optimistic write undoes only its own change, in the state as it
// is when the failure arrives, so a change that completed meanwhile stays
// (club_client#235).
import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// A definite refusal: the write did not land, so nothing is refetched.
const _refused = ServerException(
  statusCode: 409,
  code: 'conflict',
  message: 'refused',
);

AppNotification _notification(int id) => AppNotification(
  id: id,
  username: 'admin1',
  type: 'broadcast.text',
  channel: NotificationChannel.inApp,
  payload: const <String, dynamic>{},
  isRead: false,
  createdAtUtc: DateTime.utc(2026, 9),
);

/// Each write waits on its own gate; a gate completed with an error fails
/// that write.
class _Notifications extends Fake implements NotificationSource {
  final Map<String, Completer<void>> gates = {};

  Completer<void> gate(String call) => gates.putIfAbsent(call, Completer.new);

  @override
  Future<PaginatedList<AppNotification>> getNotifications({
    int offset = 0,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final items = [_notification(1), _notification(2), _notification(3)];
    return PaginatedList(
      items: offset == 0 ? items : const [],
      total: items.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<void> markRead(int id) => gate('markRead($id)').future;

  @override
  Future<void> markAllRead() => gate('markAllRead').future;

  @override
  Future<void> deleteNotification(int id) => gate('delete($id)').future;
}

UserInfo _user(String username, {bool coach = false}) => UserInfo(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isMember: true, isCoach: coach),
);

class _Users extends Fake implements UserSource {
  final blockGate = Completer<UserInfo>();

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
    final items = [_user('bob')];
    return PaginatedList(
      items: offset == 0 ? items : const [],
      total: items.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<UserInfo> blockUser(String username, {String? resolutionReason}) =>
      blockGate.future;

  @override
  Future<UserInfo> assignRole(String username, String role) async =>
      _user(username, coach: true);
}

final _admin = UserPrivate(
  username: 'admin1',
  displayName: 'Admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

ProviderContainer _container(SecureClient client) {
  final c = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWith((ref) => _admin),
      secureClientProvider.overrideWith((ref) async => client),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('Issue 235: notifications', () {
    late _Notifications source;
    late ProviderContainer c;
    late ClNotificationsMasterNotifier notifier;

    Map<int, AppNotification> feed() =>
        c.read(clNotificationsMasterProvider).requireValue;

    setUp(() async {
      source = _Notifications();
      c = _container(fakeSecureClient(notifications: source));
      final sub = c.listen(clNotificationsMasterProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(clNotificationsMasterProvider.future);
      notifier = c.read(clNotificationsMasterProvider.notifier);
    });

    test('Issue 235: two overlapping markRead calls, the first fails: the '
        'second stays read', () async {
      final first = notifier.markRead(1);
      final second = notifier.markRead(2);
      source.gate('markRead(2)').complete();
      await second;
      source.gate('markRead(1)').completeError(_refused);
      await expectLater(first, throwsA(isA<ServerException>()));

      expect(feed()[1]!.isRead, isFalse);
      expect(feed()[2]!.isRead, isTrue);
    });

    test('Issue 235: a markAllRead that fails keeps a delete that completed '
        'meanwhile', () async {
      final all = notifier.markAllRead();
      final delete = notifier.deleteNotification(3);
      source.gate('delete(3)').complete();
      await delete;
      source.gate('markAllRead').completeError(_refused);
      await expectLater(all, throwsA(isA<ServerException>()));

      expect(feed().keys, unorderedEquals([1, 2]));
      expect(feed().values.every((n) => !n.isRead), isTrue);
    });

    test('Issue 235: a delete that fails keeps a markRead that completed '
        'meanwhile', () async {
      final delete = notifier.deleteNotification(1);
      final read = notifier.markRead(2);
      source.gate('markRead(2)').complete();
      await read;
      source.gate('delete(1)').completeError(_refused);
      await expectLater(delete, throwsA(isA<ServerException>()));

      expect(feed().keys, unorderedEquals([1, 2, 3]));
      expect(feed()[2]!.isRead, isTrue);
    });
  });

  test('Issue 235: a block that fails keeps a role assigned meanwhile, and '
      'only its status is undone', () async {
    final users = _Users();
    final c = _container(fakeSecureClient(users: users));
    final sub = c.listen(clUsersMasterProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(clUsersMasterProvider.future);
    final notifier = c.read(clUsersMasterProvider.notifier);

    final block = notifier.blockUser('bob');
    await notifier.assignRole('bob', 'coach');
    users.blockGate.completeError(_refused);
    await expectLater(block, throwsA(isA<ServerException>()));

    final bob = c.read(clUsersMasterProvider).requireValue['bob']!;
    expect(bob.roles.isCoach, isTrue);
    expect(bob.status, UserStatus.active);
  });
}
