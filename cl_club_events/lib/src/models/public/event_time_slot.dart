import 'package:meta/meta.dart';

import '../../utils/public_event_format.dart';

/// One row of an event's timetable: a wall-clock range and what happens in it.
@immutable
class EventTimeSlot {
  const EventTimeSlot({required this.start, required this.end, this.label});

  final DateTime start;
  final DateTime end;

  /// The session's name, or `null` when the slot is the whole window.
  final String? label;

  /// e.g. "4:30 PM - 5:00 PM".
  String get range => '${formatTimeOnly(start)} - ${formatTimeOnly(end)}';

  /// e.g. "4:30 PM - 5:00 PM Off-Ice Workout", or just the range when
  /// there is nothing to name.
  String get display => label == null ? range : '$range $label';

  @override
  bool operator ==(Object other) =>
      other is EventTimeSlot &&
      other.start == start &&
      other.end == end &&
      other.label == label;

  @override
  int get hashCode => Object.hash(start, end, label);

  @override
  String toString() =>
      'EventTimeSlot(start: $start, end: $end, '
      'label: $label)';
}
