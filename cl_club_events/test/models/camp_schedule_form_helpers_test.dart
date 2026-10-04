import 'package:cl_club_events/src/models/camp_schedule_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;
import 'package:ui_lib/ui_lib.dart' show CampScheduleData, SessionInput;

Event _event({
  required DateTime startTimeUtc,
  required DateTime endTimeUtc,
  String? rrule,
  List<EventSession>? sessions,
  DateTime? untilTimeUtc,
  int version = 1,
}) {
  return Event(
    id: 1,
    version: version,
    title: 'Summer Camp',
    description: 'A camp',
    type: EventType.camp,
    visibility: Visibility.public,
    venueId: 7,
    startTimeUtc: startTimeUtc,
    endTimeUtc: endTimeUtc,
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
    rrule: rrule,
    sessions: sessions,
    untilTimeUtc: untilTimeUtc,
  );
}

/// Records the single `rescheduleEvent` call `updateSchedule` makes and
/// faithfully models the server guards it relies on, without touching the
/// network. Overriding `rescheduleEvent` is enough — since #706 the whole
/// change (window + session split) is one atomic reschedule, and the override
/// never touches `ref`.
///
/// The reschedule mirrors the server's guards: overrides are checked before the
/// session-window validity, and the supplied split (carried in the same call)
/// is validated against the new window — `INVALID_SESSIONS_TOTAL` when it
/// doesn't sum to it.
class _FakeCampNotifier extends ClEventsMasterNotifier {
  _FakeCampNotifier({
    List<EventSession> initialSessions = const [],
    this.overridesPresent = false,
  }) : _sessions = List.of(initialSessions);

  final List<String> calls = [];
  final List<int?> versions = [];
  late Event returnEvent;
  bool overridesPresent;
  List<EventSession> _sessions;

  @override
  Future<Event> rescheduleEvent(
    int eventId, {
    int? version,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    String? rrule,
    int? venueId,
    List<EventSession>? Function()? sessions,
    bool resetOverrides = false,
  }) async {
    final supplied = sessions == null ? _omitted : sessions();
    final desc = sessions == null
        ? 'omitted'
        : supplied == null
        ? 'null'
        : 'list(${supplied.length})';
    calls.add('reschedule(resetOverrides=$resetOverrides, sessions=$desc)');
    versions.add(version);
    // Guard order: overrides before session validity.
    if (overridesPresent && !resetOverrides) {
      throw const ServerException(
        statusCode: 409,
        code: SdkErrorCode.occurrenceOverridesPresent,
        message: 'overrides',
        details: {
          'occurrenceTimeUtcs': [1, 2],
        },
      );
    }
    if (resetOverrides) overridesPresent = false;
    // The split validated is the one supplied in this call; an omitted getter
    // re-validates the stored timetable (server #248).
    final effective = identical(supplied, _omitted)
        ? _sessions
        : (supplied ?? const <EventSession>[]);
    final window = endTimeUtc!.difference(startTimeUtc!).inMinutes;
    if (effective.isNotEmpty) {
      final sum = effective.fold<int>(0, (a, b) => a + b.periodMinutes);
      if (sum != window) {
        throw const ServerException(
          statusCode: 422,
          code: SdkErrorCode.invalidSessionsTotal,
          message: 'sessions',
        );
      }
    }
    _sessions = effective;
    return returnEvent;
  }

  /// A timetable correction (#85): allowed at any time, validated against
  /// the stored window.
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
    DateTime? Function()? dobOnOrAfterUtc,
    DateTime? Function()? dobOnOrBeforeUtc,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
  }) async {
    final supplied = sessions?.call();
    final desc = supplied == null ? 'null' : 'list(${supplied.length})';
    calls.add('update(sessions=$desc)');
    versions.add(version);
    _sessions = supplied ?? const <EventSession>[];
    return returnEvent;
  }
}

/// Sentinel distinguishing "getter omitted" from "getter returned null".
const List<EventSession> _omitted = [EventSession(name: '', periodMinutes: -1)];

