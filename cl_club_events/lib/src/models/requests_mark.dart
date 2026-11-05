import 'package:club_sdk_2/club_sdk_2.dart';

/// What a session's Manage requests action shows (club_client#439).
enum RequestsMark {
  /// Nothing waiting and no approved leave: no icon.
  none,

  /// A leave, enrollment or withdrawal request awaits a decision: ⏳.
  pending,

  /// Nothing waiting, but some members are on approved leave: ◐.
  approvedLeave;

  /// The mark of [occurrence], from the counts the staff occurrence list
  /// carries (club_server#142, #153). A future session's marked members are
  /// its approved leave, since nobody is marked before it starts. Once it
  /// has started they are its attendance, so a started session never shows
  /// ◐ (club_client#444).
  static RequestsMark of(Occurrence occurrence, {DateTime? now}) {
    final pending =
        (occurrence.leaveRequestsPending ?? 0) +
        (occurrence.enrollmentRequestsPending ?? 0) +
        (occurrence.withdrawalRequestsPending ?? 0);
    if (pending > 0) return RequestsMark.pending;
    final started = !(now ?? DateTime.now()).toUtc().isBefore(
      occurrence.actualStartTimeUtc,
    );
    if (!started && (occurrence.attendanceMarked ?? 0) > 0) {
      return RequestsMark.approvedLeave;
    }
    return RequestsMark.none;
  }
}
