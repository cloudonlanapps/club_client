import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_credit_sources.dart';
import '../support/fake_secure_client.dart';

const _programme = 9;

/// Roster fake over the credit fake, recording roster calls.
class _Credits extends FakeCredits {
  _Credits(super.store);
  int rosterCalls = 0;

  @override
  Future<PaginatedList<MemberCreditStatus>> listEventCredits(
    int eventId, {
    RosterCreditFilter? filter,
    DateTime? expiringBeforeUtc,
    int offset = 0,
    int limit = 50,
  }) async {
    rosterCalls++;
    return PaginatedList(
      items: const [
        MemberCreditStatus(
          membername: 'bound',
          usableCredits: 2,
          boundCredits: 2,
          blocked: false,
        ),
      ],
      total: 1,
      offset: offset,
      limit: limit,
    );
  }
}

class _Events extends Fake implements EventSource {
  _Events(this.type);
  final EventType type;

  @override
  Future<PaginatedList<Event>> listEvents({
    DateTime? fromTimeUtc,
    DateTime? toTimeUtc,
    int? venueId,
    EventType? eventType,
    Visibility? visibility,
    int? limit,
    int? offset,
  }) async {
    final e = Event(
      id: _programme,
      version: 1,
      title: 'p',
      description: '',
      type: type,
      visibility: Visibility.public,
      venueId: 1,
      startTimeUtc: DateTime.utc(2026, 9),
      endTimeUtc: DateTime.utc(2026, 9, 1, 1),
      createdAtUtc: DateTime.utc(2026),
      updatedAtUtc: DateTime.utc(2026),
    );
    final items = eventType == null || eventType == type ? [e] : <Event>[];
    return PaginatedList(
      items: items,
      total: items.length,
      offset: 0,
      limit: 100,
    );
  }
}

class _Enrollments extends Fake implements EnrollmentSource {
  int detailedCalls = 0;
  @override
  Future<Map<String, Enrollment>> listEnrollmentsDetailed(
    int eventId, {
    EnrollmentStatus? status,
  }) async {
    detailedCalls++;
    return const {};
  }

  @override
  Future<Map<String, EnrollmentStatus>> listEnrollments(
    int eventId, {
    EnrollmentStatus? status,
  }) async => const {};
}

class _Attendance extends Fake implements AttendanceSource {
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
  ) async => const AttendanceMarkReport(trialEnded: ['trial']);
}

ProviderContainer _container({
  required EventType type,
  bool creditSystem = true,
  _Credits? credits,
  _Enrollments? enrollments,
}) {
  final store = FakeMyCredits();
  final container = ProviderContainer(
    overrides: [
      clubEventTypesProvider.overrideWithValue(EventType.values.toSet()),
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(
          capabilities: FakeCapabilities(creditSystem: creditSystem),
          myCredits: store,
          credits: credits ?? _Credits(store),
          events: _Events(type),
          enrollments: enrollments ?? _Enrollments(),
          attendance: _Attendance(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<T> _settled<T>(
  ProviderContainer c,
  ProviderListenable<AsyncValue<T>> p,
) async {
  final sub = c.listen(p, (_, _) {});
  addTearDown(sub.close);
  for (var i = 0; i < 100; i++) {
    final v = c.read(p);
    if (v.hasValue && !v.isLoading) return v.requireValue;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('$p did not settle');
}

void main() {
  group('Issue 97: who can be funded (the server rule)', () {
    CreditAccount a(int balance, {int? eventId, bool trial = false}) =>
        creditAccount(
          'A$balance$eventId$trial',
          membername: 'm',
          balance: balance,
          eventId: eventId,
          isTrial: trial,
        );

    test('Issue 97: general and this programme count', () {
      expect(
        usableCreditsFor(
          [a(2), a(3, eventId: _programme)],
          eventId: _programme,
          trial: false,
        ),
        5,
      );
    });

    test('Issue 97: another programme does not count', () {
      expect(
        usableCreditsFor(
          [a(4, eventId: 77)],
          eventId: _programme,
          trial: false,
        ),
        0,
      );
    });

    test('Issue 105: trial and ordinary credit never mix', () {
      final accounts = [a(1, eventId: _programme, trial: true), a(2)];
      expect(usableCreditsFor(accounts, eventId: _programme, trial: true), 1);
      expect(usableCreditsFor(accounts, eventId: _programme, trial: false), 2);
    });

    test('Issue 97: an empty account does not count', () {
      expect(
        usableCreditsFor([a(0)], eventId: _programme, trial: false),
        0,
      );
    });
  });

  group('Issue 96: the credit roster', () {
    test('Issue 96: a programme with credit on is fetched', () async {
      final credits = _Credits(FakeMyCredits());
      final c = _container(type: EventType.programme, credits: credits);
      await c.read(capabilitiesProvider.future);
      await c.read(clEventsMasterProvider.future);

      final roster = await _settled(c, clEventCreditRosterProvider(_programme));

      expect(roster['bound']?.boundCredits, 2);
      expect(credits.rosterCalls, 1);
    });

    test('Issue 96: a camp makes no roster call', () async {
      final credits = _Credits(FakeMyCredits());
      final c = _container(type: EventType.camp, credits: credits);
      await c.read(capabilitiesProvider.future);
      await c.read(clEventsMasterProvider.future);

      final roster = await _settled(c, clEventCreditRosterProvider(_programme));

      expect(roster, isEmpty);
      expect(credits.rosterCalls, 0);
    });

    test('Issue 96: credit off makes no roster call', () async {
      final credits = _Credits(FakeMyCredits());
      final c = _container(
        type: EventType.programme,
        creditSystem: false,
        credits: credits,
      );
      await c.read(capabilitiesProvider.future);
      await c.read(clEventsMasterProvider.future);

      await _settled(c, clEventCreditRosterProvider(_programme));

      expect(credits.rosterCalls, 0);
    });
  });

  test('Issue 98: a mark that ends a trial returns the report and refetches '
      'the enrollment records', () async {
    final enrollments = _Enrollments();
    final c = _container(type: EventType.programme, enrollments: enrollments);
    final key = (eventId: _programme, occurrenceTimeUtc: DateTime.utc(2026, 9));
    await _settled(c, clAttendancesMasterProvider(key));
    await _settled(c, clEnrollmentRecordsMasterProvider(_programme));
    final before = enrollments.detailedCalls;

    final report = await c
        .read(clAttendancesMasterProvider(key).notifier)
        .markAttendance([
          const AttendanceMarkRecord(
            membername: 'trial',
            status: AttendanceStatus.present,
          ),
        ]);
    await _settled(c, clEnrollmentRecordsMasterProvider(_programme));

    expect(report.trialEnded, ['trial']);
    expect(enrollments.detailedCalls, greaterThan(before));
  });
}
