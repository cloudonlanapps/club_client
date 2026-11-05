import 'package:cl_club_events/src/models/admin_occurrence_action.dart';
import 'package:cl_club_events/src/models/requests_mark.dart';
import 'package:cl_club_events/src/utils/admin_occurrence_actions_for.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// A session starting [fromNow] from now (negative: already started), with
/// [marked] members marked and [pending] leave requests waiting.
Occurrence _session(Duration fromNow, {int marked = 0, int pending = 0}) {
  final start = DateTime.now().toUtc().add(fromNow);
  return Occurrence(
    eventId: 1,
    originalStartTimeUtc: start,
    actualStartTimeUtc: start,
    actualEndTimeUtc: start.add(const Duration(hours: 1)),
    status: OccurrenceStatus.scheduled,
    venueId: 1,
    attendanceExpected: 10,
    attendanceMarked: marked,
    leaveRequestsPending: pending,
    enrollmentRequestsPending: 0,
    withdrawalRequestsPending: 0,
  );
}

const _past = Duration(hours: -14);
const _future = Duration(days: 2);

void main() {
  group('RequestsMark.of', () {
    test('Issue 444: a started session with attendance taken has no mark', () {
      expect(RequestsMark.of(_session(_past, marked: 10)), RequestsMark.none);
    });

    test('Issue 444: a future session with marked members is on leave', () {
      expect(
        RequestsMark.of(_session(_future, marked: 2)),
        RequestsMark.approvedLeave,
      );
    });

    test('Issue 444: a pending request still marks a started session', () {
      expect(
        RequestsMark.of(_session(_past, marked: 10, pending: 1)),
        RequestsMark.pending,
      );
    });
  });

  group('leadWithRequests', () {
    const withAttendance = [
      AdminOccurrenceAction.attendance,
      AdminOccurrenceAction.reschedule,
      AdminOccurrenceAction.cancelOccurrence,
      AdminOccurrenceAction.manageRequests,
    ];

    test('Issue 444: Attendance stays first when a request is pending', () {
      expect(
        leadWithRequests(withAttendance, _session(_past, pending: 1)),
        withAttendance,
      );
    });

    test('Issue 444: Attendance stays first after attendance is taken', () {
      expect(
        leadWithRequests(withAttendance, _session(_past, marked: 10)),
        withAttendance,
      );
    });

    test('Issue 444: without Attendance, a marked session leads with '
        'Manage requests', () {
      expect(
        leadWithRequests(const [
          AdminOccurrenceAction.reschedule,
          AdminOccurrenceAction.manageRequests,
        ], _session(_future, marked: 1)),
        const [
          AdminOccurrenceAction.manageRequests,
          AdminOccurrenceAction.reschedule,
        ],
      );
    });
  });
}
