// An event written while the events master is loading stays in the master
// once the load ends (club_client#74).
import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

Event _event(int id) {
  final start = DateTime.utc(2030, 6, id);
  return Event(
    id: id,
    title: 'Event $id',
    description: '',
    type: EventType.camp,
    visibility: Visibility.public,
    venueId: 1,
    startTimeUtc: start,
    endTimeUtc: start.add(const Duration(hours: 1)),
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
  );
}

class _Events extends Fake implements EventSource {
  final Map<int, Event> store = {1: _event(1)};
  Completer<void>? gate;
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
    // The server reads its rows when the request arrives...
    final rows = store.values.where((e) => e.type == eventType).toList();
    // ...and the answer reaches the client later.
    if (gate != null) await gate!.future;
    return PaginatedList<Event>(
      items: rows,
      total: rows.length,
      offset: 0,
      limit: limit ?? 100,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #createEvent) {
      store[2] = _event(2);
      return Future<Event>.value(store[2]);
    }
    if (invocation.memberName == #hardDeleteEvent) {
      store.remove(invocation.positionalArguments.single);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

ProviderContainer _container(_Events events) {
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWith((ref) => null),
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(events: events),
      ),
      clubEventTypesProvider.overrideWithValue({EventType.camp}),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<Event> _create(ProviderContainer c) => c
    .read(clEventsMasterProvider.notifier)
    .createEvent(
      title: 'Event 2',
      description: '',
      type: EventType.camp,
      visibility: Visibility.public,
      venueId: 1,
      startTimeUtc: DateTime.utc(2030, 6, 2),
      endTimeUtc: DateTime.utc(2030, 6, 2, 1),
    );

void main() {
  test('Issue 74: an event created while the master reloads stays in the '
      'master', () async {
    final events = _Events();
    final c = _container(events);
    await c.read(clEventsMasterProvider.future);

    events.gate = Completer<void>();
    c.invalidate(clEventsMasterProvider);
    final reload = c.read(clEventsMasterProvider.future);
    await pumpEventQueue();
    expect(events.listCalls, 2, reason: 'the reload has asked the server');

    await _create(c);
    events.gate!.complete();
    final master = await reload;
    await pumpEventQueue();

    expect(master.keys, [1, 2]);
    expect(c.read(clEventsMasterProvider).valueOrNull!.keys, [1, 2]);
  });

  test('Issue 74: an event created during the first load of the master is in '
      'the master once it loads', () async {
    final events = _Events()..gate = Completer<void>();
    final c = _container(events);
    final load = c.read(clEventsMasterProvider.future);
    await pumpEventQueue();
    expect(events.listCalls, 1);

    await _create(c);
    events.gate!.complete();
    await load;
    await pumpEventQueue();

    expect(c.read(clEventsMasterProvider).valueOrNull!.keys, [1, 2]);
  });

  test('Issue 74: an event deleted for good while the master reloads stays '
      'out of the master', () async {
    final events = _Events();
    final c = _container(events);
    await c.read(clEventsMasterProvider.future);

    events.gate = Completer<void>();
    c.invalidate(clEventsMasterProvider);
    final reload = c.read(clEventsMasterProvider.future);
    await pumpEventQueue();
    expect(events.listCalls, 2, reason: 'the reload has asked the server');

    await c.read(clEventsMasterProvider.notifier).hardDeleteEvent(1);
    events.gate!.complete();
    final master = await reload;
    await pumpEventQueue();

    expect(master, isEmpty);
    expect(c.read(clEventsMasterProvider).valueOrNull, isEmpty);
  });
}
