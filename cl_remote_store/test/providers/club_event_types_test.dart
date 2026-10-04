import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Serves one event per type, filtered as the server filters `eventType`,
/// and records which types were asked for (null: unfiltered).
class _TypedEvents extends Fake implements EventSource {
  final List<EventType?> requested = [];

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
    requested.add(eventType);
    final items = [
      for (final type in EventType.values)
        if (eventType == null || eventType == type) _event(type),
    ];
    return PaginatedList<Event>(
      items: items,
      total: items.length,
      offset: 0,
      limit: limit ?? 100,
    );
  }
}

/// Records which types each occurrence query asked for.
class _TypedOccurrences extends Fake implements OccurrenceSource {
  final List<EventType?> requested = [];

  @override
  Future<List<Occurrence>> listOccurrences({
    required DateTime fromTimeUtc,
    required DateTime toTimeUtc,
    EventType? eventType,
    Visibility? visibility,
    int? limit,
    int? offset,
  }) async {
    requested.add(eventType);
    return const [];
  }
}

Event _event(EventType type) => Event(
  id: type.index + 1,
  version: 1,
  title: type.name,
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 6),
  endTimeUtc: DateTime.utc(2026, 6, 1, 2),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

ProviderContainer _container({
  required EventSource events,
  OccurrenceSource? occurrences,
  Set<EventType>? types,
}) => ProviderContainer(
  overrides: [
    secureClientProvider.overrideWith(
      (ref) async => fakeSecureClient(events: events, occurrences: occurrences),
    ),
    if (types != null) clubEventTypesProvider.overrideWithValue(types),
  ],
);

void main() {
  group('Issue 115: staff events follow the club event types', () {
    test('Issue 115: a club that configures nothing sees camps only', () async {
      final events = _TypedEvents();
      final container = _container(events: events);
      addTearDown(container.dispose);

      final master = await container.read(clEventsMasterProvider.future);

      expect(events.requested, [EventType.camp]);
      expect(master.values.map((e) => e.type), [EventType.camp]);
    });

    test(
      'Issue 115: camps and programmes are both fetched, nothing else',
      () async {
        final events = _TypedEvents();
        final container = _container(
          events: events,
          types: {EventType.camp, EventType.programme},
        );
        addTearDown(container.dispose);

        final master = await container.read(clEventsMasterProvider.future);

        expect(
          events.requested,
          unorderedEquals(<EventType>[
            EventType.camp,
            EventType.programme,
          ]),
        );
        expect(
          master.values.map((e) => e.type).toSet(),
          {EventType.camp, EventType.programme},
        );
      },
    );

    test('Issue 115: every type is one unfiltered fetch', () async {
      final events = _TypedEvents();
      final container = _container(
        events: events,
        types: EventType.values.toSet(),
      );
      addTearDown(container.dispose);

      final master = await container.read(clEventsMasterProvider.future);

      expect(events.requested, [null]);
      expect(master, hasLength(EventType.values.length));
    });

    test(
      'Issue 115: the occurrence feed asks for the configured types',
      () async {
        final occurrences = _TypedOccurrences();
        final container = _container(
          events: _TypedEvents(),
          occurrences: occurrences,
          types: {EventType.programme},
        );
        addTearDown(container.dispose);
        final key = (
          from: DateTime.utc(2026, 6),
          to: DateTime.utc(2026, 6, 2),
        );
        final sub = container.listen(clOccurrencesProvider(key), (_, _) {});
        addTearDown(sub.close);

        await container.read(clOccurrencesProvider(key).future);

        expect(occurrences.requested, [EventType.programme]);
      },
    );
  });
}
