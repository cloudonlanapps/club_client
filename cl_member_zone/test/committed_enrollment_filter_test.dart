import 'package:cl_member_zone/src/providers/public_events.dart';
import 'package:cl_member_zone/src/providers/selected_day.dart';
import 'package:cl_member_zone/src/providers/today_my_occurrences.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClMyEventsMasterNotifier,
        clMyEnrollmentProvider,
        clMyEventsMasterProvider,
        clMyOccurrencesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Today, in the far future, so no occurrence has ended yet.
final _day = DateTime(2099, 1, 1);

Occurrence _occurrence(int eventId) => Occurrence(
  eventId: eventId,
  originalStartTimeUtc: _day.add(const Duration(hours: 10)).toUtc(),
  actualStartTimeUtc: _day.add(const Duration(hours: 10)).toUtc(),
  actualEndTimeUtc: _day.add(const Duration(hours: 11)).toUtc(),
  status: OccurrenceStatus.scheduled,
  venueId: 1,
);

/// The user's enrollment in events 1-5: two committed, the rest not.
const _statuses = <int, EnrollmentStatus?>{
  1: EnrollmentStatus.accepted,
  2: EnrollmentStatus.withdrawRequested,
  3: EnrollmentStatus.requested,
  4: EnrollmentStatus.withdrawn,
  5: null,
};

class _Events extends ClMyEventsMasterNotifier {
  @override
  Future<List<Event>> build(String arg) async => [
    for (final id in _statuses.keys)
      Event(
        id: id,
        title: 'Event $id',
        description: '',
        type: EventType.oneOff,
        visibility: Visibility.public,
        venueId: 1,
        startTimeUtc: _day.toUtc(),
        endTimeUtc: _day.add(const Duration(days: 1)).toUtc(),
        createdAtUtc: DateTime.utc(2026),
        updatedAtUtc: DateTime.utc(2026),
      ),
  ];
}

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [
      selectedDayProvider.overrideWithValue(_day),
      clMyOccurrencesProvider.overrideWith(
        (ref, key) async => [for (final id in _statuses.keys) _occurrence(id)],
      ),
      clMyEnrollmentProvider.overrideWith((ref, key) async {
        final status = _statuses[key.eventId];
        if (status == null) return null;
        return Enrollment(
          id: key.eventId,
          membername: key.username,
          eventId: key.eventId,
          status: status,
          createdAtUtc: DateTime.utc(2026),
        );
      }),
      clMyEventsMasterProvider.overrideWith(_Events.new),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test(
    'Issue 208: My Events keeps the events the user is committed to',
    () async {
      final c = _container();
      final mine = await c.read(todayMyOccurrencesProvider('asha').future);
      expect(mine.map((o) => o.eventId), [1, 2]);
    },
  );

  test('Issue 208: Public Events keeps the rest', () async {
    final c = _container();
    final public = await c.read(todayPublicOccurrencesProvider('asha').future);
    expect(public.map((o) => o.eventId), [3, 4, 5]);
  });
}
