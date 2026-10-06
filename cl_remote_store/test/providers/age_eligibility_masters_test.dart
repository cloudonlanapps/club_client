import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// The age band (club_client#33) reaches the SDK through the events and
/// groups masters: `minAge`, `maxAge` and `strictAge`, and no dates.

/// What one write carried: the two getters as given (null = left out) and
/// the strict flag.
class _Band {
  _Band(this.minAge, this.maxAge, {required this.strictAge});
  final Age? Function()? minAge;
  final Age? Function()? maxAge;
  final bool? strictAge;
}

class _FakeEvents extends Fake implements EventSource {
  final Event stored = Event(
    id: 1,
    version: 3,
    title: 'workflow_age',
    description: '',
    type: EventType.camp,
    visibility: Visibility.public,
    venueId: 1,
    startTimeUtc: DateTime.utc(2026, 6, 1, 6),
    endTimeUtc: DateTime.utc(2026, 6, 1, 8),
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
  );
  final List<_Band> updates = [];
  final List<_Band> corrections = [];
  ({Age? minAge, Age? maxAge, bool? strictAge})? created;

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
    items: [stored],
    total: 1,
    offset: 0,
    limit: limit ?? 100,
  );

  @override
  Future<Event> createEvent({
    required String title,
    required String description,
    required EventType type,
    required Visibility visibility,
    required int venueId,
    required DateTime startTimeUtc,
    required DateTime endTimeUtc,
    String? organizerName,
    List<String>? coachNames,
    String? rrule,
    Gender? gender,
    Age? minAge,
    Age? maxAge,
    bool? strictAge,
    bool isFeatured = false,
    List<String>? galleryUris,
    String? shortDescription,
    String? stamp,
    List<String>? highlights,
    List<String>? includes,
    List<EventSession>? sessions,
  }) async {
    created = (minAge: minAge, maxAge: maxAge, strictAge: strictAge);
    return stored.copyWith(
      id: 2,
      minAge: () => minAge,
      maxAge: () => maxAge,
      strictAge: strictAge,
    );
  }

  @override
  Future<Event> updateEvent(
    int eventId, {
    required int version,
    String? title,
    String? description,
    Visibility? visibility,
    String? organizerName,
    List<String>? Function()? coachNames,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    String? Function()? shortDescription,
    String? Function()? stamp,
    List<String>? Function()? highlights,
    List<String>? Function()? includes,
    List<EventSession>? Function()? sessions,
  }) async {
    updates.add(_Band(minAge, maxAge, strictAge: strictAge));
    return stored.copyWith(
      version: version + 1,
      minAge: minAge,
      maxAge: maxAge,
      strictAge: strictAge,
    );
  }

  @override
  Future<Event> correctionOnEvent(
    int eventId, {
    required int version,
    String? title,
    String? description,
    Visibility? visibility,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    String? Function()? shortDescription,
    String? Function()? stamp,
    List<String>? Function()? highlights,
    List<String>? Function()? includes,
    List<EventSession>? Function()? sessions,
    int? scheduleId,
  }) async {
    corrections.add(_Band(minAge, maxAge, strictAge: strictAge));
    return stored.copyWith(
      version: version + 1,
      minAge: minAge,
      maxAge: maxAge,
      strictAge: strictAge,
    );
  }
}

class _FakeGroups extends Fake implements GroupSource {
  final Group stored = Group(
    id: 7,
    name: 'workflow_age_group',
    kind: GroupKind.semiAuto,
    createdAtUtc: DateTime.utc(2026),
  );
  final List<_Band> updates = [];
  ({Age? minAge, Age? maxAge, bool? strictAge})? created;

  @override
  Future<PaginatedList<Group>> getGroups({
    int offset = 0,
    int limit = 20,
  }) async =>
      PaginatedList<Group>(items: [stored], total: 1, offset: 0, limit: limit);

  @override
  Future<Group> createGroup({
    required String name,
    String? description,
    Age? minAge,
    Age? maxAge,
    bool? strictAge,
    Gender? gender,
    bool? semiAuto,
  }) async {
    created = (minAge: minAge, maxAge: maxAge, strictAge: strictAge);
    return stored.copyWith(
      id: 8,
      minAge: () => minAge,
      maxAge: () => maxAge,
      strictAge: strictAge,
    );
  }

  @override
  Future<Group> updateGroup(
    int id, {
    String? name,
    String? Function()? description,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    Gender? Function()? gender,
    bool? semiAuto,
  }) async {
    updates.add(_Band(minAge, maxAge, strictAge: strictAge));
    return stored.copyWith(
      minAge: minAge,
      maxAge: maxAge,
      strictAge: strictAge,
    );
  }
}

