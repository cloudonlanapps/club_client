import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

const _eventId = 1;

/// Fake [EventSource]: one event that `updateEvent` changes in place, and
/// a count of the schedule reads.
class _FakeEvents extends Fake implements EventSource {
  _FakeEvents(Event seed) {
    store[seed.id] = seed;
  }

  final Map<int, Event> store = {};
  int scheduleReads = 0;

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
    final items = store.values.toList();
    return PaginatedList<Event>(
      items: items,
      total: items.length,
      offset: 0,
      limit: limit ?? 100,
    );
  }

  @override
  Future<Event> getEvent(int id) async => store[id]!;

  @override
  Future<List<EventSchedule>> listSchedules(int eventId) async {
    scheduleReads++;
    return const [];
  }

  @override
  Future<Event> updateEvent(
    int eventId, {
    required int version,
    String? title,
    String? description,
    Visibility? visibility,
    String? organizerName,
    List<String>? Function()? coachNames,
    List<Gender> Function()? genders,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    String? Function()? shortDescription,
    String? Function()? stamp,
    List<String>? Function()? highlights,
    List<String>? Function()? includes,
    List<EventSession>? Function()? sessions,
  }) async {
    final current = store[eventId]!;
    // The server answers with fresh lists, as a real response does.
    return store[eventId] = current.copyWith(
      version: version + 1,
      title: title,
      description: description,
      visibility: visibility,
      isFeatured: isFeatured,
      coachNames: () => coachNames != null
          ? coachNames()
          : current.coachNames == null
          ? null
          : [...current.coachNames!],
      sessions: () => sessions != null
          ? sessions()
          : current.sessions == null
          ? null
          : [...current.sessions!],
    );
  }
}

/// Fake [EnrollmentSource] counting the enrolment reads.
class _FakeEnrollments extends Fake implements EnrollmentSource {
  int statusReads = 0;
  int recordReads = 0;

  @override
  Future<Map<String, EnrollmentStatus>> listEnrollments(
    int eventId, {
    EnrollmentStatus? status,
  }) async {
    statusReads++;
    return const {'member_a': EnrollmentStatus.accepted};
  }

  @override
  Future<Map<String, Enrollment>> listEnrollmentsDetailed(
    int eventId, {
    EnrollmentStatus? status,
  }) async {
    recordReads++;
    return const {};
  }
}

Event _camp() => Event(
  id: _eventId,
  version: 1,
  title: 'workflow_narrow',
  description: 'before',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 1,
  organizerName: 'the_organizer',
  coachNames: const ['coach_a'],
  rrule: 'FREQ=DAILY;COUNT=3',
  startTimeUtc: DateTime.utc(2030, 6),
  endTimeUtc: DateTime.utc(2030, 6, 1, 1),
  sessions: const [EventSession(name: 'Warm-up', periodMinutes: 30)],
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

void main() {
  late _FakeEvents events;
  late _FakeEnrollments enrollments;
  late ProviderContainer container;

  /// The reads made while the page loaded: (status, records, schedules).
  late (int, int, int) loaded;

  setUp(() async {
    events = _FakeEvents(_camp());
    enrollments = _FakeEnrollments();
    container =
        ProviderContainer(
            overrides: [
              currentUserProvider.overrideWithValue(null),
              secureClientProvider.overrideWith(
                (ref) async =>
                    fakeSecureClient(events: events, enrollments: enrollments),
              ),
            ],
          )
          // Keep the three providers alive, as the event page does.
          ..listen(clEnrollmentsMasterProvider(_eventId), (_, _) {})
          ..listen(clEnrollmentRecordsMasterProvider(_eventId), (_, _) {})
          ..listen(clEventSchedulesProvider(_eventId), (_, _) {});
    await container.read(clEventsMasterProvider.future);
    await container.read(clEnrollmentsMasterProvider(_eventId).future);
    await container.read(clEnrollmentRecordsMasterProvider(_eventId).future);
    await container.read(clEventSchedulesProvider(_eventId).future);
    loaded = (
      enrollments.statusReads,
      enrollments.recordReads,
      events.scheduleReads,
    );
  });

  tearDown(() => container.dispose());

  ClEventsMasterNotifier master() =>
      container.read(clEventsMasterProvider.notifier);

  /// The reads made since the page loaded: (status, records, schedules).
  (int, int, int) readsSinceLoad() => (
    enrollments.statusReads - loaded.$1,
    enrollments.recordReads - loaded.$2,
    events.scheduleReads - loaded.$3,
  );

  /// Lets every provider that is going to rebuild do so.
  Future<void> settle() async {
    await container.read(clEnrollmentsMasterProvider(_eventId).future);
    await container.read(clEnrollmentRecordsMasterProvider(_eventId).future);
    await container.read(clEventSchedulesProvider(_eventId).future);
  }

  group('Issue 230: an event save reloads only what depends on it', () {
    test('Issue 230: a Private toggle reloads neither the enrolments nor the '
        'schedules', () async {
      await master().updateEvent(_eventId, visibility: Visibility.private);
      await settle();

      expect(readsSinceLoad(), (0, 0, 0));
    });

    test('Issue 230: a Featured toggle and a description save reload '
        'neither', () async {
      await master().updateEvent(_eventId, isFeatured: true);
      await master().updateEvent(_eventId, description: 'after');
      await settle();

      expect(readsSinceLoad(), (0, 0, 0));
    });

    test('Issue 230: a timetable save reloads the schedules', () async {
      await master().updateEvent(
        _eventId,
        sessions: () => const [EventSession(name: 'Drills', periodMinutes: 45)],
      );
      await settle();

      expect(readsSinceLoad(), (0, 0, 1));
    });

    test('Issue 230: archiving the event reloads its enrolments', () async {
      master().replaceLocally(
        events.store[_eventId]!.copyWith(
          deletedAtUtc: () => DateTime.utc(2026, 3),
        ),
      );
      await settle();

      expect(readsSinceLoad(), (1, 1, 0));
    });

    test('Issue 230: the occurrence version is still bumped on every event '
        'save', () async {
      final before = container
          .read(clResourceVersionProvider)
          .occurrencesVersion;
      await master().updateEvent(_eventId, visibility: Visibility.private);

      expect(
        container.read(clResourceVersionProvider).occurrencesVersion,
        before + 1,
      );
    });
  });
}
