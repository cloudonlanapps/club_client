import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [EventSource] recording the drop / reinstate calls, and optionally
/// refusing each with [error].
class _FakeEvents extends Fake implements EventSource {
  _FakeEvents(this.event);

  Event event;
  final List<String> calls = [];
  Exception? error;

  @override
  Future<PaginatedList<Event>> listEvents({
    DateTime? fromTimeUtc,
    DateTime? toTimeUtc,
    int? venueId,
    EventType? eventType,
    Visibility? visibility,
    int? limit,
    int? offset,
  }) async => PaginatedList<Event>(
    items: [event],
    total: 1,
    offset: 0,
    limit: limit ?? 100,
  );

  Event answer(String call) {
    calls.add(call);
    final refused = error;
    if (refused != null) throw refused;
    return event = event.copyWith(version: event.version + 1);
  }

  @override
  Future<Event> drop(
    int eventId, {
    required int version,
    required String reason,
  }) async => answer('drop($eventId, v$version, $reason)');

  @override
  Future<Event> reinstate(int eventId, {required int version}) async =>
      answer('reinstate($eventId, v$version)');
}

Event _oneOff() => Event(
  id: 5,
  version: 2,
  title: 'workflow_calloff_event',
  description: '',
  type: EventType.oneOff,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2030, 6),
  endTimeUtc: DateTime.utc(2030, 6, 1, 2),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

Future<(ProviderContainer, _FakeEvents)> _loaded() async {
  final events = _FakeEvents(_oneOff());
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWithValue(null),
      clubEventTypesProvider.overrideWithValue(EventType.values.toSet()),
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(events: events),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(clEventsMasterProvider.future);
  return (container, events);
}

int _occurrencesVersion(ProviderContainer container) =>
    container.read(clResourceVersionProvider).occurrencesVersion;

void main() {
  group('Issue 40: the events master calls off and reinstates a one-off', () {
    test(
      'Issue 40: drop sends the occurrence version and the reason',
      () async {
        final (container, events) = await _loaded();
        final before = _occurrencesVersion(container);

        final updated = await container
            .read(clEventsMasterProvider.notifier)
            .drop(5, version: 7, reason: 'Rink closed');

        expect(events.calls, ['drop(5, v7, Rink closed)']);
        expect(container.read(clEventsMasterProvider).value![5], updated);
        expect(_occurrencesVersion(container), before + 1);
      },
    );

    test('Issue 40: reinstate sends the occurrence version', () async {
      final (container, events) = await _loaded();
      final before = _occurrencesVersion(container);

      final updated = await container
          .read(clEventsMasterProvider.notifier)
          .reinstate(5, version: 8);

      expect(events.calls, ['reinstate(5, v8)']);
      expect(container.read(clEventsMasterProvider).value![5], updated);
      expect(_occurrencesVersion(container), before + 1);
    });

    test(
      'Issue 40: a stale drop reloads the occurrences and rethrows',
      () async {
        final (container, events) = await _loaded();
        events.error = const StaleVersionException(
          message: 'stale',
          version: 9,
        );
        final before = _occurrencesVersion(container);

        await expectLater(
          container
              .read(clEventsMasterProvider.notifier)
              .drop(5, version: 7, reason: 'Rink closed'),
          throwsA(isA<StaleVersionException>()),
        );

        expect(_occurrencesVersion(container), before + 1);
      },
    );

    test(
      'Issue 40: any other refusal leaves the event and occurrences alone',
      () async {
        final (container, events) = await _loaded();
        events.error = const ServerException(
          statusCode: 422,
          code: SdkErrorCode.invalidState,
          message: 'started',
        );
        final before = _occurrencesVersion(container);

        await expectLater(
          container
              .read(clEventsMasterProvider.notifier)
              .reinstate(
                5,
                version: 7,
              ),
          throwsA(isA<ServerException>()),
        );

        expect(_occurrencesVersion(container), before);
        expect(container.read(clEventsMasterProvider).value![5]!.version, 2);
      },
    );
  });
}
