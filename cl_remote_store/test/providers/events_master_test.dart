import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [EventSource] backed by an in-memory store. Models the server's
/// soft-delete semantics: `deleteEvent` sets `deletedAtUtc` (the row
/// survives) and echoes the soft-deleted event, while `listEvents` (the
/// active listing) excludes soft-deleted rows.
class _FakeEvents extends Fake implements EventSource {
  _FakeEvents(Iterable<Event> seed) {
    for (final e in seed) {
      store[e.id] = e;
    }
  }

  final Map<int, Event> store = {};

  /// When set, `deleteEvent` throws this instead of soft-deleting — models
  /// the server rejecting the delete.
  Exception? deleteError;

  int deleteCalls = 0;

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
    final active = store.values.where((e) => e.isActive).toList();
    return PaginatedList<Event>(
      items: active,
      total: active.length,
      offset: 0,
      limit: limit ?? 100,
    );
  }

  @override
  Future<Event> deleteEvent(int eventId) async {
    deleteCalls++;
    if (deleteError != null) {
      throw deleteError!;
    }
    final deleted = store[eventId]!.copyWith(
      deletedAtUtc: () => DateTime.utc(2026, 1, 1),
    );
    store[eventId] = deleted;
    return deleted;
  }

  /// When set, `rescheduleEvent` throws this — models a stale version.
  Exception? rescheduleError;

  /// The `version` each `rescheduleEvent` call sent.
  final List<int> rescheduleVersions = [];

  int getCalls = 0;

  @override
  Future<Event> getEvent(int id) async {
    getCalls++;
    return store[id]!;
  }

  @override
  Future<Event> rescheduleEvent(
    int eventId, {
    required int version,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    String? rrule,
    int? venueId,
    List<EventSession>? Function()? sessions,
    bool resetOverrides = false,
  }) async {
    rescheduleVersions.add(version);
    if (rescheduleError != null) throw rescheduleError!;
    final moved = store[eventId]!.copyWith(
      startTimeUtc: startTimeUtc,
      version: version + 1,
    );
    store[eventId] = moved;
    return moved;
  }
}

/// Fake [OccurrenceSource] recording the `version` each change sends, and
/// optionally refusing every change with [error].
class _FakeOccurrences extends Fake implements OccurrenceSource {
  final List<String> calls = [];
  Exception? error;

  @override
  Future<void> rescheduleOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
    DateTime? newStartTimeUtc,
    int? newDurationMinutes,
    int? newVenueId,
  }) async {
    calls.add('reschedule(v$version)');
    if (error != null) throw error!;
  }

  @override
  Future<void> cancelOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
    required String reason,
  }) async {
    calls.add('cancel(v$version)');
    if (error != null) throw error!;
  }

  @override
  Future<void> undoCancelOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
  }) async {
    calls.add('undoCancel(v$version)');
    if (error != null) throw error!;
  }
}

SecureClient _buildClient(EventSource events, OccurrenceSource? occurrences) {
  return fakeSecureClient(
    events: events,
    occurrences: occurrences,
  );
}

ProviderContainer _makeContainer(
  EventSource events, {
  OccurrenceSource? occurrences,
}) {
  return ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => _buildClient(events, occurrences),
      ),
    ],
  );
}

StaleVersionException _stale(int version) => StaleVersionException(
  message: 'stale',
  version: version,
  updatedAtUtc: DateTime.utc(2026, 9, 1, 10),
  updatedBy: 'coach_a',
);

Event _campEvent(
  int id, {
  String title = 'workflow_camp',
  int version = 1,
}) => Event(
  id: id,
  version: version,
  title: title,
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 6),
  endTimeUtc: DateTime.utc(2026, 6, 1, 2),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

