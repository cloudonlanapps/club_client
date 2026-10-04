import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

class _FakeAttendance extends Fake implements AttendanceSource {
  final Map<String, AttendanceStatus> store = {};
  int getCalls = 0;
  int markCalls = 0;
  int clearCalls = 0;
  int approveLeaveCalls = 0;

  AttendanceRecord _toRecord(String username, AttendanceStatus status) {
    return AttendanceRecord(
      id: username.hashCode,
      occurrenceId: 1,
      membername: username,
      status: status,
      recordedAtUtc: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc,
  ) async {
    getCalls++;
    return store.entries.map((e) => _toRecord(e.key, e.value)).toList();
  }

  @override
  Future<AttendanceMarkReport> markAttendance(
    int eventId,
    DateTime occurrenceTimeUtc,
    List<AttendanceMarkRecord> records,
  ) async {
    markCalls++;
    for (final r in records) {
      store[r.membername] = r.status;
    }
    // No credit system behind this fake, so nobody is ever refused.
    return AttendanceMarkReport(
      marked: records
          .map(
            (r) => MarkedAttendance(
              membername: r.membername,
              status: r.status,
            ),
          )
          .toList(),
      refused: const [],
    );
  }

  @override
  Future<void> clearAttendance(
    int eventId,
    String username,
    DateTime occurrenceTimeUtc,
  ) async {
    clearCalls++;
    store.remove(username);
  }

  @override
  Future<void> approveLeave(
    int eventId,
    String username,
    DateTime occurrenceTimeUtc,
  ) async {
    approveLeaveCalls++;
    store[username] = AttendanceStatus.onLeave;
  }
}

SecureClient _buildClient(AttendanceSource attendance) {
  return fakeSecureClient(
    attendance: attendance,
  );
}

ProviderContainer _makeContainer(AttendanceSource attendance) {
  return ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => _buildClient(attendance),
      ),
    ],
  );
}

void main() {
  final key = (eventId: 1, occurrenceTimeUtc: DateTime.utc(2026, 1, 1));

  test(
    'Issue 536: markAttendance() invalidates state — next read sees the new '
    'records',
    () async {
      final fake = _FakeAttendance();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final initial = await container.read(
        clAttendancesMasterProvider(key).future,
      );
      expect(initial, isEmpty);
      expect(fake.getCalls, 1);

      await container
          .read(clAttendancesMasterProvider(key).notifier)
          .markAttendance([
            const AttendanceMarkRecord(
              membername: 'alice',
              status: AttendanceStatus.present,
            ),
          ]);

      expect(fake.markCalls, 1);

      final after = await container.read(
        clAttendancesMasterProvider(key).future,
      );
      expect(after, hasLength(1));
      expect(after.first.membername, 'alice');
      expect(after.first.status, AttendanceStatus.present);
      expect(
        fake.getCalls,
        2,
        reason: 'invalidateSelf should have triggered a re-fetch',
      );
    },
  );

  test(
    'Issue 536: approveLeave() invalidates state — next read reflects onLeave '
    'status',
    () async {
      final fake = _FakeAttendance()
        ..store['alice'] = AttendanceStatus.onLeaveRequested;
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final initial = await container.read(
        clAttendancesMasterProvider(key).future,
      );
      expect(initial.first.status, AttendanceStatus.onLeaveRequested);

      await container
          .read(clAttendancesMasterProvider(key).notifier)
          .approveLeave('alice');

      final after = await container.read(
        clAttendancesMasterProvider(key).future,
      );
      expect(after.first.status, AttendanceStatus.onLeave);
      expect(fake.approveLeaveCalls, 1);
      expect(fake.getCalls, 2);
    },
  );

  test(
    'Issue 540: markAttendance() awaits the refetch — synchronous read after '
    'await sees the new records (no flash of pre-mutation state)',
    () async {
      final fake = _FakeAttendance();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(clAttendancesMasterProvider(key).future);
      expect(fake.getCalls, 1);

      await container
          .read(clAttendancesMasterProvider(key).notifier)
          .markAttendance([
            const AttendanceMarkRecord(
              membername: 'alice',
              status: AttendanceStatus.present,
            ),
          ]);

      // Synchronous read — must already reflect the mutation, not the cached
      // pre-mutation value. This is what a widget watching the provider would
      // see on its next rebuild after the mutation's await resolves.
      final sync = container.read(clAttendancesMasterProvider(key)).valueOrNull;
      expect(
        sync,
        isNotNull,
        reason:
            'state must be AsyncData (refetch already settled), not '
            'AsyncLoading',
      );
      expect(sync, hasLength(1));
      expect(sync!.first.status, AttendanceStatus.present);
      expect(
        fake.getCalls,
        2,
        reason: 'refetch must complete before mutation future resolves',
      );
    },
  );

  test(
    'Issue 540: approveLeave() awaits the refetch — synchronous read after '
    'await reflects onLeave status',
    () async {
      final fake = _FakeAttendance()
        ..store['alice'] = AttendanceStatus.onLeaveRequested;
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(clAttendancesMasterProvider(key).future);

      await container
          .read(clAttendancesMasterProvider(key).notifier)
          .approveLeave('alice');

      final sync = container.read(clAttendancesMasterProvider(key)).valueOrNull;
      expect(sync, isNotNull);
      expect(sync!.first.status, AttendanceStatus.onLeave);
      expect(fake.getCalls, 2);
    },
  );

  test(
    'Issue 724: clearAttendance() invalidates state — next read drops the '
    'cleared member',
    () async {
      final fake = _FakeAttendance()..store['alice'] = AttendanceStatus.present;
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final initial = await container.read(
        clAttendancesMasterProvider(key).future,
      );
      expect(initial, hasLength(1));

      await container
          .read(clAttendancesMasterProvider(key).notifier)
          .clearAttendance('alice');

      expect(fake.clearCalls, 1);

      final after = container
          .read(clAttendancesMasterProvider(key))
          .valueOrNull;
      expect(after, isEmpty);
      expect(
        fake.getCalls,
        2,
        reason: 'invalidateSelf should have triggered a re-fetch',
      );
    },
  );

  test(
    'Issue 536: clManualRefreshProvider bump re-fetches via build()',
    () async {
      final fake = _FakeAttendance();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(clAttendancesMasterProvider(key).future);
      expect(fake.getCalls, 1);

      fake.store['alice'] = AttendanceStatus.present;
      container.read(clManualRefreshProvider.notifier).state++;

      final after = await container.read(
        clAttendancesMasterProvider(key).future,
      );
      expect(after, hasLength(1));
      expect(fake.getCalls, 2);
    },
  );
}
