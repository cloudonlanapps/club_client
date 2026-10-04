import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart';

/// An event combined with the enrollments of selected family members.
///
/// Used by the My Events dashboard to display one card per event,
/// with subtitle lines showing each enrolled member's status.
@immutable
class AggregatedMyEvent {
  const AggregatedMyEvent({
    required this.event,
    required this.enrollments,
  });

  /// The event data.
  final Event event;

  /// Enrollments for the selected family members in this event.
  final List<Enrollment> enrollments;

  AggregatedMyEvent copyWith({
    Event? event,
    List<Enrollment>? enrollments,
  }) {
    return AggregatedMyEvent(
      event: event ?? this.event,
      enrollments: enrollments ?? this.enrollments,
    );
  }

  @override
  String toString() =>
      'AggregatedMyEvent(event: ${event.id}, '
      'enrollments: ${enrollments.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AggregatedMyEvent &&
        other.event == event &&
        listEquals(other.enrollments, enrollments);
  }

  @override
  int get hashCode => event.hashCode ^ enrollments.hashCode;
}
