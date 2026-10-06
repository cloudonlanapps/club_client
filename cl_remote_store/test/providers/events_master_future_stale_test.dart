import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [EventSource] for `updateEventForAllFuture`: an in-memory store
/// whose split either applies (bumping the version) or throws [splitError].
class _FakeEvents extends Fake implements EventSource {
  _FakeEvents(Event seed) {
    store[seed.id] = seed;
  }

  final Map<int, Event> store = {};

  /// When set, the split throws this instead of applying.
  Exception? splitError;

  /// The `version` each split sent.
  final List<int> splitVersions = [];

  int getCalls = 0;

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
  Future<Event> updateEventForAllFuture(
    int eventId, {
    required int version,
    required DateTime effectiveDateTimeUtc,
    int? venueId,
    String? organizerName,
    List<String>? Function()? coachNames,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    String? rrule,
    List<EventSession>? Function()? sessions,
  }) async {
    splitVersions.add(version);
    if (splitError != null) throw splitError!;
    final updated = store[eventId]!.copyWith(
      rrule: () => rrule,
      version: version + 1,
    );
    store[eventId] = updated;
    return updated;
  }
}

Event _programme({required int version}) => Event(
  id: 1,
  version: version,
  title: 'workflow_adjustprog',
  description: '',
  type: EventType.programme,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 6),
  endTimeUtc: DateTime.utc(2026, 6, 1, 1),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  rrule: 'FREQ=WEEKLY;BYDAY=MO',
);

void main() {
  group('Issue 38: updateEventForAllFuture and a stale version', () {
    late _FakeEvents fake;
    late ProviderContainer container;
    final effective = DateTime.utc(2026, 6, 8);

    setUp(() async {
      fake = _FakeEvents(_programme(version: 2));
      container = ProviderContainer(
        overrides: [
          secureClientProvider.overrideWith(
            (ref) async => fakeSecureClient(events: fake),
          ),
        ],
      );
      await container.read(clEventsMasterProvider.future);
    });

    tearDown(() => container.dispose());

    test(
      'Issue 38: a split replaces the event with the server answer',
      () async {
        final updated = await container
            .read(clEventsMasterProvider.notifier)
            .updateEventForAllFuture(
              1,
              effectiveDateTimeUtc: effective,
              version: 2,
              rrule: 'FREQ=WEEKLY;BYDAY=TU',
            );

        expect(updated.rrule, 'FREQ=WEEKLY;BYDAY=TU');
        expect(fake.splitVersions, [2]);
        expect(
          container.read(clEventsMasterProvider).valueOrNull?[1]?.rrule,
          'FREQ=WEEKLY;BYDAY=TU',
        );
        expect(fake.getCalls, 0);
      },
    );

    test('Issue 38: a stale version reloads the event and rethrows', () async {
      // Someone else changed the programme since it was loaded.
      fake
        ..store[1] = _programme(version: 5)
        ..splitError = const StaleVersionException(
          message: 'stale',
          version: 5,
          updatedBy: 'another_admin',
        );

      await expectLater(
        container
            .read(clEventsMasterProvider.notifier)
            .updateEventForAllFuture(
              1,
              effectiveDateTimeUtc: effective,
              version: 2,
              rrule: 'FREQ=WEEKLY;BYDAY=TU',
            ),
        throwsA(isA<StaleVersionException>()),
      );

      expect(fake.getCalls, 1, reason: 'the event is fetched again');
      expect(
        container.read(clEventsMasterProvider).valueOrNull?[1]?.version,
        5,
        reason: 'the cache now holds the version the server has',
      );
    });
  });
}