void main() {
  group('Issue 705: buildCampScheduleInitialValues ↔ assembleCampSchedule', () {
    test('round-trips an event back to the same CampScheduleData', () {
      final data = CampScheduleData(
        startDate: DateTime(2026, 8, 1),
        trainingDays: 5,
        sessionStartTime: const ShadTimeOfDay(hour: 6, minute: 30, second: 0),
        durationMinutes: 120,
        excludedDates: {DateTime(2026, 8, 3)},
        sessions: const [
          SessionInput(name: 'On-Ice', startTime: '06:30', endTime: '07:30'),
          SessionInput(name: 'Off-Ice', startTime: '07:30', endTime: '08:30'),
        ],
      );

      final fields = assembleCampSchedule(data);
      final event = _event(
        startTimeUtc: fields.startUtc,
        endTimeUtc: fields.endUtc,
        rrule: fields.rrule,
        sessions: fields.sessions,
      );

      // Equality across every field (incl. excludedDates and sessions) means
      // an unedited open is not dirty.
      expect(buildCampScheduleInitialValues(event), data);
    });

    test('maps COUNT → trainingDays and a single session to no split', () {
      final data = CampScheduleData(
        startDate: DateTime(2026, 9, 10),
        trainingDays: 3,
        sessionStartTime: const ShadTimeOfDay(hour: 7, minute: 0, second: 0),
        durationMinutes: 90,
      );
      final fields = assembleCampSchedule(data);
      final back = buildCampScheduleInitialValues(
        _event(
          startTimeUtc: fields.startUtc,
          endTimeUtc: fields.endUtc,
          rrule: fields.rrule,
        ),
      );
      expect(back.trainingDays, 3);
      expect(back.excludedDates, isEmpty);
      expect(back.sessions, isEmpty);
      expect(back.durationMinutes, 90);
    });
  });

  group('Issue 705: canRescheduleCamp', () {
    final now = DateTime.utc(2026, 8, 1, 12);

    test('true for a future camp', () {
      final event = _event(
        startTimeUtc: DateTime.utc(2026, 8, 2, 6),
        endTimeUtc: DateTime.utc(2026, 8, 2, 8),
        rrule: 'FREQ=DAILY;COUNT=3',
      );
      expect(canRescheduleCamp(event, now: now), isTrue);
    });

    test('false once the camp has started', () {
      final event = _event(
        startTimeUtc: DateTime.utc(2026, 7, 30, 6),
        endTimeUtc: DateTime.utc(2026, 7, 30, 8),
        rrule: 'FREQ=DAILY;COUNT=3',
      );
      expect(canRescheduleCamp(event, now: now), isFalse);
    });

    test('false for a cancelled series', () {
      final event = _event(
        startTimeUtc: DateTime.utc(2026, 8, 2, 6),
        endTimeUtc: DateTime.utc(2026, 8, 2, 8),
        rrule: 'FREQ=DAILY;COUNT=3',
        untilTimeUtc: DateTime.utc(2026, 8, 1),
      );
      expect(canRescheduleCamp(event, now: now), isFalse);
    });
  });

  group('Issue 85: isCampTimetableOnly', () {
    final now = DateTime.utc(2026, 8, 1, 12);

    test('Issue 85: false before the camp starts', () {
      final event = _event(
        startTimeUtc: DateTime.utc(2026, 8, 2, 6),
        endTimeUtc: DateTime.utc(2026, 8, 2, 8),
        rrule: 'FREQ=DAILY;COUNT=3',
      );
      expect(isCampTimetableOnly(event, now: now), isFalse);
    });

    test('Issue 85: true once the camp has started', () {
      final event = _event(
        startTimeUtc: DateTime.utc(2026, 7, 30, 6),
        endTimeUtc: DateTime.utc(2026, 7, 30, 8),
        rrule: 'FREQ=DAILY;COUNT=3',
      );
      expect(isCampTimetableOnly(event, now: now), isTrue);
      expect(campRescheduleLockReason(event, now: now), campStartedMessage);
    });

    test('Issue 85: false for a cancelled series', () {
      final event = _event(
        startTimeUtc: DateTime.utc(2026, 7, 30, 6),
        endTimeUtc: DateTime.utc(2026, 7, 30, 8),
        rrule: 'FREQ=DAILY;COUNT=3',
        untilTimeUtc: DateTime.utc(2026, 7, 31, 6),
      );
      expect(isCampTimetableOnly(event, now: now), isFalse);
    });
  });

  group('Issue 706: updateSchedule single atomic reschedule', () {
    CampScheduleData seed() => CampScheduleData(
      startDate: DateTime(2026, 8, 1),
      trainingDays: 5,
      sessionStartTime: const ShadTimeOfDay(hour: 6, minute: 0, second: 0),
      durationMinutes: 120,
    );

    const split = [
      SessionInput(name: 'A', startTime: '06:00', endTime: '07:00'),
      SessionInput(name: 'B', startTime: '07:00', endTime: '08:00'),
    ];

    // A 90-minute split (two 45-min slots) that fits a duration-90 window.
    const shortSplit = [
      SessionInput(name: 'A', startTime: '06:00', endTime: '06:45'),
      SessionInput(name: 'B', startTime: '06:45', endTime: '07:30'),
    ];

    Event eventFor(CampScheduleData data) {
      final f = assembleCampSchedule(data);
      return _event(
        startTimeUtc: f.startUtc,
        endTimeUtc: f.endUtc,
        rrule: f.rrule,
        sessions: f.sessions.isEmpty ? null : f.sessions,
      );
    }

    List<EventSession> sessionsOf(CampScheduleData data) =>
        assembleCampSchedule(data).sessions;

    test('window-only change → one reschedule carrying sessions', () async {
      final event = eventFor(seed());
      final edited = seed().copyWith(trainingDays: 7);
      final notifier = _FakeCampNotifier()..returnEvent = event;

      await CampScheduleFormSubmit.updateSchedule(
        event: event,
        data: edited,
        notifier: notifier,
      );

      // No split on this camp, so the atomic call carries an explicit null
      // (keeps the timetable empty).
      expect(notifier.calls, [
        'reschedule(resetOverrides=false, sessions=null)',
      ]);
    });

    test('duration change clearing a split → one reschedule', () async {
      final withSplit = seed().copyWith(sessions: split);
      final event = eventFor(withSplit);
      // Duration change resets the split (form clears it). One atomic call now
      // shrinks the window and clears the timetable together.
      final edited = withSplit.copyWith(
        durationMinutes: 90,
        sessions: const [],
      );
      final notifier = _FakeCampNotifier(initialSessions: sessionsOf(withSplit))
        ..returnEvent = event;

      await CampScheduleFormSubmit.updateSchedule(
        event: event,
        data: edited,
        notifier: notifier,
      );

      expect(notifier.calls, [
        'reschedule(resetOverrides=false, sessions=null)',
      ]);
    });

    test('duration change with a new valid split → one reschedule', () async {
      final withSplit = seed().copyWith(sessions: split);
      final event = eventFor(withSplit);
      // Window shrinks to 90 and the admin supplies a split that fits it — all
      // in a single atomic call (would have been impossible pre-#706).
      final edited = withSplit.copyWith(
        durationMinutes: 90,
        sessions: shortSplit,
      );
      final notifier = _FakeCampNotifier(initialSessions: sessionsOf(withSplit))
        ..returnEvent = event;

      await CampScheduleFormSubmit.updateSchedule(
        event: event,
        data: edited,
        notifier: notifier,
      );

      expect(notifier.calls, [
        'reschedule(resetOverrides=false, sessions=list(2))',
      ]);
    });

    test(
      'Issue 85: split edit only (window unchanged) → one timetable '
      'correction, no reschedule',
      () async {
        final event = eventFor(seed());
        final edited = seed().copyWith(sessions: split);
        final notifier = _FakeCampNotifier()..returnEvent = event;

        await CampScheduleFormSubmit.updateSchedule(
          event: event,
          data: edited,
          notifier: notifier,
        );

        // A correction moves nothing, so it goes through updateEvent, which
        // the server allows even after the camp has started.
        expect(notifier.calls, ['update(sessions=list(2))']);
      },
    );

    test(
      'Issue 85: clearing the split only → a correction clearing the timetable',
      () async {
        final withSplit = seed().copyWith(sessions: split);
        final event = eventFor(withSplit);
        final notifier = _FakeCampNotifier(
          initialSessions: sessionsOf(withSplit),
        )..returnEvent = event;

        await CampScheduleFormSubmit.updateSchedule(
          event: event,
          data: withSplit.copyWith(sessions: const []),
          notifier: notifier,
        );

        expect(notifier.calls, ['update(sessions=null)']);
      },
    );

    test('Issue 85: a timetable correction sends the event version', () async {
      final event = _event(
        startTimeUtc: assembleCampSchedule(seed()).startUtc,
        endTimeUtc: assembleCampSchedule(seed()).endUtc,
        rrule: assembleCampSchedule(seed()).rrule,
        version: 9,
      );
      final notifier = _FakeCampNotifier()..returnEvent = event;

      await CampScheduleFormSubmit.updateSchedule(
        event: event,
        data: seed().copyWith(sessions: split),
        notifier: notifier,
      );

      expect(notifier.versions, [9]);
    });

    test('start-date move keeping the split → one reschedule', () async {
      final withSplit = seed().copyWith(sessions: split);
      final event = eventFor(withSplit);
      // Window moves but the daily duration is unchanged, so the split stays
      // valid and is re-sent verbatim.
      final edited = withSplit.copyWith(startDate: () => DateTime(2026, 8, 5));
      final notifier = _FakeCampNotifier(initialSessions: sessionsOf(withSplit))
        ..returnEvent = event;

      await CampScheduleFormSubmit.updateSchedule(
        event: event,
        data: edited,
        notifier: notifier,
      );

      expect(notifier.calls, [
        'reschedule(resetOverrides=false, sessions=list(2))',
      ]);
    });

    test('no-op (nothing changed) → no call', () async {
      final event = eventFor(seed());
      final notifier = _FakeCampNotifier()..returnEvent = event;

      final result = await CampScheduleFormSubmit.updateSchedule(
        event: event,
        data: seed(),
        notifier: notifier,
      );

      expect(notifier.calls, isEmpty);
      expect(result, event);
    });

    test('overrides present → atomic reject, nothing applied', () async {
      final withSplit = seed().copyWith(sessions: split);
      final event = eventFor(withSplit);
      final edited = withSplit.copyWith(
        durationMinutes: 90,
        sessions: const [],
      );
      final notifier = _FakeCampNotifier(
        initialSessions: sessionsOf(withSplit),
        overridesPresent: true,
      )..returnEvent = event;

      await expectLater(
        CampScheduleFormSubmit.updateSchedule(
          event: event,
          data: edited,
          notifier: notifier,
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            SdkErrorCode.occurrenceOverridesPresent,
          ),
        ),
      );

      // Exactly one call, rejected atomically — no half-applied state.
      expect(notifier.calls, [
        'reschedule(resetOverrides=false, sessions=null)',
      ]);
    });

    test('resetOverrides=true → one reschedule completes', () async {
      final withSplit = seed().copyWith(sessions: split);
      final event = eventFor(withSplit);
      final edited = withSplit.copyWith(
        durationMinutes: 90,
        sessions: const [],
      );
      final notifier = _FakeCampNotifier(
        initialSessions: sessionsOf(withSplit),
        overridesPresent: true,
      )..returnEvent = event;

      await CampScheduleFormSubmit.updateSchedule(
        event: event,
        data: edited,
        notifier: notifier,
        resetOverrides: true,
      );

      // Override-reset reschedule passes the overrides guard and clears the
      // split in the same call.
      expect(notifier.calls, [
        'reschedule(resetOverrides=true, sessions=null)',
      ]);
    });

    test('stale split not summing to window → surfaces the error', () async {
      final withSplit = seed().copyWith(sessions: split);
      final event = eventFor(withSplit);
      // Window shrinks to 90 but the (still 120-min) split is kept — the server
      // rejects, and the helper surfaces it (no clear-then-retry dance).
      final edited = withSplit.copyWith(durationMinutes: 90);
      final notifier = _FakeCampNotifier(initialSessions: sessionsOf(withSplit))
        ..returnEvent = event;

      await expectLater(
        CampScheduleFormSubmit.updateSchedule(
          event: event,
          data: edited,
          notifier: notifier,
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            SdkErrorCode.invalidSessionsTotal,
          ),
        ),
      );

      expect(notifier.calls, [
        'reschedule(resetOverrides=false, sessions=list(2))',
      ]);
    });
  });

  test(
    'Issue 68: updateSchedule sends the event version it was given',
    () async {
      final data = CampScheduleData(
        startDate: DateTime(2026, 8, 1),
        trainingDays: 5,
        sessionStartTime: const ShadTimeOfDay(hour: 6, minute: 0, second: 0),
        durationMinutes: 120,
      );
      final f = assembleCampSchedule(data);
      final event = _event(
        startTimeUtc: f.startUtc,
        endTimeUtc: f.endUtc,
        rrule: f.rrule,
        version: 6,
      );
      final notifier = _FakeCampNotifier()..returnEvent = event;

      await CampScheduleFormSubmit.updateSchedule(
        event: event,
        data: data.copyWith(trainingDays: 7),
        notifier: notifier,
      );

      expect(notifier.versions, [6]);
    },
  );
}
