import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [EventSource] for the end-date verbs: an in-memory store whose
/// terminate / extend / extend-indefinitely either apply or throw [error].
class _FakeEvents extends Fake implements EventSource {
  _FakeEvents(Event seed) {
    store[seed.id] = seed;
  }

  final Map<int, Event> store = {};
  final List<String> calls = [];

  /// When set, every end-date verb throws this instead of applying.
  Exception? error;

  int listCalls = 0;

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
    listCalls++;
    final items = store.values.toList();
    return PaginatedList<Event>(
      items: items,
      total: items.length,
      offset: 0,
      limit: limit ?? 100,
    );
  }

  Event _apply(int eventId, DateTime? cutoff) {
    if (error != null) throw error!;
    final current = store[eventId]!;
    final updated = current.copyWith(
      untilTimeUtc: () => cutoff,
      version: current.version + 1,
    );
    store[eventId] = updated;
    return updated;
  }

  @override
  Future<Event> terminate(
    int eventId, {
    required String reason,
    required DateTime cutoffTimeUtc,
  }) async {
    calls.add('terminate($cutoffTimeUtc, $reason)');
    return _apply(eventId, cutoffTimeUtc);
  }

  @override
  Future<Event> extend(
    int eventId, {
    required DateTime cutoffTimeUtc,
    String? reason,
  }) async {
    calls.add('extend($cutoffTimeUtc, $reason)');
    return _apply(eventId, cutoffTimeUtc);
  }

  @override
  Future<Event> extendIndefinitely(int eventId, {String? reason}) async {
    calls.add('extendIndefinitely($reason)');
    return _apply(eventId, null);
  }
}

Event _programme({DateTime? untilTimeUtc}) => Event(
  id: 1,
  version: 2,
  title: 'workflow_endprog',
  description: '',
  type: EventType.programme,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 6),
  endTimeUtc: DateTime.utc(2026, 6, 1, 1),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  rrule: 'FREQ=WEEKLY;BYDAY=MO',
  untilTimeUtc: untilTimeUtc,
);

void main() {
  group('Issue 39: the events master sets, moves and clears an end date', () {
    final cutoff = DateTime.utc(2026, 11, 16);
    final later = DateTime.utc(2026, 11, 30);

    late _FakeEvents fake;
    late ProviderContainer container;

    Future<void> pump(Event seed) async {
      fake = _FakeEvents(seed);
      container = ProviderContainer(
        overrides: [
          secureClientProvider.overrideWith(
            (ref) async => fakeSecureClient(events: fake),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(clEventsMasterProvider.future);
    }

    Event? cached() => container.read(clEventsMasterProvider).valueOrNull?[1];

    int occurrencesVersion() =>
        container.read(clResourceVersionProvider).occurrencesVersion;

    test('Issue 39: terminate puts the server answer in the master map and '
        'reloads the occurrence feeds', () async {
      await pump(_programme());
      final before = occurrencesVersion();

      final updated = await container
          .read(clEventsMasterProvider.notifier)
          .terminate(1, reason: 'Season over', cutoffTimeUtc: cutoff);

      expect(fake.calls, ['terminate($cutoff, Season over)']);
      expect(updated.untilTimeUtc, cutoff);
      expect(cached()?.untilTimeUtc, cutoff);
      expect(cached()?.version, 3);
      expect(cached()?.isActive, isTrue, reason: 'the programme stays listed');
      expect(occurrencesVersion(), before + 1);
    });

    test('Issue 39: extend moves the end to the cutoff the server answers '
        'with', () async {
      await pump(_programme(untilTimeUtc: cutoff));

      await container
          .read(clEventsMasterProvider.notifier)
          .extend(1, cutoffTimeUtc: later);

      expect(fake.calls, ['extend($later, null)']);
      expect(cached()?.untilTimeUtc, later);
    });

    test('Issue 39: extendIndefinitely clears the end', () async {
      await pump(_programme(untilTimeUtc: cutoff));
      final before = occurrencesVersion();

      final updated = await container
          .read(clEventsMasterProvider.notifier)
          .extendIndefinitely(1, reason: 'Running on');

      expect(fake.calls, ['extendIndefinitely(Running on)']);
      expect(updated.untilTimeUtc, isNull);
      expect(cached()?.untilTimeUtc, isNull);
      expect(occurrencesVersion(), before + 1);
    });

    test('Issue 39: a refusal leaves the master map as it was', () async {
      await pump(_programme());
      fake.error = const ServerException(
        statusCode: 422,
        code: SdkErrorCode.cutoffTooSoon,
        message: 'too soon',
      );

      await expectLater(
        container
            .read(clEventsMasterProvider.notifier)
            .terminate(1, reason: 'Season over', cutoffTimeUtc: cutoff),
        throwsA(isA<ServerException>()),
      );

      expect(cached()?.untilTimeUtc, isNull);
      expect(cached()?.version, 2);
      expect(fake.listCalls, 1, reason: 'a plain refusal does not refetch');
    });
  });
}
