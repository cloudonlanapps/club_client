import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

const _member = 'm';
const _eventId = 1;
final _time = DateTime.utc(2026, 10, 1, 18);

/// The server's attendance marks, shared by the staff and member sources.
final Map<String, AttendanceStatus> _marks = {};

class _FakeAttendance extends Fake implements AttendanceSource {
  @override
  Future<List<AttendanceRecord>> getAttendanceForOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc,
  ) async => const [];

  @override
  Future<AttendanceMarkReport> markAttendance(
    int eventId,
    DateTime occurrenceTimeUtc,
    List<AttendanceMarkRecord> records,
  ) async {
    for (final r in records) {
      _marks[r.membername] = r.status;
    }
    return const AttendanceMarkReport();
  }

  @override
  Future<void> clearAttendance(
    int eventId,
    String username,
    DateTime occurrenceTimeUtc,
  ) async {
    _marks.remove(username);
  }

  @override
  Future<void> approveLeave(
    int eventId,
    String username,
    DateTime occurrenceTimeUtc,
  ) async {}

  @override
  Future<void> rejectLeave(
    int eventId,
    String username,
    DateTime occurrenceTimeUtc, {
    String? reason,
  }) async {}
}

class _FakeMyEvents extends Fake implements MyEventsSource {
  int attendanceListReads = 0;
  int occurrenceReads = 0;

  @override
  Future<List<MyAttendanceRecord>> listMyAttendance(
    String username, {
    required DateTime fromTimeUtc,
    required DateTime toTimeUtc,
  }) async {
    attendanceListReads++;
    final status = _marks[username];
    return [
      if (status != null)
        MyAttendanceRecord(
          eventId: _eventId,
          occurrenceTimeUtc: _time,
          membername: username,
          status: status,
          recordedAtUtc: _time,
        ),
    ];
  }

  @override
  Future<List<Occurrence>> listMyOccurrences(
    String username, {
    required DateTime fromTimeUtc,
    required DateTime toTimeUtc,
  }) async {
    occurrenceReads++;
    return const [];
  }

  @override
  Future<AttendanceRecord?> getMyOccurrenceAttendance(
    String username,
    int eventId,
    DateTime occurrenceTimeUtc,
  ) async => null;

  @override
  Future<void> requestLeave(
    String username,
    int eventId,
    DateTime occurrenceTimeUtc, {
    String? reason,
  }) async {}

  @override
  Future<void> cancelLeaveRequest(
    String username,
    int eventId,
    DateTime occurrenceTimeUtc,
  ) async {}
}

void main() {
  final listKey = (
    username: _member,
    fromTimeUtc: DateTime.utc(2026, 10),
    toTimeUtc: DateTime.utc(2026, 11),
  );
  final occurrencesKey = (
    username: _member,
    from: DateTime.utc(2026, 10),
    to: DateTime.utc(2026, 11),
  );
  final staffKey = (eventId: _eventId, occurrenceTimeUtc: _time);
  final memberKey = (
    username: _member,
    eventId: _eventId,
    occurrenceTimeUtc: _time,
  );

  late _FakeMyEvents myEvents;
  late ProviderContainer container;

  setUp(() {
    _marks.clear();
    myEvents = _FakeMyEvents();
    container = ProviderContainer(
      overrides: [
        secureClientProvider.overrideWith(
          (ref) async => fakeSecureClient(
            attendance: _FakeAttendance(),
            myEvents: myEvents,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  int attendanceVersion() =>
      container.read(clResourceVersionProvider).attendanceVersion;

  test(
    "Issue 232: after markAttendance, the member's attendance list and "
    'occurrences refetch and the list shows the mark',
    () async {
      final list = container.listen(
        clMyAttendanceListProvider(listKey),
        (_, _) {},
      );
      addTearDown(list.close);
      final occurrences = container.listen(
        clMyOccurrencesProvider(occurrencesKey),
        (_, _) {},
      );
      addTearDown(occurrences.close);
      expect(
        await container.read(clMyAttendanceListProvider(listKey).future),
        isEmpty,
      );
      await container.read(clMyOccurrencesProvider(occurrencesKey).future);
      expect(myEvents.attendanceListReads, 1);
      expect(myEvents.occurrenceReads, 1);

      await container
          .read(clAttendancesMasterProvider(staffKey).notifier)
          .markAttendance(const [
            AttendanceMarkRecord(
              membername: _member,
              status: AttendanceStatus.present,
            ),
          ]);

      final after = await container.read(
        clMyAttendanceListProvider(listKey).future,
      );
      expect(myEvents.attendanceListReads, 2);
      expect(after.single.status, AttendanceStatus.present);
      await container.read(clMyOccurrencesProvider(occurrencesKey).future);
      expect(myEvents.occurrenceReads, 2);
    },
  );

  final staffActions =
      <String, Future<void> Function(ClAttendancesMasterNotifier)>{
        'clearAttendance': (n) => n.clearAttendance(_member),
        'approveLeave': (n) => n.approveLeave(_member),
        'rejectLeave': (n) => n.rejectLeave(_member),
      };
  for (final MapEntry(key: name, value: action) in staffActions.entries) {
    test('Issue 232: $name bumps attendanceVersion', () async {
      await container.read(clAttendancesMasterProvider(staffKey).future);
      final before = attendanceVersion();

      await action(
        container.read(clAttendancesMasterProvider(staffKey).notifier),
      );

      expect(attendanceVersion(), greaterThan(before));
    });
  }

  final memberActions =
      <String, Future<void> Function(ClMyAttendancesMasterNotifier)>{
        'requestLeave': (n) => n.requestLeave(reason: 'travel'),
        'cancelLeaveRequest': (n) => n.cancelLeaveRequest(),
      };
  for (final MapEntry(key: name, value: action) in memberActions.entries) {
    test('Issue 232: a member $name bumps attendanceVersion', () async {
      final sub = container.listen(
        clMyAttendancesMasterProvider(memberKey),
        (_, _) {},
      );
      addTearDown(sub.close);
      await container.read(clMyAttendancesMasterProvider(memberKey).future);
      final before = attendanceVersion();

      await action(
        container.read(clMyAttendancesMasterProvider(memberKey).notifier),
      );

      expect(attendanceVersion(), greaterThan(before));
    });
  }
}
