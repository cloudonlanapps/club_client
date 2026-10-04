import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Reads fail once [failReads] is set; leave requests always succeed.
class _FakeMyEvents extends Fake implements MyEventsSource {
  bool failReads = false;
  int reads = 0;
  int leaveRequests = 0;

  @override
  Future<AttendanceRecord?> getMyOccurrenceAttendance(
    String username,
    int eventId,
    DateTime occurrenceTimeUtc,
  ) async {
    reads++;
    if (failReads) {
      throw const ServerException(
        statusCode: 503,
        code: 'service_unavailable',
        message: 'down',
      );
    }
    return null;
  }

  @override
  Future<void> requestLeave(
    String username,
    int eventId,
    DateTime occurrenceTimeUtc, {
    String? reason,
  }) async {
    leaveRequests++;
  }
}

/// Counts the staff register's reads, to see the cross-invalidation.
class _FakeAttendance extends Fake implements AttendanceSource {
  int reads = 0;

  @override
  Future<List<AttendanceRecord>> getAttendanceForOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc,
  ) async {
    reads++;
    return const [];
  }
}

void main() {
  final time = DateTime.utc(2026, 10, 1, 18);
  final key = (username: 'm', eventId: 1, occurrenceTimeUtc: time);
  final staffKey = (eventId: 1, occurrenceTimeUtc: time);

  late _FakeMyEvents myEvents;
  late _FakeAttendance attendance;
  late ProviderContainer container;

  setUp(() {
    myEvents = _FakeMyEvents();
    attendance = _FakeAttendance();
    container = ProviderContainer(
      overrides: [
        secureClientProvider.overrideWith(
          (ref) async =>
              fakeSecureClient(myEvents: myEvents, attendance: attendance),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'Issue 139: a failed read surfaces as an error, not no record',
    () async {
      myEvents.failReads = true;
      final sub = container.listen(
        clMyAttendancesMasterProvider(key),
        (_, _) {},
      );
      addTearDown(sub.close);

      await expectLater(
        container.read(clMyAttendancesMasterProvider(key).future),
        throwsA(isA<ServerException>()),
      );
      expect(sub.read().hasError, isTrue);
    },
  );

  test(
    'Issue 139: a leave request whose refetch fails completes, leaves the '
    'error in state and still refreshes the staff register',
    () async {
      final sub = container.listen(
        clMyAttendancesMasterProvider(key),
        (_, _) {},
      );
      addTearDown(sub.close);
      final staff = container.listen(
        clAttendancesMasterProvider(staffKey),
        (_, _) {},
      );
      addTearDown(staff.close);
      await container.read(clMyAttendancesMasterProvider(key).future);
      await container.read(clAttendancesMasterProvider(staffKey).future);
      expect(attendance.reads, 1);

      myEvents.failReads = true;
      await container
          .read(clMyAttendancesMasterProvider(key).notifier)
          .requestLeave(reason: 'travel');

      expect(myEvents.leaveRequests, 1);
      final state = sub.read();
      expect(state.hasError, isTrue);
      expect(state.error, isA<ServerException>());

      await container.read(clAttendancesMasterProvider(staffKey).future);
      expect(
        attendance.reads,
        2,
        reason: 'the staff register must be invalidated even so',
      );
    },
  );
}
