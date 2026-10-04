import 'package:club_sdk_2/club_sdk_2.dart';

import '../models/attendance_roster_entry.dart';
import '../widgets/attendance_member_tile.dart' show isMarkableAttendance;

/// Enrollment statuses on the register: enrolled members, including those
/// whose withdrawal is still pending — the server keeps them enrolled, and
/// markable, until it is approved (club_core#113, R74).
const Set<EnrollmentStatus> registerEnrollmentStatuses = {
  EnrollmentStatus.assigned,
  EnrollmentStatus.accepted,
  EnrollmentStatus.assignedTrial,
  EnrollmentStatus.withdrawRequested,
};

/// Builds a session's register: the enrolled members (and any whose trial
/// [trialEnded] this session), their records, whether their enrollment
/// covers [occurrenceTimeUtc], and — with a programme's [creditRoster] —
/// whether a mark would charge a member who cannot pay (club_core#99).
/// Sorted by username.
List<AttendanceRosterEntry> buildAttendanceRoster({
  required Map<String, Enrollment> enrollments,
  required List<AttendanceRecord> records,
  required DateTime occurrenceTimeUtc,
  Map<String, MemberCreditStatus>? creditRoster,
  Set<String> trialEnded = const {},
}) {
  final recordMap = {for (final r in records) r.membername: r};
  final roster = <AttendanceRosterEntry>[];
  for (final entry in enrollments.entries) {
    final enrollment = entry.value;
    final ended = trialEnded.contains(entry.key);
    if (!ended && !registerEnrollmentStatuses.contains(enrollment.status)) {
      continue;
    }
    final status = recordMap[entry.key]?.status;
    final credit = creditRoster?[entry.key];
    roster.add((
      username: entry.key,
      enrollmentStatus: enrollment.status,
      currentStatus: status,
      eligible: enrollmentCoversOccurrence(enrollment, occurrenceTimeUtc),
      creditBlocked:
          !ended && (credit?.blocked ?? false) && !isMarkableAttendance(status),
      usableCredits: credit?.usableCredits ?? 0,
      trialEnded: ended,
      leaveReason: recordMap[entry.key]?.leaveReason,
    ));
  }
  roster.sort((a, b) => a.username.compareTo(b.username));
  return roster;
}
