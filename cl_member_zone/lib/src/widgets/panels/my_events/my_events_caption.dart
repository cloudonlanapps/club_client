import 'package:club_sdk_2/club_sdk_2.dart';

/// Caption text for an upcoming occurrence in the My Events panel.
///
/// Leave state takes precedence over enrollment state.
String myEventsFutureCaption(AttendanceStatus? a, EnrollmentStatus? e) {
  switch (a) {
    case AttendanceStatus.onLeaveRequested:
      return 'Leave requested';
    case AttendanceStatus.onLeave:
      return 'Leave approved';
    case AttendanceStatus.present:
    case AttendanceStatus.absent:
    case AttendanceStatus.late:
    case null:
      return enrollmentCaption(e);
  }
}

/// Caption text for a past occurrence in the My Events panel.
String myEventsPastCaption(AttendanceStatus? a) {
  switch (a) {
    case AttendanceStatus.present:
      return 'You attended';
    case AttendanceStatus.absent:
      return 'You were absent';
    case AttendanceStatus.late:
      return 'You were late';
    case AttendanceStatus.onLeave:
      return 'You were on leave';
    case AttendanceStatus.onLeaveRequested:
      return 'Leave was pending';
    case null:
      return 'Attendance not recorded';
  }
}

String enrollmentCaption(EnrollmentStatus? s) {
  switch (s) {
    case EnrollmentStatus.invited:
      return 'You are invited';
    case EnrollmentStatus.accepted:
      return 'You are accepted';
    case EnrollmentStatus.assigned:
      return 'You are assigned';
    case EnrollmentStatus.assignedTrial:
      return 'Trial — assigned';
    case EnrollmentStatus.withdrawRequested:
      return 'Withdrawal pending';
    case EnrollmentStatus.requested:
    case EnrollmentStatus.withdrawn:
    case EnrollmentStatus.rejected:
    case EnrollmentStatus.declined:
    case EnrollmentStatus.removed:
    case null:
      return '';
  }
}
