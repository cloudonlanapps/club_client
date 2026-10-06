import 'package:cl_club_events/src/models/event_timetable_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show EventTimetableValue, SessionInput;

Event _event(EventType type, {List<EventSession>? sessions}) => Event(
  id: 1,
  version: 7,
  title: 'workflow_timetable',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 6, 1, 6),
  endTimeUtc: DateTime.utc(2026, 6, 1, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  sessions: sessions,
);

/// Records the timetable correction the adapter sends.
class _RecordingNotifier extends ClEventsMasterNotifier {
  _RecordingNotifier(this.returnEvent);

  final Event returnEvent;
  final List<String> calls = [];

  static String _describe(List<EventSession>? Function()? sessions) {
    if (sessions == null) return 'omitted';
    final supplied = sessions();
    if (supplied == null) return 'null';
    return supplied.map((s) => '${s.name}:${s.periodMinutes}').join(',');
  }

  @override
  Future<Event> updateEvent(
    int eventId, {
    int? version,
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
    List<EventSession>? Function()? sessions,
  }) async {
    calls.add('update(v$version, ${_describe(sessions)})');
    return returnEvent;
  }

  @override
  Future<Event> correctionOnEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
    int? scheduleId,
  }) async {
    calls.add(
      'correction(v$version, ${_describe(sessions)}, schedule $scheduleId)',
    );
    return returnEvent;
  }
}

const List<SessionInput> _split = [
  SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '06:30'),
  SessionInput(name: 'Drills', startTime: '06:30', endTime: '08:00'),
];

void main() {
  group('Issue 85: EventTimetableFormSubmit.updateTimetable', () {
    for (final type in [EventType.camp, EventType.oneOff]) {
      test(
        'Issue 85: a ${type.name} is corrected through updateEvent',
        () async {
          final event = _event(type);
          final notifier = _RecordingNotifier(event);

          await EventTimetableFormSubmit.updateTimetable(
            event: event,
            value: const EventTimetableValue(sessions: _split),
            notifier: notifier,
          );

          expect(notifier.calls, ['update(v7, Warm-up:30,Drills:90)']);
        },
      );
    }

    test(
      'Issue 85: a programme is corrected on the chosen schedule, no split',
      () async {
        final event = _event(EventType.programme);
        final notifier = _RecordingNotifier(event);

        await EventTimetableFormSubmit.updateTimetable(
          event: event,
          value: const EventTimetableValue(scheduleId: 3, sessions: _split),
          notifier: notifier,
        );

        expect(notifier.calls, [
          'correction(v7, Warm-up:30,Drills:90, schedule 3)',
        ]);
      },
    );

    test('Issue 85: an empty split clears the timetable', () async {
      final event = _event(EventType.camp);
      final notifier = _RecordingNotifier(event);

      await EventTimetableFormSubmit.updateTimetable(
        event: event,
        value: const EventTimetableValue(sessions: []),
        notifier: notifier,
      );

      expect(notifier.calls, ['update(v7, null)']);
    });
  });

  group('Issue 85: buildEventTimetableSchedules', () {
    test("Issue 85: a camp's one schedule round-trips its split", () {
      final options = buildEventTimetableSchedules(
        _event(
          EventType.camp,
          sessions: const [
            EventSession(name: 'Warm-up', periodMinutes: 30),
            EventSession(name: 'Drills', periodMinutes: 90),
          ],
        ),
      );

      expect(options, hasLength(1));
      expect(options.single.id, isNull);
      expect(options.single.totalMinutes, 120);
      expect(
        options.single.sessions.map((s) => s.name),
        ['Warm-up', 'Drills'],
      );
    });

    test(
      'Issue 85: a programme offers each schedule over its own length',
      () {
        final options = buildEventTimetableSchedules(
          _event(EventType.programme),
          schedules: [
            EventSchedule(
              id: 3,
              eventId: 1,
              effectiveFromUtc: DateTime.utc(2026, 6),
              effectiveUntilUtc: DateTime.utc(2026, 7),
              startTimeUtc: DateTime.utc(2026, 6, 1, 6),
              endTimeUtc: DateTime.utc(2026, 6, 1, 7),
              venueId: 1,
            ),
            EventSchedule(
              id: 4,
              eventId: 1,
              effectiveFromUtc: DateTime.utc(2026, 7),
              startTimeUtc: DateTime.utc(2026, 7, 1, 6),
              endTimeUtc: DateTime.utc(2026, 7, 1, 8),
              venueId: 1,
            ),
          ],
        );

        expect(options.map((o) => o.id), [3, 4]);
        expect(options.map((o) => o.totalMinutes), [60, 120]);
        expect(options.last.label, endsWith('(current)'));
        expect(options.first.label, contains('until'));
      },
    );

    test('Issue 85: a programme without its schedules falls back to the '
        'event', () {
      final options = buildEventTimetableSchedules(_event(EventType.programme));

      expect(options, hasLength(1));
      expect(options.single.id, isNull, reason: 'the latest schedule');
    });
  });
}
