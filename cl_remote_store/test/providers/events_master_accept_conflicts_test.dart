import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// The clash the fakes refuse a write with until it is accepted.
final ScheduleConflictException _clash = ScheduleConflictException(
  message: 'clash',
  report: ConflictReport(
    coachConflicts: [
      EventConflictItem(
        eventId: 9,
        eventTitle: 'Evening skate',
        eventType: 'programme',
        occurrences: [
          OccurrencePair(
            targetStartUtc: DateTime.utc(2030, 6, 1, 17),
            targetEndUtc: DateTime.utc(2030, 6, 1, 18),
            otherStartUtc: DateTime.utc(2030, 6, 1, 17, 30),
            otherEndUtc: DateTime.utc(2030, 6, 1, 18, 30),
          ),
        ],
      ),
    ],
  ),
);

/// Fake [EventSource] recording the `acceptConflicts` each schedule write
/// sends, and refusing one that does not accept with [_clash] while
/// [clashing].
class _FakeEvents extends Fake implements EventSource {
  _FakeEvents(this.event);

  Event event;
  bool clashing = false;
  final List<String> calls = [];

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

  Event answer(String call, {required bool acceptConflicts}) {
    calls.add('$call(accept: $acceptConflicts)');
    if (clashing && !acceptConflicts) throw _clash;
    return event = event.copyWith(version: event.version + 1);
  }

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
    List<Gender>? genders,
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
    bool acceptConflicts = false,
  }) async => answer('create', acceptConflicts: acceptConflicts);

  @override
  Future<Event> updateEvent(
    int eventId, {
    required int version,
    String? title,
    String? description,
    Visibility? visibility,
    String? organizerName,
    List<String>? Function()? coachNames,
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
  }) async => answer('update', acceptConflicts: acceptConflicts);

  @override
  Future<Event> rescheduleEvent(
    int eventId, {
    required int version,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    String? rrule,
    int? venueId,
    List<EventSession>? Function()? sessions,
    bool resetOverrides = false,
    bool acceptConflicts = false,
  }) async => answer('reschedule', acceptConflicts: acceptConflicts);

  @override
  Future<Event> updateEventForAllFuture(
    int eventId, {
    required int version,
    required DateTime effectiveDateTimeUtc,
    int? venueId,
    String? organizerName,
    List<String>? Function()? coachNames,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    String? rrule,
    List<EventSession>? Function()? sessions,
    bool acceptConflicts = false,
  }) async => answer('split', acceptConflicts: acceptConflicts);

  @override
  Future<Event> reinstate(
    int eventId, {
    required int version,
    bool acceptConflicts = false,
  }) async => answer('reinstate', acceptConflicts: acceptConflicts);
}

/// Fake [OccurrenceSource] recording the `acceptConflicts` a reschedule
/// sends, refusing one that does not accept while [clashing].
class _FakeOccurrences extends Fake implements OccurrenceSource {
  bool clashing = false;
  final List<String> calls = [];

  @override
  Future<void> rescheduleOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
    DateTime? newStartTimeUtc,
    int? newDurationMinutes,
    int? newVenueId,
    bool acceptConflicts = false,
  }) async {
    calls.add('occurrence(accept: $acceptConflicts)');
    if (clashing && !acceptConflicts) throw _clash;
  }
}

Event _event() => Event(
  id: 5,
  version: 2,
  title: 'test_clash_event',
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2030, 6),
  endTimeUtc: DateTime.utc(2030, 6, 1, 2),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

typedef _Loaded = ({
  ProviderContainer container,
  _FakeEvents events,
  _FakeOccurrences occurrences,
});

