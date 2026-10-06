import 'package:flutter/foundation.dart';

import 'programme_schedule_data.dart';

/// The value `ProgrammeScheduleAdjustForm` edits and returns: the terms a
/// programme follows from a chosen session onward.
@immutable
class ProgrammeScheduleAdjustValue {
  const ProgrammeScheduleAdjustValue({
    required this.schedule,
    this.from,
    this.venueId,
  });

  /// The start of the first session the new terms apply to; `null` until
  /// one is picked.
  final DateTime? from;

  /// The weekdays, start time, duration and sessions. Its dates are not
  /// part of an adjustment: [from] says when the terms begin.
  final ProgrammeScheduleData schedule;

  /// The chosen venue's id; `null` until one is picked.
  final int? venueId;

  ProgrammeScheduleAdjustValue copyWith({
    DateTime? Function()? from,
    ProgrammeScheduleData? schedule,
    int? Function()? venueId,
  }) {
    return ProgrammeScheduleAdjustValue(
      from: from != null ? from() : this.from,
      schedule: schedule ?? this.schedule,
      venueId: venueId != null ? venueId() : this.venueId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgrammeScheduleAdjustValue &&
        other.from == from &&
        other.schedule == schedule &&
        other.venueId == venueId;
  }

  @override
  int get hashCode => Object.hash(from, schedule, venueId);

  @override
  String toString() =>
      'ProgrammeScheduleAdjustValue(from: $from, schedule: $schedule, '
      'venueId: $venueId)';
}
