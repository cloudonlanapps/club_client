import 'package:club_sdk_2/club_sdk_2.dart';

/// A single member's enrollment + attendance data for the attendance roster.
///
/// Merges the enrollment roster with attendance records. `currentStatus` is
/// null when no attendance has been recorded yet ("not recorded").
///
/// `eligible` is whether the member's enrollment covers *this* occurrence
/// (see `enrollmentCoversOccurrence`). When false, the member enrolled after
/// (or withdrew before) the session and only a super-admin may mark them.
///
/// `creditBlocked` is whether marking would charge a member who has no
/// usable credit (club_core#99): the credit roster says `blocked` and the
/// session is not charged already. A present, absent or late record is
/// already paid, so changing it costs nothing and is never blocked (R44a).
/// `usableCredits` is what the roster reports they can spend.
///
/// `trialEnded` marks a member whose trial this session's mark ended
/// (club_core#98): they have left the programme and stay on the register,
/// flagged and read-only, until it is reopened.
///
/// `leaveReason` is the reason the member gave with a leave request, when
/// they gave one (club_core#137); staff see it before deciding.
typedef AttendanceRosterEntry = ({
  String username,
  EnrollmentStatus enrollmentStatus,
  AttendanceStatus? currentStatus,
  bool eligible,
  bool creditBlocked,
  int usableCredits,
  bool trialEnded,
  String? leaveReason,
});