Future<_Loaded> _loaded() async {
  final events = _FakeEvents(_event());
  final occurrences = _FakeOccurrences();
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWithValue(null),
      clubEventTypesProvider.overrideWithValue(EventType.values.toSet()),
      secureClientProvider.overrideWith(
        (ref) async =>
            fakeSecureClient(events: events, occurrences: occurrences),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(clEventsMasterProvider.future);
  return (container: container, events: events, occurrences: occurrences);
}

/// Each master write that takes `acceptConflicts`, called with `accept`.
Map<
  String,
  Future<Object?> Function(ClEventsMasterNotifier, {required bool accept})
>
_writes() => {
  'create': (n, {required accept}) => n.createEvent(
    title: 'test_clash_event',
    description: '',
    type: EventType.camp,
    visibility: Visibility.public,
    venueId: 1,
    startTimeUtc: DateTime.utc(2030, 6),
    endTimeUtc: DateTime.utc(2030, 6, 1, 2),
    acceptConflicts: accept,
  ),
  'update': (n, {required accept}) =>
      n.updateEvent(5, organizerName: 'coach_b', acceptConflicts: accept),
  'reschedule': (n, {required accept}) => n.rescheduleEvent(
    5,
    startTimeUtc: DateTime.utc(2030, 6, 2),
    acceptConflicts: accept,
  ),
  'split': (n, {required accept}) => n.updateEventForAllFuture(
    5,
    effectiveDateTimeUtc: DateTime.utc(2030, 6, 8),
    venueId: 3,
    acceptConflicts: accept,
  ),
  'reinstate': (n, {required accept}) =>
      n.reinstate(5, version: 4, acceptConflicts: accept),
  'occurrence': (n, {required accept}) => n.rescheduleOccurrence(
    5,
    DateTime.utc(2030, 6),
    version: 1,
    newStartTimeUtc: DateTime.utc(2030, 6, 1, 3),
    acceptConflicts: accept,
  ),
};

/// The calls the fakes recorded, events first.
List<String> _calls(_Loaded loaded) => [
  ...loaded.events.calls,
  ...loaded.occurrences.calls,
];

void main() {
  group('Issue 278: the events master forwards acceptConflicts', () {
    for (final MapEntry(key: name, value: write) in _writes().entries) {
      test('Issue 278: $name sends acceptConflicts false by default', () async {
        final loaded = await _loaded();
        final notifier = loaded.container.read(clEventsMasterProvider.notifier);

        await write(notifier, accept: false);

        expect(_calls(loaded), ['$name(accept: false)']);
      });

      test('Issue 278: $name sends acceptConflicts true when asked', () async {
        final loaded = await _loaded();
        final notifier = loaded.container.read(clEventsMasterProvider.notifier);

        await write(notifier, accept: true);

        expect(_calls(loaded), ['$name(accept: true)']);
      });

      test(
        'Issue 278: a clash on $name rethrows the report and changes '
        'nothing held',
        () async {
          final loaded = await _loaded();
          loaded.events.clashing = true;
          loaded.occurrences.clashing = true;
          final container = loaded.container;
          final notifier = container.read(clEventsMasterProvider.notifier);
          final heldBefore = container.read(clEventsMasterProvider).value;
          final occurrencesBefore = container
              .read(clResourceVersionProvider)
              .occurrencesVersion;

          await expectLater(
            write(notifier, accept: false),
            throwsA(
              isA<ScheduleConflictException>().having(
                (e) => e.report.coachConflicts.single.eventTitle,
                'clashing coach event',
                'Evening skate',
              ),
            ),
          );

          // A 409 is a definite "not written": no reload, nothing replaced.
          expect(container.read(clEventsMasterProvider).value, heldBefore);
          expect(
            container.read(clResourceVersionProvider).occurrencesVersion,
            occurrencesBefore,
          );
        },
      );

      test('Issue 278: $name accepted after a clash is written', () async {
        final loaded = await _loaded();
        loaded.events.clashing = true;
        loaded.occurrences.clashing = true;
        final notifier = loaded.container.read(clEventsMasterProvider.notifier);

        await expectLater(
          write(notifier, accept: false),
          throwsA(isA<ScheduleConflictException>()),
        );
        await write(notifier, accept: true);

        expect(_calls(loaded), [
          '$name(accept: false)',
          '$name(accept: true)',
        ]);
      });
    }
  });
}
