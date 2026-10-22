import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// What one basic marketing write sent.
typedef _Sent = ({
  String verb,
  int version,
  String? shortDescription,
  String? stamp,
  List<String>? highlights,
  List<String>? includes,
});

/// Fake [EventSource] recording the basic marketing fields each write sent
/// and applying them to its store.
class _FakeEvents extends Fake implements EventSource {
  _FakeEvents(List<Event> seed) {
    for (final event in seed) {
      store[event.id] = event;
    }
  }

  final Map<int, Event> store = {};
  final List<_Sent> sent = [];

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
    final items = store.values.where((e) => e.type == eventType).toList();
    return PaginatedList<Event>(
      items: items,
      total: items.length,
      offset: 0,
      limit: limit ?? 100,
    );
  }

  Event apply(
    String verb,
    int eventId,
    int version,
    String? Function()? shortDescription,
    String? Function()? stamp,
    List<String>? Function()? highlights,
    List<String>? Function()? includes,
  ) {
    sent.add((
      verb: verb,
      version: version,
      shortDescription: shortDescription?.call(),
      stamp: stamp?.call(),
      highlights: highlights?.call(),
      includes: includes?.call(),
    ));
    final updated = store[eventId]!.copyWith(
      shortDescription: shortDescription,
      stamp: stamp,
      highlights: highlights,
      includes: includes,
      version: version + 1,
    );
    store[eventId] = updated;
    return updated;
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
    List<Gender> Function()? genders,
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
    bool acceptConflicts = false,
  }) async => apply(
    'update',
    eventId,
    version,
    shortDescription,
    stamp,
    highlights,
    includes,
  );

  @override
  Future<Event> correctionOnEvent(
    int eventId, {
    required int version,
    String? title,
    String? description,
    Visibility? visibility,
    List<Gender> Function()? genders,
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
  }) async => apply(
    'correction',
    eventId,
    version,
    shortDescription,
    stamp,
    highlights,
    includes,
  );
}

Event _event(int id, EventType type) => Event(
  id: id,
  version: 3,
  title: 'workflow_$id',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 6),
  endTimeUtc: DateTime.utc(2026, 6, 1, 2),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  stamp: 'OLD',
);

void main() {
  group('Issue 1: the basic marketing write', () {
    late _FakeEvents fake;
    late ProviderContainer container;

    setUp(() async {
      fake = _FakeEvents([
        _event(1, EventType.camp),
        _event(2, EventType.programme),
      ]);
      container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          clubEventTypesProvider.overrideWithValue({
            EventType.camp,
            EventType.programme,
          }),
          secureClientProvider.overrideWith(
            (ref) async => fakeSecureClient(events: fake),
          ),
        ],
      );
      await container.read(clEventsMasterProvider.future);
    });

    tearDown(() => container.dispose());

    test(
      "Issue 1: a camp's goes through updateEvent with its version",
      () async {
        final updated = await container
            .read(clEventsMasterProvider.notifier)
            .updateBasicMarketing(
              fake.store[1]!,
              shortDescription: () => 'Learn to skate',
              highlights: () => ['Skating basics'],
            );

        expect(fake.sent.single.verb, 'update');
        expect(fake.sent.single.version, 3);
        expect(fake.sent.single.shortDescription, 'Learn to skate');
        expect(fake.sent.single.highlights, ['Skating basics']);
        expect(updated.stamp, 'OLD', reason: 'an omitted field is left alone');
        expect(
          container.read(clEventsMasterProvider).valueOrNull?[1]?.version,
          4,
          reason: "the master holds the server's answer",
        );
      },
    );

    test("Issue 1: a programme's goes through correctionOnEvent", () async {
      final updated = await container
          .read(clEventsMasterProvider.notifier)
          .updateBasicMarketing(fake.store[2]!, stamp: () => null);

      expect(fake.sent.single.verb, 'correction');
      expect(updated.stamp, isNull, reason: 'a getter giving null clears');
    });
  });
}
