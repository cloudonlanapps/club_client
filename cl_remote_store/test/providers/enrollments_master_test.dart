import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

class _FakeEnrollments extends Fake implements EnrollmentSource {
  final Map<String, EnrollmentStatus> store = {};
  int listCalls = 0;
  int assignCalls = 0;
  int assignBulkCalls = 0;
  int inviteCalls = 0;
  int inviteBulkCalls = 0;
  int removeCalls = 0;

  @override
  Future<Map<String, EnrollmentStatus>> listEnrollments(
    int eventId, {
    EnrollmentStatus? status,
  }) async {
    listCalls++;
    return Map<String, EnrollmentStatus>.from(store);
  }

  @override
  Future<void> assign(int eventId, String username) async {
    assignCalls++;
    store[username] = EnrollmentStatus.assigned;
  }

  @override
  Future<void> assignBulk(int eventId, List<String> usernames) async {
    assignBulkCalls++;
    for (final u in usernames) {
      store[u] = EnrollmentStatus.assigned;
    }
  }

  @override
  Future<void> invite(int eventId, String username) async {
    inviteCalls++;
    store[username] = EnrollmentStatus.invited;
  }

  @override
  Future<void> inviteBulk(int eventId, List<String> usernames) async {
    inviteBulkCalls++;
    for (final u in usernames) {
      store[u] = EnrollmentStatus.invited;
    }
  }

  @override
  Future<void> removeEnrollment(
    int eventId,
    String username, {
    CreditDisposition? creditDisposition,
    String? reason,
  }) async {
    removeCalls++;
    store.remove(username);
  }
}

SecureClient _buildClient(EnrollmentSource enrollments) {
  return fakeSecureClient(
    enrollments: enrollments,
  );
}

ProviderContainer _makeContainer(EnrollmentSource enrollments) {
  return ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => _buildClient(enrollments),
      ),
    ],
  );
}

void main() {
  const eventId = 42;

  test(
    'Issue 536: assign() invalidates state — next read sees the new enrollment',
    () async {
      final fake = _FakeEnrollments();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final initial = await container.read(
        clEnrollmentsMasterProvider(eventId).future,
      );
      expect(initial, isEmpty);
      expect(fake.listCalls, 1);

      await container
          .read(clEnrollmentsMasterProvider(eventId).notifier)
          .assign('alice');

      expect(fake.assignCalls, 1);

      final after = await container.read(
        clEnrollmentsMasterProvider(eventId).future,
      );
      expect(after, {'alice': EnrollmentStatus.assigned});
      expect(
        fake.listCalls,
        2,
        reason: 'invalidateSelf should have triggered a re-fetch',
      );
    },
  );

  test(
    'Issue 536: assignBulk() invalidates state — next read sees all new '
    'enrollments',
    () async {
      final fake = _FakeEnrollments();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(clEnrollmentsMasterProvider(eventId).future);

      await container
          .read(clEnrollmentsMasterProvider(eventId).notifier)
          .assignBulk(['alice', 'bob']);

      expect(fake.assignBulkCalls, 1);

      final after = await container.read(
        clEnrollmentsMasterProvider(eventId).future,
      );
      expect(after, {
        'alice': EnrollmentStatus.assigned,
        'bob': EnrollmentStatus.assigned,
      });
      expect(fake.listCalls, 2);
    },
  );

  test(
    'Issue 536: invite() invalidates state — next read reflects invited status',
    () async {
      final fake = _FakeEnrollments();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(clEnrollmentsMasterProvider(eventId).future);

      await container
          .read(clEnrollmentsMasterProvider(eventId).notifier)
          .invite('alice');

      final after = await container.read(
        clEnrollmentsMasterProvider(eventId).future,
      );
      expect(after, {'alice': EnrollmentStatus.invited});
      expect(fake.inviteCalls, 1);
      expect(fake.listCalls, 2);
    },
  );

  test(
    'Issue 536: removeEnrollment() invalidates state — next read no longer '
    'lists the user',
    () async {
      final fake = _FakeEnrollments()
        ..store['alice'] = EnrollmentStatus.assigned
        ..store['bob'] = EnrollmentStatus.assigned;
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final initial = await container.read(
        clEnrollmentsMasterProvider(eventId).future,
      );
      expect(initial.keys, ['alice', 'bob']);

      await container
          .read(clEnrollmentsMasterProvider(eventId).notifier)
          .removeEnrollment('alice');

      final after = await container.read(
        clEnrollmentsMasterProvider(eventId).future,
      );
      expect(after, {'bob': EnrollmentStatus.assigned});
      expect(fake.removeCalls, 1);
      expect(fake.listCalls, 2);
    },
  );

  test(
    'Issue 540: assign() awaits the refetch — synchronous read after await '
    'sees the new enrollment (no flash of pre-mutation state)',
    () async {
      final fake = _FakeEnrollments();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(clEnrollmentsMasterProvider(eventId).future);
      expect(fake.listCalls, 1);

      await container
          .read(clEnrollmentsMasterProvider(eventId).notifier)
          .assign('alice');

      // Synchronous read — must already reflect the mutation, not the cached
      // pre-mutation map.
      final sync = container
          .read(clEnrollmentsMasterProvider(eventId))
          .valueOrNull;
      expect(
        sync,
        isNotNull,
        reason:
            'state must be AsyncData (refetch already settled), not '
            'AsyncLoading',
      );
      expect(sync, {'alice': EnrollmentStatus.assigned});
      expect(
        fake.listCalls,
        2,
        reason: 'refetch must complete before mutation future resolves',
      );
    },
  );

  test(
    'Issue 536: clManualRefreshProvider bump re-fetches via build()',
    () async {
      final fake = _FakeEnrollments();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(clEnrollmentsMasterProvider(eventId).future);
      expect(fake.listCalls, 1);

      fake.store['alice'] = EnrollmentStatus.assigned;
      container.read(clManualRefreshProvider.notifier).state++;

      final after = await container.read(
        clEnrollmentsMasterProvider(eventId).future,
      );
      expect(after, {'alice': EnrollmentStatus.assigned});
      expect(fake.listCalls, 2);
    },
  );
}