ProviderContainer _container({EventSource? events, GroupSource? groups}) {
  final container = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(events: events, groups: groups),
      ),
      currentUserProvider.overrideWith((ref) => null),
      clubEventTypesProvider.overrideWithValue(const {
        EventType.camp,
        EventType.programme,
        EventType.oneOff,
      }),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

const _five = Age(years: 5);
const _eighteen = Age(years: 18);

void main() {
  group('Issue 33: the events master sends the age band', () {
    test('Issue 33: updateEvent forwards minAge, maxAge and strictAge and '
        'keeps the answer', () async {
      final fake = _FakeEvents();
      final container = _container(events: fake);
      await container.read(clEventsMasterProvider.future);

      final updated = await container
          .read(clEventsMasterProvider.notifier)
          .updateEvent(
            1,
            minAge: () => _five,
            maxAge: () => _eighteen,
            strictAge: true,
          );

      expect(fake.updates.single.minAge!(), _five);
      expect(fake.updates.single.maxAge!(), _eighteen);
      expect(fake.updates.single.strictAge, isTrue);
      expect(updated.minAge, _five);
      expect(container.read(clEventsMasterProvider).value![1], updated);
    });

    test('Issue 33: a getter returning null clears that bound; an omitted '
        'one is left out', () async {
      final fake = _FakeEvents();
      final container = _container(events: fake);
      await container.read(clEventsMasterProvider.future);

      await container
          .read(clEventsMasterProvider.notifier)
          .updateEvent(1, maxAge: () => null);

      expect(fake.updates.single.minAge, isNull);
      expect(fake.updates.single.maxAge, isNotNull);
      expect(fake.updates.single.maxAge!(), isNull);
      expect(fake.updates.single.strictAge, isNull);
    });

    test('Issue 33: correctionOnEvent forwards the age band', () async {
      final fake = _FakeEvents();
      final container = _container(events: fake);
      await container.read(clEventsMasterProvider.future);

      await container
          .read(clEventsMasterProvider.notifier)
          .correctionOnEvent(
            1,
            minAge: () => _five,
            maxAge: () => null,
            strictAge: false,
          );

      expect(fake.corrections.single.minAge!(), _five);
      expect(fake.corrections.single.maxAge!(), isNull);
      expect(fake.corrections.single.strictAge, isFalse);
    });

    test('Issue 33: createEvent forwards the age band', () async {
      final fake = _FakeEvents();
      final container = _container(events: fake);
      await container.read(clEventsMasterProvider.future);

      await container
          .read(clEventsMasterProvider.notifier)
          .createEvent(
            title: 'workflow_age_new',
            description: '',
            type: EventType.camp,
            visibility: Visibility.public,
            venueId: 1,
            startTimeUtc: DateTime.utc(2026, 6, 1, 6),
            endTimeUtc: DateTime.utc(2026, 6, 1, 8),
            minAge: _five,
            maxAge: _eighteen,
            strictAge: true,
          );

      expect(fake.created, (minAge: _five, maxAge: _eighteen, strictAge: true));
    });
  });

  group('Issue 33: the groups master sends the age band', () {
    test(
      'Issue 33: createGroup forwards minAge, maxAge and strictAge',
      () async {
        final fake = _FakeGroups();
        final container = _container(groups: fake);
        await container.read(clGroupsMasterProvider.future);

        final created = await container
            .read(clGroupsMasterProvider.notifier)
            .createGroup(
              name: 'workflow_age_group_new',
              minAge: _five,
              maxAge: _eighteen,
              strictAge: true,
            );

        expect(fake.created, (
          minAge: _five,
          maxAge: _eighteen,
          strictAge: true,
        ));
        expect(container.read(clGroupsMasterProvider).value![8], created);
      },
    );

    test('Issue 33: updateGroup forwards the getters, null clearing a '
        'bound', () async {
      final fake = _FakeGroups();
      final container = _container(groups: fake);
      await container.read(clGroupsMasterProvider.future);

      final updated = await container
          .read(clGroupsMasterProvider.notifier)
          .updateGroup(
            7,
            minAge: () => _five,
            maxAge: () => null,
            strictAge: false,
          );

      expect(fake.updates.single.minAge!(), _five);
      expect(fake.updates.single.maxAge!(), isNull);
      expect(fake.updates.single.strictAge, isFalse);
      expect(container.read(clGroupsMasterProvider).value![7], updated);
    });
  });
}
