import 'package:flutter/foundation.dart';

import 'one_off_schedule_data.dart';
import 'session_input.dart';

/// The value `OneOffScheduleForm` edits and returns: when a one-off takes
/// place, where, and how its single occurrence is split into sessions.
@immutable
class OneOffScheduleValue {
  const OneOffScheduleValue({
    required this.schedule,
    this.venueId,
    this.sessions = const <SessionInput>[],
  });

  /// The date, start time and duration.
  final OneOffScheduleData schedule;

  /// The chosen venue's id; `null` until one is picked.
  final int? venueId;

  /// The split of the occurrence; empty when it is one undivided session.
  final List<SessionInput> sessions;

  OneOffScheduleValue copyWith({
    OneOffScheduleData? schedule,
    int? Function()? venueId,
    List<SessionInput>? sessions,
  }) {
    return OneOffScheduleValue(
      schedule: schedule ?? this.schedule,
      venueId: venueId != null ? venueId() : this.venueId,
      sessions: sessions ?? this.sessions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OneOffScheduleValue &&
        other.schedule == schedule &&
        other.venueId == venueId &&
        listEquals(other.sessions, sessions);
  }

  @override
  int get hashCode => Object.hash(schedule, venueId, Object.hashAll(sessions));

  @override
  String toString() =>
      'OneOffScheduleValue(schedule: $schedule, venueId: $venueId, '
      'sessions: $sessions)';
}
