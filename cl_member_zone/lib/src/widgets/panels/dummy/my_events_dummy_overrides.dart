import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Design-time fixtures for the My Events panel.
///
/// Returned by [myEventsDummyOverrides] for use in `ProviderScope(overrides:)`.
/// Not exported from the package barrel; intended only for the dev preview
/// behind `--dart-define=DASHBOARD_DUMMY=1`.
List<Override> myEventsDummyOverrides({String username = 'demo_user'}) {
  final today = DateTime.now();
  final dayLocal = DateTime(today.year, today.month, today.day);

  DateTime at(int hour, int minute) => DateTime(
    dayLocal.year,
    dayLocal.month,
    dayLocal.day,
    hour,
    minute,
  ).toUtc();

  // Four events corresponding to the four occurrence rows.
  final events = <Event>[
    dummyEvent(id: 101, title: 'U10 Skating Practice'),
    dummyEvent(id: 102, title: 'Goalie Clinic'),
    dummyEvent(id: 103, title: 'Off-ice Conditioning'),
    dummyEvent(
      id: 104,
      title: 'Stick & Puck',
      type: EventType.oneOff,
    ),
  ];

  final occurrences = <Occurrence>[
    // 1. No leave, scheduled — Apply Leave button visible.
    Occurrence(
      eventId: 101,
      originalStartTimeUtc: at(16, 0),
      actualStartTimeUtc: at(16, 0),
      actualEndTimeUtc: at(17, 0),
      status: OccurrenceStatus.scheduled,
      venueId: 1,
      enrollmentStatus: EnrollmentStatus.assigned,
    ),
    // 2. Leave requested — "Awaiting approval" + Cancel Request.
    Occurrence(
      eventId: 102,
      originalStartTimeUtc: at(17, 30),
      actualStartTimeUtc: at(17, 30),
      actualEndTimeUtc: at(18, 30),
      status: OccurrenceStatus.scheduled,
      venueId: 1,
      enrollmentStatus: EnrollmentStatus.accepted,
      attendanceStatus: AttendanceStatus.onLeaveRequested,
    ),
    // 3. Leave approved (rescheduled) — muted card + Cancel Leave.
    Occurrence(
      eventId: 103,
      originalStartTimeUtc: at(19, 0),
      actualStartTimeUtc: at(19, 30),
      actualEndTimeUtc: at(20, 30),
      status: OccurrenceStatus.rescheduled,
      venueId: 2,
      enrollmentStatus: EnrollmentStatus.assigned,
      attendanceStatus: AttendanceStatus.onLeave,
    ),
    // 4. Cancelled — muted, no action.
    Occurrence(
      eventId: 104,
      originalStartTimeUtc: at(20, 30),
      actualStartTimeUtc: at(20, 30),
      actualEndTimeUtc: at(21, 30),
      status: OccurrenceStatus.cancelled,
      venueId: 1,
      enrollmentStatus: EnrollmentStatus.assigned,
    ),
  ];

  return <Override>[
    clMyEventsMasterProvider.overrideWith(
      () => StaticMyEventsNotifier(events),
    ),
    clMyOccurrencesProvider.overrideWith(
      (ref, key) async =>
          key.username == username ? occurrences : <Occurrence>[],
    ),
  ];
}

Event dummyEvent({
  required int id,
  required String title,
  EventType type = EventType.programme,
}) {
  final now = DateTime.now().toUtc();
  return Event(
    id: id,
    title: title,
    description: '',
    type: type,
    visibility: Visibility.private,
    venueId: 1,
    startTimeUtc: now,
    endTimeUtc: now.add(const Duration(hours: 1)),
    createdAtUtc: now,
    updatedAtUtc: now,
  );
}

class StaticMyEventsNotifier extends ClMyEventsMasterNotifier {
  StaticMyEventsNotifier(this._events);

  final List<Event> _events;

  @override
  Future<List<Event>> build(String arg) async => _events;
}
