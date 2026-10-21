import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [EventSource] for the five cutoff verbs: an in-memory store whose
/// verbs record the `version` they were sent, then apply (bumping the
/// version) or throw [error].
class _FakeEvents extends Fake implements EventSource {
  _FakeEvents(Event seed) {
    store[seed.id] = seed;
  }

  final Map<int, Event> store = {};

  /// Each cutoff call as `verb(v<version>)`, in order.
  final List<String> calls = [];

  /// When set, every cutoff verb throws this instead of applying.
  Exception? error;

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

  Event _apply(String verb, int eventId, int version) {
    calls.add('$verb(v$version)');
    final refused = error;
    if (refused != null) throw refused;
    return store[eventId] = store[eventId]!.copyWith(version: version + 1);
  }

  @override
  Future<Event> cancelSeries(
    int eventId, {
    required int version,
    required String reason,
    required DateTime effectiveDateTimeUtc,
  }) async => _apply('cancelSeries', eventId, version);

  @override
  Future<Event> undoCancelSeries(int eventId, {required int version}) async =>
      _apply('undoCancelSeries', eventId, version);

  @override
  Future<Event> terminate(
    int eventId, {
    required int version,
    required String reason,
    required DateTime cutoffTimeUtc,
  }) async => _apply('terminate', eventId, version);

  @override
  Future<Event> extend(
    int eventId, {
    required int version,
    required DateTime cutoffTimeUtc,
    String? reason,
  }) async => _apply('extend', eventId, version);

  @override
  Future<Event> extendIndefinitely(
    int eventId, {
    required int version,
    String? reason,
  }) async => _apply('extendIndefinitely', eventId, version);
}

Event _event({required int version}) => Event(
  id: 1,
  version: version,
  title: 'workflow_cutoff',
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
  final cutoff = DateTime.utc(2026, 11, 16);
  final verbs =
      <String, Future<Event> Function(ClEventsMasterNotifier, {int? version})>{
        'cancelSeries': (n, {version}) => n.cancelSeries(
          1,
          reason: 'Rink closed',
          effectiveDateTimeUtc: cutoff,
          version: version,
        ),
        'undoCancelSeries': (n, {version}) =>
            n.undoCancelSeries(1, version: version),
        'terminate': (n, {version}) => n.terminate(
          1,
          reason: 'Season over',
          cutoffTimeUtc: cutoff,
          version: version,
        ),
        'extend': (n, {version}) =>
            n.extend(1, cutoffTimeUtc: cutoff, version: version),
        'extendIndefinitely': (n, {version}) =>
            n.extendIndefinitely(1, version: version),
      };

  late _FakeEvents fake;
  late ProviderContainer container;

  setUp(() async {
    fake = _FakeEvents(_event(version: 2));
    container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        secureClientProvider.overrideWith(
          (ref) async => fakeSecureClient(events: fake),
        ),
      ],
    );
    await container.read(clEventsMasterProvider.future);
  });

  tearDown(() => container.dispose());

  ClEventsMasterNotifier notifier() =>
      container.read(clEventsMasterProvider.notifier);

  int occurrencesVersion() =>
      container.read(clResourceVersionProvider).occurrencesVersion;

  for (final MapEntry(key: name, value: verb) in verbs.entries) {
    group('Issue 123: $name sends the event version', () {
      test('Issue 123: $name sends the version the caller loaded', () async {
        await verb(notifier(), version: 2);

        expect(fake.calls, ['$name(v2)']);
        expect(
          container.read(clEventsMasterProvider).valueOrNull?[1]?.version,
          3,
          reason: "the master holds the server's answer",
        );
      });

      test('Issue 123: $name with no version given sends the one the master '
          'holds', () async {
        await verb(notifier());

        expect(fake.calls, ['$name(v2)']);
      });

      test('Issue 123: $name refused as stale reloads the event and its '
          'occurrences, and rethrows', () async {
        // Another admin changed the event since it was loaded.
        fake
          ..store[1] = _event(version: 5)
          ..error = StaleVersionException(
            message: 'stale',
            version: 5,
            updatedAtUtc: DateTime.utc(2026, 9, 26, 10),
            updatedBy: 'another_admin',
          );
        final before = occurrencesVersion();

        await expectLater(
          verb(notifier(), version: 2),
          throwsA(
            isA<StaleVersionException>().having(
              (e) => e.updatedBy,
              'updatedBy',
              'another_admin',
            ),
          ),
        );

        expect(fake.calls, ['$name(v2)']);
        expect(fake.getCalls, 1, reason: 'the event is fetched again');
        expect(
          container.read(clEventsMasterProvider).valueOrNull?[1]?.version,
          5,
          reason: 'the master now holds the version the server has',
        );
        expect(
          occurrencesVersion(),
          before + 1,
          reason: 'the occurrence feeds reload',
        );
      });

      test('Issue 123: $name retried after a stale refusal sends the fresh '
          'version', () async {
        fake
          ..store[1] = _event(version: 5)
          ..error = const StaleVersionException(message: 'stale', version: 5);
        await expectLater(
          verb(notifier()),
          throwsA(isA<StaleVersionException>()),
        );

        fake.error = null;
        await verb(notifier());

        expect(fake.calls, ['$name(v2)', '$name(v5)']);
      });

      test('Issue 123: $name refused for another reason does not refetch the '
          'event', () async {
        fake.error = const ServerException(
          statusCode: 422,
          code: SdkErrorCode.cutoffTooSoon,
          message: 'too soon',
        );

        await expectLater(
          verb(notifier(), version: 2),
          throwsA(isA<ServerException>()),
        );

        expect(fake.getCalls, 0);
      });
    });
  }

  test('Issue 188: cancelSeries on a camp with no version given sends the '
      'version of the camp the master holds', () async {
    final camp = _event(version: 6).copyWith(
      type: EventType.camp,
      rrule: () => 'FREQ=DAILY;COUNT=5',
    );
    final events = _FakeEvents(camp);
    final campContainer = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        secureClientProvider.overrideWith(
          (ref) async => fakeSecureClient(events: events),
        ),
      ],
    );
    addTearDown(campContainer.dispose);
    await campContainer.read(clEventsMasterProvider.future);

    await campContainer
        .read(clEventsMasterProvider.notifier)
        .cancelSeries(
          camp.id,
          reason: 'Rink closed',
          effectiveDateTimeUtc: cutoff,
        );

    expect(events.calls, ['cancelSeries(v6)']);
  });
}
