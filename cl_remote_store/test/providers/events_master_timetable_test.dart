import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [EventSource] recording the timetable corrections the master sends
/// through `updateEvent` (camp / one-off) and `correctionOnEvent`
/// (programme), and optionally refusing them with [error].
class _FakeEvents extends Fake implements EventSource {
  _FakeEvents(Event seed) {
    store[seed.id] = seed;
  }

  final Map<int, Event> store = {};

  /// When set, every correction throws this instead.
  Exception? error;

  /// One line per call: the verb, the version, the sessions and schedule.
  final List<String> calls = [];

  int getCalls = 0;

  String _describe(List<EventSession>? Function()? sessions) {
    if (sessions == null) return 'omitted';
    final supplied = sessions();
    if (supplied == null) return 'null';
    return supplied.map((s) => '${s.name}:${s.periodMinutes}').join(',');
  }

  Event _apply(int eventId, int version, List<EventSession>? sessions) {
    final updated = store[eventId]!.copyWith(
      sessions: () => sessions,
      version: version + 1,
    );
    store[eventId] = updated;
    return updated;
  }

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
  Future<Event> getEvent(int id) async {
    getCalls++;
    return store[id]!;
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
    Gender? Function()? gender,
    DateTime? Function()? dobOnOrAfterUtc,
    DateTime? Function()? dobOnOrBeforeUtc,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    String? Function()? shortDescription,
    String? Function()? stamp,
    List<String>? Function()? highlights,
    List<String>? Function()? includes,
    List<EventSession>? Function()? sessions,
  }) async {
    calls.add('update(v$version, ${_describe(sessions)})');
    if (error != null) throw error!;
    return _apply(eventId, version, sessions?.call());
  }

  @override
  Future<Event> correctionOnEvent(
    int eventId, {
    required int version,
    String? title,
    String? description,
    Visibility? visibility,
    Gender? Function()? gender,
    DateTime? Function()? dobOnOrAfterUtc,
    DateTime? Function()? dobOnOrBeforeUtc,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    String? Function()? shortDescription,
    String? Function()? stamp,
    List<String>? Function()? highlights,
    List<String>? Function()? includes,
    List<EventSession>? Function()? sessions,
    int? scheduleId,
  }) async {
    calls.add(
      'correction(v$version, ${_describe(sessions)}, schedule $scheduleId)',
    );
    if (error != null) throw error!;
    return _apply(eventId, version, sessions?.call());
  }
}

ProviderContainer _makeContainer(EventSource events) {
  return ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(events: events),
      ),
      clubEventTypesProvider.overrideWithValue(const {
        EventType.camp,
        EventType.programme,
        EventType.oneOff,
      }),
    ],
  );
}

Event _event({required EventType type, int version = 1}) => Event(
  id: 1,
  version: version,
  title: 'workflow_timetable',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 6, 1, 6),
  endTimeUtc: DateTime.utc(2026, 6, 1, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

const List<EventSession> _split = [
  EventSession(name: 'Warm-up', periodMinutes: 30),
  EventSession(name: 'Drills', periodMinutes: 90),
];

StaleVersionException _stale(int version) => StaleVersionException(
  message: 'stale',
  version: version,
  updatedAtUtc: DateTime.utc(2026, 9, 1, 10),
  updatedBy: 'coach_a',
);

void main() {
  group('Issue 85: a timetable correction goes through the master', () {
    test('Issue 85: updateEvent forwards the sessions and version', () async {
      final fake = _FakeEvents(_event(type: EventType.camp, version: 3));
      final container = _makeContainer(fake);
      addTearDown(container.dispose);
      await container.read(clEventsMasterProvider.future);
      final before = container.read(clResourceVersionProvider);

      final updated = await container
          .read(clEventsMasterProvider.notifier)
          .updateEvent(1, version: 3, sessions: () => _split);

      expect(fake.calls, ['update(v3, Warm-up:30,Drills:90)']);
      expect(updated.sessions, _split);
      expect(
        container.read(clEventsMasterProvider).valueOrNull?[1],
        updated,
        reason: 'the corrected event replaces the cached one',
      );
      expect(
        container.read(clResourceVersionProvider).occurrencesVersion,
        before.occurrencesVersion + 1,
        reason: 'the occurrences carry the timetable, so they reload',
      );
    });

    test(
      'Issue 85: updateEvent clears the timetable with a null getter',
      () async {
        final fake = _FakeEvents(_event(type: EventType.oneOff));
        final container = _makeContainer(fake);
        addTearDown(container.dispose);
        await container.read(clEventsMasterProvider.future);

        await container
            .read(clEventsMasterProvider.notifier)
            .updateEvent(1, version: 1, sessions: () => null);

        expect(fake.calls, ['update(v1, null)']);
      },
    );

    test(
      'Issue 85: correctionOnEvent forwards the sessions and schedule',
      () async {
        final fake = _FakeEvents(_event(type: EventType.programme, version: 2));
        final container = _makeContainer(fake);
        addTearDown(container.dispose);
        await container.read(clEventsMasterProvider.future);
        final before = container.read(clResourceVersionProvider);

        await container
            .read(clEventsMasterProvider.notifier)
            .correctionOnEvent(
              1,
              version: 2,
              sessions: () => _split,
              scheduleId: 11,
            );

        expect(fake.calls, [
          'correction(v2, Warm-up:30,Drills:90, schedule 11)',
        ]);
        expect(
          container.read(clResourceVersionProvider).occurrencesVersion,
          before.occurrencesVersion + 1,
          reason: 'the occurrences carry the timetable, so they reload',
        );
      },
    );

    test(
      'Issue 85: a stale timetable correction reloads the event and rethrows',
      () async {
        final fake = _FakeEvents(_event(type: EventType.programme, version: 2));
        final container = _makeContainer(fake);
        addTearDown(container.dispose);
        await container.read(clEventsMasterProvider.future);
        // Someone else changed the programme since it was loaded.
        fake
          ..store[1] = _event(type: EventType.programme, version: 5)
          ..error = _stale(5);

        await expectLater(
          container
              .read(clEventsMasterProvider.notifier)
              .correctionOnEvent(1, version: 2, sessions: () => _split),
          throwsA(isA<StaleVersionException>()),
        );

        expect(fake.getCalls, 1, reason: 'the event is fetched again');
        expect(
          container.read(clEventsMasterProvider).valueOrNull?[1]?.version,
          5,
        );
      },
    );

    test(
      'Issue 85: a stale updateEvent reloads the event and rethrows',
      () async {
        final fake = _FakeEvents(_event(type: EventType.camp, version: 2));
        final container = _makeContainer(fake);
        addTearDown(container.dispose);
        await container.read(clEventsMasterProvider.future);
        fake
          ..store[1] = _event(type: EventType.camp, version: 4)
          ..error = _stale(4);

        await expectLater(
          container
              .read(clEventsMasterProvider.notifier)
              .updateEvent(1, version: 2, sessions: () => _split),
          throwsA(isA<StaleVersionException>()),
        );

        expect(fake.getCalls, 1, reason: 'the event is fetched again');
        expect(
          container.read(clEventsMasterProvider).valueOrNull?[1]?.version,
          4,
        );
      },
    );
  });
}
