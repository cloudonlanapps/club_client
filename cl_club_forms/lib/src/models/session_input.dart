import 'package:flutter/foundation.dart';

/// UI-layer description of one named time slot inside a programme or camp
/// schedule form.
///
/// Mirrors the shape of the SDK's `SessionSegment` but is owned by the
/// form widgets so they remain SDK-free. The host (create flow / schedule
/// editor) is responsible for translating between this and the SDK type
/// at the boundary.
@immutable
class SessionInput {
  const SessionInput({
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  /// Display name (e.g. "Off-Ice", "Morning Batch").
  final String name;

  /// Local time-of-day in `HH:MM` 24-hour format.
  final String startTime;

  /// Local time-of-day in `HH:MM` 24-hour format.
  final String endTime;

  SessionInput copyWith({
    String? name,
    String? startTime,
    String? endTime,
  }) {
    return SessionInput(
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionInput &&
        other.name == name &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => Object.hash(name, startTime, endTime);

  @override
  String toString() =>
      'SessionInput(name: $name, startTime: $startTime, endTime: $endTime)';
}
