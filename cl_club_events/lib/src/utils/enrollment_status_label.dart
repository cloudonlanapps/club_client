import 'package:club_sdk_2/club_sdk_2.dart';

/// [status] in words, for staff reading a member's enrolment: "Invited",
/// "Withdrawal pending", "Trial — assigned". The pending and trial states
/// read as the member's own lines put them.
String enrollmentStatusLabel(EnrollmentStatus status) => switch (status) {
  EnrollmentStatus.invited => 'Invited',
  EnrollmentStatus.accepted => 'Accepted',
  EnrollmentStatus.assigned => 'Assigned',
  EnrollmentStatus.assignedTrial => 'Trial — assigned',
  EnrollmentStatus.requested => 'Request pending',
  EnrollmentStatus.withdrawRequested => 'Withdrawal pending',
  EnrollmentStatus.withdrawn => 'Withdrawn',
  EnrollmentStatus.declined => 'Declined',
  EnrollmentStatus.rejected => 'Rejected',
  EnrollmentStatus.removed => 'Removed',
};
