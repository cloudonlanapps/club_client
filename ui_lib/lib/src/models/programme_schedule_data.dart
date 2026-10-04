import 'package:flutter/foundation.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import 'session_input.dart';

/// Typed value produced by `ProgrammeScheduleFields` once it is wrapped
/// as a `ShadFormBuilderField<ProgrammeScheduleData>`.
///
/// Holds everything the host needs to drive a programme create / edit
/// flow:
/// - the recurrence weekdays
/// - the date range (with `hasNoEndDate` describing the "Ongoing" choice)
/// - the session start time and total duration
/// - an optional list of named session segments inside that duration
///
/// This class lives in the form layer; the host translates between it
/// and SDK types (`Event`, `EventInput`, `SessionSegment`) at the
/// boundary.
@immutable
class ProgrammeScheduleData {
  const ProgrammeScheduleData({
    this.weekdays = const <int>{},
    this.startDate,
    this.endDate,
    this.hasNoEndDate = true,
    this.sessionStartTime,
    this.totalDurationMinutes = 60,
    this.sessions = const <SessionInput>[],
  });

  /// Selected weekdays as ISO-style day numbers (1=Monday … 7=Sunday).
  final Set<int> weekdays;

  /// Local-date when the recurrence starts.
  final DateTime? startDate;

  /// Local-date when the recurrence ends. `null` means ongoing.
  final DateTime? endDate;

  /// `true` when the form's End Date input is blank (ongoing series).
  /// Mirrors `endDate == null` in normal usage but is kept explicit so
  /// a host can distinguish "user hasn't picked yet" from "user opted
  /// for ongoing".
  final bool hasNoEndDate;

  /// Local time-of-day when each session starts.
  final ShadTimeOfDay? sessionStartTime;

  /// Sum of the session segments' durations, in minutes.
  final int totalDurationMinutes;

  /// Optional named segments inside the session. Empty when the user
  /// has not split the session into multiple parts.
  final List<SessionInput> sessions;

  ProgrammeScheduleData copyWith({
    Set<int>? weekdays,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    bool? hasNoEndDate,
    ShadTimeOfDay? Function()? sessionStartTime,
    int? totalDurationMinutes,
    List<SessionInput>? sessions,
  }) {
    return ProgrammeScheduleData(
      weekdays: weekdays ?? this.weekdays,
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      hasNoEndDate: hasNoEndDate ?? this.hasNoEndDate,
      sessionStartTime: sessionStartTime != null
          ? sessionStartTime()
          : this.sessionStartTime,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      sessions: sessions ?? this.sessions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProgrammeScheduleData) return false;
    if (other.weekdays.length != weekdays.length ||
        !other.weekdays.containsAll(weekdays)) {
      return false;
    }
    if (other.sessions.length != sessions.length) return false;
    for (var i = 0; i < sessions.length; i++) {
      if (other.sessions[i] != sessions[i]) return false;
    }
    return other.startDate == startDate &&
        other.endDate == endDate &&
        other.hasNoEndDate == hasNoEndDate &&
        other.sessionStartTime == sessionStartTime &&
        other.totalDurationMinutes == totalDurationMinutes;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(weekdays),
    startDate,
    endDate,
    hasNoEndDate,
    sessionStartTime,
    totalDurationMinutes,
    Object.hashAll(sessions),
  );

  @override
  String toString() =>
      'ProgrammeScheduleData(weekdays: $weekdays, startDate: $startDate, '
      'endDate: $endDate, hasNoEndDate: $hasNoEndDate, '
      'sessionStartTime: $sessionStartTime, totalDurationMinutes: '
      '$totalDurationMinutes, sessions: $sessions)';
}
