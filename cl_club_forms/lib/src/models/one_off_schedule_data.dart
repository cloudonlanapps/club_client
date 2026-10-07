import 'package:flutter/foundation.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

/// Typed value produced by `OneOffScheduleFormField`.
///
/// One-off events are the simplest of the three: a single date, a start
/// time, and a duration. The host derives the end time as
/// `start + duration` at the SDK boundary.
@immutable
class OneOffScheduleData {
  const OneOffScheduleData({
    this.date,
    this.startTime,
    this.durationMinutes = 120,
  });

  /// Local-date when the event happens.
  final DateTime? date;

  /// Local time-of-day when the event starts.
  final ShadTimeOfDay? startTime;

  /// Total event duration in minutes.
  final int durationMinutes;

  OneOffScheduleData copyWith({
    DateTime? Function()? date,
    ShadTimeOfDay? Function()? startTime,
    int? durationMinutes,
  }) {
    return OneOffScheduleData(
      date: date != null ? date() : this.date,
      startTime: startTime != null ? startTime() : this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OneOffScheduleData &&
        other.date == date &&
        other.startTime == startTime &&
        other.durationMinutes == durationMinutes;
  }

  @override
  int get hashCode => Object.hash(date, startTime, durationMinutes);

  @override
  String toString() =>
      'OneOffScheduleData(date: $date, startTime: $startTime, '
      'durationMinutes: $durationMinutes)';
}
