import 'package:cl_club_events/src/models/event_display_status.dart';
import 'package:cl_club_events/src/models/event_list_filter.dart';
import 'package:cl_club_events/src/models/my_event_phase.dart';
import 'package:cl_club_events/src/models/my_events_list_filter.dart';
import 'package:cl_club_events/src/providers/event_display_status.dart';
import 'package:cl_club_events/src/providers/event_list.dart';
import 'package:cl_club_events/src/providers/my_events_list.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime.now().toUtc();

Event _event(
  int id,
  EventType type, {
  required DateTime start,
  String? rrule,
  DateTime? untilTimeUtc,
  bool? hasEnded,
}) => Event(
  id: id,
  version: 1,
  title: 'event_$id',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 1,
  rrule: rrule,
  untilTimeUtc: untilTimeUtc,
  hasEnded: hasEnded,
  startTimeUtc: start,
  endTimeUtc: start.add(const Duration(hours: 1)),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

/// A five-day camp that started two days ago: its rule runs three more
/// days, but every remaining day was cancelled, so the server says it has
/// ended.
final Event _campAllCancelled = _event(
  1,
  EventType.camp,
  start: _now.subtract(const Duration(days: 2)),
  rrule: 'FREQ=DAILY;COUNT=5',
  hasEnded: true,
);

/// A one-off whose slot ended yesterday but which was postponed to
/// tomorrow: the server says it has not ended.
final Event _postponedOneOff = _event(
  2,
  EventType.oneOff,
  start: _now.subtract(const Duration(days: 1)),
  hasEnded: false,
);

/// A camp whose cutoff has passed: cancelled, whatever the server says
/// about its end.
final Event _cancelledCamp = _event(
  3,
  EventType.camp,
  start: _now.subtract(const Duration(days: 4)),
  rrule: 'FREQ=DAILY;COUNT=5',
  untilTimeUtc: _now.subtract(const Duration(days: 2)),
  hasEnded: true,
);

/// A programme stopped by a cutoff: ended (the server's `isPast` is false
/// for it, `hasEnded` true).
final Event _terminatedProgramme = _event(
  4,
  EventType.programme,
  start: _now.subtract(const Duration(days: 60)),
  rrule: 'FREQ=WEEKLY',
  untilTimeUtc: _now.subtract(const Duration(days: 7)),
  hasEnded: true,
);

final List<Event> _all = [_campAllCancelled, _postponedOneOff];

class _StaticEvents extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async => {for (final e in _all) e.id: e};
}

void main() {
  group("Issue 191: ended is the server's hasEnded", () {
    test('Issue 191: a camp whose remaining days are all cancelled has '
        'ended', () {
      expect(
        computeDisplayStatus(_campAllCancelled, const []),
        EventDisplayStatus.ended,
      );
      expect(MyEventPhase.of(_campAllCancelled), MyEventPhase.past);
    });

    test('Issue 191: a postponed last occurrence has not ended until its '
        'new end', () {
      expect(
        computeDisplayStatus(_postponedOneOff, const []),
        EventDisplayStatus.ongoing,
      );
      expect(MyEventPhase.of(_postponedOneOff), MyEventPhase.current);
    });

    test('Issue 191: the cutoff still tells cancelled from ended', () {
      expect(
        computeDisplayStatus(_cancelledCamp, const []),
        EventDisplayStatus.cancelled,
      );
      expect(MyEventPhase.of(_cancelledCamp), MyEventPhase.cancelled);
      expect(
        computeDisplayStatus(_terminatedProgramme, const []),
        EventDisplayStatus.ended,
      );
      expect(MyEventPhase.of(_terminatedProgramme), MyEventPhase.past);
    });

    test('Issue 191: an event the server has not ended that has not started '
        'is coming soon', () {
      final upcoming = _event(
        5,
        EventType.camp,
        start: _now.add(const Duration(days: 3)),
        rrule: 'FREQ=DAILY;COUNT=2',
        hasEnded: false,
      );
      expect(
        computeDisplayStatus(upcoming, const []),
        EventDisplayStatus.comingSoon,
      );
    });

    test('Issue 191: without hasEnded the local rule still applies', () {
      final pastOneOff = _event(
        6,
        EventType.oneOff,
        start: _now.subtract(const Duration(days: 1)),
      );
      expect(
        computeDisplayStatus(pastOneOff, const []),
        EventDisplayStatus.ended,
      );
    });

    test('Issue 191: the event list hides what the server has ended and '
        'keeps what it has not', () async {
      final container = ProviderContainer(
        overrides: [clEventsMasterProvider.overrideWith(_StaticEvents.new)],
      );
      addTearDown(container.dispose);

      final listed = await container.read(
        eventListProvider(const EventListFilter()).future,
      );

      expect(listed.map((e) => e.id), [_postponedOneOff.id]);
    });

    test('Issue 191: My Events hides what the server has ended and keeps '
        'what it has not', () async {
      final container = ProviderContainer(
        overrides: [
          clMyEventsAggregatedProvider.overrideWith(
            (ref, username) async => [
              for (final e in _all) AggregatedMyEvent(event: e),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final listed = await container.read(
        myEventsListProvider(
          const MyEventsListFilter(username: 'member191'),
        ).future,
      );

      expect(listed.map((a) => a.event.id), [_postponedOneOff.id]);
    });
  });
}