void main() {
  test(
    'Issue 605: deleteEvent reflects the server round-trip — the event stays '
    'in the master map with isActive == false (not silently removed)',
    () async {
      final fake = _FakeEvents([_campEvent(1)]);
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final loaded = await container.read(clEventsMasterProvider.future);
      expect(loaded[1]?.isActive, isTrue, reason: 'seeded event is active');

      await container.read(clEventsMasterProvider.notifier).deleteEvent(1);

      final after = container.read(clEventsMasterProvider).valueOrNull;
      expect(after, isNotNull);
      // The notifier must store the soft-deleted entity echoed by the server
      // so the in-memory map mirrors real server state, rather than blindly
      // dropping the id (which would pass an `isActive == false` assertion
      // even when the server delete never persisted).
      expect(
        after![1],
        isNotNull,
        reason: 'soft-deleted event must remain in the master map',
      );
      expect(
        after[1]!.isActive,
        isFalse,
        reason: 'master map must reflect the server-side soft-delete',
      );
      expect(fake.deleteCalls, 1);
    },
  );

  test(
    'Issue 605: deleteEvent does not mutate local state when the server '
    'rejects the delete',
    () async {
      final fake = _FakeEvents([_campEvent(1)])
        ..deleteError = Exception('EVENT_CANCELLED');
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(clEventsMasterProvider.future);

      await expectLater(
        container.read(clEventsMasterProvider.notifier).deleteEvent(1),
        throwsA(isA<Exception>()),
      );

      final after = container.read(clEventsMasterProvider).valueOrNull;
      expect(
        after?[1],
        isNotNull,
        reason: 'a rejected delete must leave the event in place',
      );
      expect(
        after![1]!.isActive,
        isTrue,
        reason: 'a rejected delete must not flip the event inactive',
      );
    },
  );

  group('Issue 68: rescheduleEvent sends the event version', () {
    test('Issue 68: forwards the version the caller loaded', () async {
      final fake = _FakeEvents([_campEvent(1, version: 4)]);
      final container = _makeContainer(fake);
      addTearDown(container.dispose);
      await container.read(clEventsMasterProvider.future);

      final moved = await container
          .read(clEventsMasterProvider.notifier)
          .rescheduleEvent(1, version: 3, startTimeUtc: DateTime.utc(2026, 7));

      expect(fake.rescheduleVersions, [3]);
      expect(
        container.read(clEventsMasterProvider).valueOrNull?[1],
        moved,
        reason: 'the rescheduled event replaces the cached one',
      );
    });

    test(
      'Issue 68: without a version, sends the cached event version',
      () async {
        final fake = _FakeEvents([_campEvent(1, version: 4)]);
        final container = _makeContainer(fake);
        addTearDown(container.dispose);
        await container.read(clEventsMasterProvider.future);

        await container
            .read(clEventsMasterProvider.notifier)
            .rescheduleEvent(1, startTimeUtc: DateTime.utc(2026, 7));

        expect(fake.rescheduleVersions, [4]);
      },
    );

    test('Issue 68: a stale version reloads the event and rethrows', () async {
      final fake = _FakeEvents([_campEvent(1, version: 2)]);
      final container = _makeContainer(fake);
      addTearDown(container.dispose);
      await container.read(clEventsMasterProvider.future);
      // Someone else moved the event since it was loaded.
      fake
        ..store[1] = _campEvent(1, version: 5)
        ..rescheduleError = _stale(5);
      final before = container.read(clResourceVersionProvider);

      await expectLater(
        container
            .read(clEventsMasterProvider.notifier)
            .rescheduleEvent(
              1,
              version: 2,
              startTimeUtc: DateTime.utc(2026, 7),
            ),
        throwsA(isA<StaleVersionException>()),
      );

      expect(fake.getCalls, 1, reason: 'the event is fetched again');
      expect(
        container.read(clEventsMasterProvider).valueOrNull?[1]?.version,
        5,
      );
      expect(
        container.read(clResourceVersionProvider).occurrencesVersion,
        before.occurrencesVersion + 1,
        reason: 'its occurrences are reloaded too',
      );
    });
  });

  group('Issue 69: occurrence changes send the occurrence version', () {
    final slot = DateTime.utc(2026, 6, 3, 6);

    test(
      'Issue 69: reschedule, cancel and undo-cancel forward the version',
      () async {
        final occurrences = _FakeOccurrences();
        final container = _makeContainer(
          _FakeEvents([_campEvent(1)]),
          occurrences: occurrences,
        );
        addTearDown(container.dispose);
        final notifier = container.read(clEventsMasterProvider.notifier);

        await notifier.rescheduleOccurrence(1, slot, version: 2, newVenueId: 9);
        await notifier.cancelOccurrence(1, slot, version: 3, reason: 'ice');
        await notifier.undoCancelOccurrence(1, slot, version: 4);

        expect(occurrences.calls, [
          'reschedule(v2)',
          'cancel(v3)',
          'undoCancel(v4)',
        ]);
      },
    );

    for (final change in ['reschedule', 'cancel', 'undoCancel']) {
      test(
        'Issue 69: a stale $change reloads the occurrences and rethrows',
        () async {
          final occurrences = _FakeOccurrences()..error = _stale(7);
          final container = _makeContainer(
            _FakeEvents([_campEvent(1)]),
            occurrences: occurrences,
          );
          addTearDown(container.dispose);
          final notifier = container.read(clEventsMasterProvider.notifier);
          final before = container.read(clResourceVersionProvider);

          final call = switch (change) {
            'reschedule' => notifier.rescheduleOccurrence(
              1,
              slot,
              version: 1,
              newVenueId: 9,
            ),
            'cancel' => notifier.cancelOccurrence(
              1,
              slot,
              version: 1,
              reason: 'ice',
            ),
            _ => notifier.undoCancelOccurrence(1, slot, version: 1),
          };
          await expectLater(call, throwsA(isA<StaleVersionException>()));

          expect(
            container.read(clResourceVersionProvider).occurrencesVersion,
            before.occurrencesVersion + 1,
          );
        },
      );
    }

    test('Issue 69: any other refusal leaves the occurrences alone', () async {
      final occurrences = _FakeOccurrences()
        ..error = const ServerException(
          statusCode: 422,
          code: 'CANCELLED_OCCURRENCE',
          message: 'cancelled',
        );
      final container = _makeContainer(
        _FakeEvents([_campEvent(1)]),
        occurrences: occurrences,
      );
      addTearDown(container.dispose);
      final before = container.read(clResourceVersionProvider);

      await expectLater(
        container
            .read(clEventsMasterProvider.notifier)
            .cancelOccurrence(1, slot, version: 1, reason: 'ice'),
        throwsA(isA<ServerException>()),
      );

      expect(container.read(clResourceVersionProvider), before);
    });
  });
}
