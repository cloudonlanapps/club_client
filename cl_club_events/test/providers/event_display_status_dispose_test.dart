import 'dart:async';

import 'package:cl_club_events/src/models/event_display_status.dart';
import 'package:cl_club_events/src/providers/event_display_status.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime.now().toUtc();

Event _event(int id, {bool? hasEnded}) => Event(
  id: id,
  version: 1,
  title: 'event_$id',
  description: '',
  type: EventType.oneOff,
  visibility: Visibility.public,
  venueId: 1,
  hasEnded: hasEnded,
  startTimeUtc: _now.subtract(const Duration(hours: 1)),
  endTimeUtc: _now.add(const Duration(hours: 1)),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

class _Events extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async => {1: _event(1), 2: _event(2)};

  void put(Event event) =>
      state = AsyncData({...state.requireValue, event.id: event});
}

/// A master whose first load never answers.
class _LoadingEvents extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() => Completer<Map<int, Event>>().future;
}

ProviderContainer _container({bool loading = false}) => ProviderContainer(
  overrides: [
    clEventsMasterProvider.overrideWith(
      loading ? _LoadingEvents.new : _Events.new,
    ),
    clEventSchedulesProvider.overrideWith((ref, eventId) async => const []),
  ],
);

void main() {
  group('Issue 290: eventDisplayStatusProvider', () {
    test('Issue 290: disposing the scope that watches it does not '
        'throw', () async {
      final container = _container();
      final sub = container.listen(eventDisplayStatusProvider(1), (_, _) {});
      await container.read(eventDisplayStatusProvider(1).future);
      expect(sub.read().value, EventDisplayStatus.ongoing);

      expect(container.dispose, returnsNormally);
    });

    test('Issue 290: disposing it while the master is still loading does '
        'not throw', () async {
      final container = _container(loading: true)
        ..listen(eventDisplayStatusProvider(1), (_, _) {});
      await container.pump();
      expect(container.read(eventDisplayStatusProvider(1)).isLoading, isTrue);

      expect(container.dispose, returnsNormally);
    });

    test('Issue 290: follows its own event, and a write to another event '
        'leaves it alone', () async {
      final container = _container();
      addTearDown(container.dispose);
      final seen = <AsyncValue<EventDisplayStatus>>[];
      container.listen(
        eventDisplayStatusProvider(1),
        (_, next) => seen.add(next),
        fireImmediately: true,
      );
      await container.read(eventDisplayStatusProvider(1).future);
      final events = container.read(clEventsMasterProvider.notifier) as _Events;

      seen.clear();
      events.put(_event(2, hasEnded: true));
      await container.pump();
      expect(seen, isEmpty);

      events.put(_event(1, hasEnded: true));
      expect(
        await container.read(eventDisplayStatusProvider(1).future),
        EventDisplayStatus.ended,
      );
    });
  });
}
