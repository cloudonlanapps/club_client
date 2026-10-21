import 'package:cl_club_events/src/models/event_list_filter.dart';
import 'package:cl_club_events/src/models/my_events_list_filter.dart';
import 'package:cl_club_events/src/providers/event_list.dart';
import 'package:cl_club_events/src/providers/my_events_list.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime.now().toUtc();

String _rruleUntil(DateTime utc) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${utc.year}${two(utc.month)}${two(utc.day)}T'
      '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
}

Event _event(
  int id,
  EventType type, {
  required DateTime start,
  required String rrule,
  DateTime? untilTimeUtc,
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
  startTimeUtc: start,
  endTimeUtc: start.add(const Duration(hours: 1)),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

/// A five-day camp whose first session ended yesterday.
final Event _runningCamp = _event(
  1,
  EventType.camp,
  start: _now.subtract(const Duration(hours: 26)),
  rrule: 'FREQ=DAILY;COUNT=5',
);

/// A weekly programme that started two weeks ago and ends in two months.
final Event _runningProgramme = _event(
  2,
  EventType.programme,
  start: _now.subtract(const Duration(days: 15)),
  rrule:
      'FREQ=WEEKLY;UNTIL='
      '${_rruleUntil(_now.add(const Duration(days: 60)))}',
);

/// A weekly programme whose last session was three weeks ago: it was
/// stopped by a cutoff, as the server ends a programme (its rule carries no
/// UNTIL, and a programme is never past by its rule alone).
final Event _endedProgramme = _event(
  3,
  EventType.programme,
  start: _now.subtract(const Duration(days: 90)),
  rrule: 'FREQ=WEEKLY',
  untilTimeUtc: _now.subtract(const Duration(days: 20)),
);

final List<Event> _all = [_runningCamp, _runningProgramme, _endedProgramme];

class _StaticEvents extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async => {for (final e in _all) e.id: e};
}

void main() {
  group('Issue 210: hiding past events keeps a running series', () {
    test(
      'Issue 210: the event list keeps running series, hides ended ones',
      () async {
        final container = ProviderContainer(
          overrides: [clEventsMasterProvider.overrideWith(_StaticEvents.new)],
        );
        addTearDown(container.dispose);

        final listed = await container.read(
          eventListProvider(const EventListFilter()).future,
        );

        expect(listed.map((e) => e.id).toSet(), {
          _runningCamp.id,
          _runningProgramme.id,
        });
      },
    );

    test(
      'Issue 210: My Events keeps running series, hides ended ones',
      () async {
        const member = 'member210';
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
            const MyEventsListFilter(username: member),
          ).future,
        );

        expect(listed.map((a) => a.event.id).toSet(), {
          _runningCamp.id,
          _runningProgramme.id,
        });
      },
    );
  });
}
