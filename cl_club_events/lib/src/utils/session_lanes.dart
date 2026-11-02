import '../models/selected_occurrence.dart';
import '../models/session_lane.dart';

/// Splits a day's sessions into side-by-side lanes for the week view
/// (club_client#420).
///
/// Sessions that overlap, directly or through a chain of others, form a
/// group, and each group gets as many lanes as it needs at once; a session
/// takes the leftmost lane free when it starts and keeps it for its whole
/// length, so it sits in the same lane in every half-hour cell it covers.
/// A session that overlaps nothing has a group to itself: one lane, the
/// full width. Cancelled sessions take a lane like any other.
///
/// [items] are one day's sessions; the result holds each once, in the
/// order they start.
List<SessionLane> sessionLanes(List<SelectedOccurrence> items) {
  final sorted = [...items]
    ..sort((a, b) {
      final byStart = a.$1.actualStartTimeUtc.compareTo(
        b.$1.actualStartTimeUtc,
      );
      if (byStart != 0) return byStart;
      return a.$1.actualEndTimeUtc.compareTo(b.$1.actualEndTimeUtc);
    });

  final result = <SessionLane>[];
  var group = <(SelectedOccurrence, int)>[];
  // When each lane of the current group is free again.
  var laneEnds = <DateTime>[];
  DateTime? groupEnd;

  void closeGroup() {
    final lanes = laneEnds.length;
    for (final (item, lane) in group) {
      result.add((item: item, lane: lane, lanes: lanes));
    }
    group = [];
    laneEnds = [];
    groupEnd = null;
  }

  for (final item in sorted) {
    final start = item.$1.actualStartTimeUtc;
    final end = item.$1.actualEndTimeUtc;
    if (groupEnd != null && !start.isBefore(groupEnd!)) closeGroup();
    var lane = laneEnds.indexWhere((free) => !start.isBefore(free));
    if (lane == -1) {
      lane = laneEnds.length;
      laneEnds.add(end);
    } else {
      laneEnds[lane] = end;
    }
    group.add((item, lane));
    if (groupEnd == null || end.isAfter(groupEnd!)) groupEnd = end;
  }
  closeGroup();
  return result;
}
