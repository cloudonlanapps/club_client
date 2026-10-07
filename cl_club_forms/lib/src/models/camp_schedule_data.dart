import 'package:flutter/foundation.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import 'session_input.dart';

/// Typed value produced by `CampScheduleFormField`.
///
/// Holds everything the host needs to drive a camp create / edit flow:
/// - start date and number of training days (rest days are tracked
///   separately so `trainingDays + excludedDates.length` equals the
///   recurrence COUNT)
/// - the daily session start time and duration
/// - an optional named-session split of that daily duration (same editor as
///   the programme schedule); empty when the day is a single session
///
/// This class lives in the form layer; the host translates between it
/// and SDK types at the boundary.
@immutable
class CampScheduleData {
  const CampScheduleData({
    this.startDate,
    this.trainingDays = 7,
    this.sessionStartTime,
    this.durationMinutes = 120,
    this.excludedDates = const <DateTime>{},
    this.sessions = const <SessionInput>[],
  });

  /// Local-date when the camp begins.
  final DateTime? startDate;

  /// Number of training days (excluding rest days). Always ≥ 1.
  final int trainingDays;

  /// Local time-of-day when each daily session starts.
  final ShadTimeOfDay? sessionStartTime;

  /// Duration of a single day's session, in minutes.
  final int durationMinutes;

  /// Local-dates within the camp window that are rest days.
  final Set<DateTime> excludedDates;

  /// Optional named segments splitting the daily session. Empty when the
  /// day is a single undivided session.
  final List<SessionInput> sessions;

  CampScheduleData copyWith({
    DateTime? Function()? startDate,
    int? trainingDays,
    ShadTimeOfDay? Function()? sessionStartTime,
    int? durationMinutes,
    Set<DateTime>? excludedDates,
    List<SessionInput>? sessions,
  }) {
    return CampScheduleData(
      startDate: startDate != null ? startDate() : this.startDate,
      trainingDays: trainingDays ?? this.trainingDays,
      sessionStartTime: sessionStartTime != null
          ? sessionStartTime()
          : this.sessionStartTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      excludedDates: excludedDates ?? this.excludedDates,
      sessions: sessions ?? this.sessions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CampScheduleData) return false;
    if (other.excludedDates.length != excludedDates.length ||
        !other.excludedDates.containsAll(excludedDates)) {
      return false;
    }
    if (other.sessions.length != sessions.length) return false;
    for (var i = 0; i < sessions.length; i++) {
      if (other.sessions[i] != sessions[i]) return false;
    }
    return other.startDate == startDate &&
        other.trainingDays == trainingDays &&
        other.sessionStartTime == sessionStartTime &&
        other.durationMinutes == durationMinutes;
  }

  @override
  int get hashCode => Object.hash(
    startDate,
    trainingDays,
    sessionStartTime,
    durationMinutes,
    Object.hashAllUnordered(excludedDates),
    Object.hashAll(sessions),
  );

  @override
  String toString() =>
      'CampScheduleData(startDate: $startDate, trainingDays: $trainingDays, '
      'sessionStartTime: $sessionStartTime, durationMinutes: '
      '$durationMinutes, excludedDates: $excludedDates, sessions: $sessions)';
}
