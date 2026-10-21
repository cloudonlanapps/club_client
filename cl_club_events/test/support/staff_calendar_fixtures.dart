/// A staff calendar backed by a fake occurrence source and a fixed events
/// master, so the calendar providers (`dayEventCountsProvider`,
/// `dateItemsNotifierProvider`) run their own code against known data.
library;

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves [occurrences], filtered by event type as the server filters
/// `eventType` (null: every type).
class TypedOccurrenceSource extends Fake implements OccurrenceSource {
  TypedOccurrenceSource(this.occurrences, this.typeOf);

  final List<Occurrence> occurrences;
  final Map<int, EventType> typeOf;

  @override
  Future<List<Occurrence>> listOccurrences({
    required DateTime fromTimeUtc,
    required DateTime toTimeUtc,
    EventType? eventType,
    Visibility? visibility,
    int? limit,
    int? offset,
  }) async => [
    for (final occ in occurrences)
      if (eventType == null || typeOf[occ.eventId] == eventType) occ,
  ];
}

class _Client extends Fake implements SecureClient {
  _Client(this.occurrences);

  @override
  final OccurrenceSource occurrences;
}

class _StaticEvents extends ClEventsMasterNotifier {
  _StaticEvents(this.events);
  final Map<int, Event> events;
  @override
  Future<Map<int, Event>> build() async => events;
}

/// An event of [type] with [id].
Event calendarEvent(int id, EventType type) => Event(
  id: id,
  version: 1,
  title: '${type.name}_$id',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 10),
  endTimeUtc: DateTime.utc(2026, 10, 1, 1),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

/// A one-hour scheduled session of event [eventId] starting at [startUtc].
Occurrence calendarOccurrence(int eventId, DateTime startUtc) => Occurrence(
  eventId: eventId,
  originalStartTimeUtc: startUtc,
  actualStartTimeUtc: startUtc,
  actualEndTimeUtc: startUtc.add(const Duration(hours: 1)),
  status: OccurrenceStatus.scheduled,
  venueId: 1,
);

/// A container whose staff occurrence feed serves [occurrences] for the
/// [events] given, and whose club runs [clubTypes].
ProviderContainer staffCalendarContainer({
  required List<Event> events,
  required List<Occurrence> occurrences,
  Set<EventType> clubTypes = const {EventType.camp},
}) {
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWithValue(null),
      clubEventTypesProvider.overrideWithValue(clubTypes),
      secureClientProvider.overrideWith(
        (ref) async => _Client(
          TypedOccurrenceSource(occurrences, {
            for (final e in events) e.id: e.type,
          }),
        ),
      ),
      clEventsMasterProvider.overrideWith(
        () => _StaticEvents({for (final e in events) e.id: e}),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Lets microtasks run until [done] holds, failing after [maxTurns] turns
/// rather than spinning.
Future<void> settle(bool Function() done, {int maxTurns = 200}) async {
  for (var i = 0; i < maxTurns; i++) {
    if (done()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('did not settle after $maxTurns turns');
}
