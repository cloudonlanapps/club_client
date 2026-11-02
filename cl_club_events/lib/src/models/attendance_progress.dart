import 'package:club_sdk_2/club_sdk_2.dart';

/// How far a session's attendance has been taken, from the counts the staff
/// occurrence list carries (`attendanceExpected`, `attendanceMarked`,
/// club_server#142), and the same for a whole day (club_client#414).
enum AttendanceProgress {
  /// Nothing marked: no icon.
  none,

  /// Some members marked, not all: ◐.
  partial,

  /// Every member marked: ✓.
  complete;

  /// The progress of [occurrence]'s register: [complete] once every member
  /// it expects is marked, [partial] while only some are, [none] when
  /// nothing is marked or nobody is expected.
  static AttendanceProgress of(Occurrence occurrence) {
    final expected = occurrence.attendanceExpected ?? 0;
    final marked = occurrence.attendanceMarked ?? 0;
    if (expected <= 0 || marked <= 0) return none;
    return marked >= expected ? complete : partial;
  }

  /// One mark for a day's [sessions]: [complete] when every session with
  /// members to mark is fully marked, [partial] when something is marked
  /// but not everything, [none] when nothing is. Cancelled sessions and
  /// sessions nobody is expected at do not count.
  static AttendanceProgress ofDay(Iterable<Occurrence> sessions) {
    final counted = [
      for (final s in sessions)
        if (s.status != OccurrenceStatus.cancelled &&
            (s.attendanceExpected ?? 0) > 0)
          of(s),
    ];
    if (counted.isEmpty) return none;
    if (counted.every((p) => p == complete)) return complete;
    if (counted.any((p) => p != none)) return partial;
    return none;
  }
}
