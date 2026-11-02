import 'package:cl_club_events/src/models/attendance_progress.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

Occurrence _session(
  int expected,
  int marked, {
  OccurrenceStatus status = OccurrenceStatus.scheduled,
}) {
  final start = DateTime.utc(2026, 11, 14, 8);
  return Occurrence(
    eventId: 1,
    originalStartTimeUtc: start,
    actualStartTimeUtc: start,
    actualEndTimeUtc: start.add(const Duration(hours: 1)),
    status: status,
    venueId: 1,
    attendanceExpected: expected,
    attendanceMarked: marked,
  );
}

void main() {
  group('Issue 414: how far a session’s attendance is taken', () {
    test('Issue 414: nothing marked, some marked, every member marked', () {
      expect(AttendanceProgress.of(_session(5, 0)), AttendanceProgress.none);
      expect(AttendanceProgress.of(_session(5, 3)), AttendanceProgress.partial);
      expect(
        AttendanceProgress.of(_session(5, 5)),
        AttendanceProgress.complete,
      );
    });

    test('Issue 414: no counts, or nobody expected, is nothing marked', () {
      final start = DateTime.utc(2026, 11, 14, 8);
      final noCounts = Occurrence(
        eventId: 1,
        originalStartTimeUtc: start,
        actualStartTimeUtc: start,
        actualEndTimeUtc: start.add(const Duration(hours: 1)),
        status: OccurrenceStatus.scheduled,
        venueId: 1,
      );
      expect(AttendanceProgress.of(noCounts), AttendanceProgress.none);
      expect(AttendanceProgress.of(_session(0, 0)), AttendanceProgress.none);
    });
  });

  group('Issue 414: one mark for a day', () {
    test('Issue 414: every session fully marked is ✓', () {
      expect(
        AttendanceProgress.ofDay([_session(5, 5), _session(2, 2)]),
        AttendanceProgress.complete,
      );
    });

    test('Issue 414: one session complete and one untouched is ◐', () {
      expect(
        AttendanceProgress.ofDay([_session(5, 5), _session(2, 0)]),
        AttendanceProgress.partial,
      );
    });

    test('Issue 414: one session partly marked is ◐', () {
      expect(
        AttendanceProgress.ofDay([_session(5, 3), _session(2, 2)]),
        AttendanceProgress.partial,
      );
    });

    test('Issue 414: nothing marked that day is no mark', () {
      expect(
        AttendanceProgress.ofDay([_session(5, 0), _session(2, 0)]),
        AttendanceProgress.none,
      );
      expect(AttendanceProgress.ofDay(const []), AttendanceProgress.none);
    });

    test(
      'Issue 414: cancelled sessions and sessions nobody is expected at do '
      'not count',
      () {
        expect(
          AttendanceProgress.ofDay([
            _session(5, 5),
            _session(3, 0, status: OccurrenceStatus.cancelled),
            _session(0, 0),
          ]),
          AttendanceProgress.complete,
        );
      },
    );
  });
}
