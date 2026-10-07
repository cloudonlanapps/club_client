import 'package:flutter/foundation.dart';

import 'session_input.dart';

/// The value `EventTimetableForm` returns: the corrected split of one
/// schedule's occurrence.
@immutable
class EventTimetableValue {
  const EventTimetableValue({
    required this.sessions,
    this.scheduleId,
  });

  /// The chosen schedule's `TimetableScheduleOption.id`.
  final int? scheduleId;

  /// The new split; empty when the day is one undivided session, which
  /// clears the timetable.
  final List<SessionInput> sessions;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventTimetableValue &&
        other.scheduleId == scheduleId &&
        listEquals(other.sessions, sessions);
  }

  @override
  int get hashCode => Object.hash(scheduleId, Object.hashAll(sessions));

  @override
  String toString() =>
      'EventTimetableValue(scheduleId: $scheduleId, sessions: $sessions)';
}
