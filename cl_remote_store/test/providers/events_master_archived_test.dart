import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [EventSource] with a live and an archived listing, as the server's
/// `GET /events` and `GET /events/deleted`.
class _FakeEvents extends Fake implements EventSource {
  _FakeEvents(Iterable<Event> seed) {
    for (final e in seed) {
      store[e.id] = e;
    }
  }

  final Map<int, Event> store = {};
  int deletedListCalls = 0;

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
    final live = store.values
        .where((e) => e.isActive)
        .where((e) => eventType == null || e.type == eventType)
        .toList();
    return PaginatedList<Event>(
      items: live,
      total: live.length,
      offset: 0,
      limit: limit ?? 100,
    );
  }

  @override
  Future<PaginatedList<Event>> listDeletedEvents({
    int offset = 0,
    int limit = 20,
  }) async {
    deletedListCalls++;
    final archived = store.values.where((e) => !e.isActive).toList();
    return PaginatedList<Event>(
      items: archived,
      total: archived.length,
      offset: 0,
      limit: limit,
    );
  }

  @override
  Future<Event> restoreEvent(int eventId) async {
    final restored = store[eventId]!.copyWith(deletedAtUtc: () => null);
    store[eventId] = restored;
    return restored;
  }

  @override
  Future<void> hardDeleteEvent(int eventId) async {
    store.remove(eventId);
  }
}

Event _event(int id, {EventType type = EventType.camp, bool archived = false}) {
  final start = DateTime.utc(2030, 6, id);
  return Event(
    id: id,
    title: 'Event $id',
    description: '',
    type: type,
    visibility: Visibility.public,
    venueId: 1,
    startTimeUtc: start,
    endTimeUtc: start.add(const Duration(hours: 1)),
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
    deletedAtUtc: archived ? DateTime.utc(2026, 2) : null,
  );
}

UserInfo _user({bool admin = false, bool superAdmin = false}) => UserInfo(
  username: 'viewer',
  displayName: 'viewer',
  status: UserStatus.active,
  isSuperAdmin: superAdmin,
  roles: UserRoles(isAdmin: admin, isCoach: !admin && !superAdmin),
);

ProviderContainer _container(
  _FakeEvents events, {
  required UserInfo? viewer,
  Set<EventType>? types,
}) {
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWith((ref) => viewer),
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(events: events),
      ),
      if (types != null) clubEventTypesProvider.overrideWithValue(types),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Issue 36: the events master and archived events', () {
    test('Issue 36: an admin also loads the archived events', () async {
      final events = _FakeEvents([_event(1), _event(2, archived: true)]);
      final container = _container(events, viewer: _user(admin: true));

      final master = await container.read(clEventsMasterProvider.future);

      expect(master.keys, unorderedEquals([1, 2]));
      expect(master[2]!.isActive, isFalse);
      expect(events.deletedListCalls, 1);
    });

    test('Issue 36: a super admin also loads the archived events', () async {
      final events = _FakeEvents([_event(1), _event(2, archived: true)]);
      final container = _container(events, viewer: _user(superAdmin: true));

      final master = await container.read(clEventsMasterProvider.future);

      expect(master.keys, unorderedEquals([1, 2]));
    });

    test(
      'Issue 36: a coach never asks for the archived events',
      () async {
        final events = _FakeEvents([_event(1), _event(2, archived: true)]);
        final container = _container(events, viewer: _user());

        final master = await container.read(clEventsMasterProvider.future);

        expect(master.keys, [1]);
        expect(events.deletedListCalls, 0);
      },
    );

    test(
      'Issue 36: archived events of a type the club does not run are left out',
      () async {
        final events = _FakeEvents([
          _event(1),
          _event(2, archived: true),
          _event(3, type: EventType.programme, archived: true),
        ]);
        final container = _container(
          events,
          viewer: _user(admin: true),
          types: const {EventType.camp},
        );

        final master = await container.read(clEventsMasterProvider.future);

        expect(master.keys, unorderedEquals([1, 2]));
      },
    );

    test(
      'Issue 36: the active listing leaves archived events out',
      () async {
        final events = _FakeEvents([_event(1), _event(2, archived: true)]);
        final container = _container(events, viewer: _user(admin: true));
        final sub = container.listen(
          clEventsProvider(
            (
              eventType: null,
              visibility: null,
              searchTerm: null,
              includePast: true,
            ),
          ),
          (_, _) {},
        );
        addTearDown(sub.close);

        final listed = await container.read(
          clEventsProvider(
            (
              eventType: null,
              visibility: null,
              searchTerm: null,
              includePast: true,
            ),
          ).future,
        );

        expect(listed.map((e) => e.id), [1]);
      },
    );

    test('Issue 36: restoring an archived event makes it active', () async {
      final events = _FakeEvents([_event(2, archived: true)]);
      final container = _container(events, viewer: _user(admin: true));
      await container.read(clEventsMasterProvider.future);

      await container.read(clEventsMasterProvider.notifier).restoreEvent(2);

      expect(container.read(clEventsMasterProvider).value![2]!.isActive, true);
    });

    test('Issue 36: a hard delete drops the event from the map', () async {
      final events = _FakeEvents([_event(2, archived: true)]);
      final container = _container(events, viewer: _user(superAdmin: true));
      await container.read(clEventsMasterProvider.future);

      await container.read(clEventsMasterProvider.notifier).hardDeleteEvent(2);

      expect(container.read(clEventsMasterProvider).value, isEmpty);
    });
  });
}
