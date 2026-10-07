import 'package:flutter/foundation.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import 'session_input.dart';

/// One schedule whose timetable `EventTimetableForm` can correct: a camp's or
/// one-off's single schedule, or one of a programme's.
///
/// Form-local and SDK-free; the host builds it from its schedule model.
@immutable
class TimetableScheduleOption {
  const TimetableScheduleOption({
    required this.label,
    required this.startTime,
    required this.totalMinutes,
    this.id,
    this.sessions = const <SessionInput>[],
  });

  /// The host's id for the schedule, handed back in `EventTimetableValue`;
  /// `null` when the event has one schedule and needs none.
  final int? id;

  /// How the schedule is named in the picker, e.g. its date range.
  final String label;

  /// Local time of day each occurrence starts, where the first session
  /// begins.
  final ShadTimeOfDay startTime;

  /// The occurrence length the sessions must add up to, in minutes.
  final int totalMinutes;

  /// The schedule's current split; empty when the day is one session.
  final List<SessionInput> sessions;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimetableScheduleOption &&
        other.id == id &&
        other.label == label &&
        other.startTime == startTime &&
        other.totalMinutes == totalMinutes &&
        listEquals(other.sessions, sessions);
  }

  @override
  int get hashCode =>
      Object.hash(id, label, startTime, totalMinutes, Object.hashAll(sessions));

  @override
  String toString() =>
      'TimetableScheduleOption(id: $id, label: $label, startTime: $startTime, '
      'totalMinutes: $totalMinutes, sessions: $sessions)';
}
