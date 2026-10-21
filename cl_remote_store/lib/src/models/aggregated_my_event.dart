import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart';

/// An event combined with the member's enrollment in it.
///
/// Used by the My Events dashboard, one card per event.
@immutable
class AggregatedMyEvent {
  const AggregatedMyEvent({
    required this.event,
    this.enrollment,
  });

  /// The event data.
  final Event event;

  /// The member's enrollment in this event, or null when they have none.
  final Enrollment? enrollment;

  AggregatedMyEvent copyWith({
    Event? event,
    Enrollment? Function()? enrollment,
  }) {
    return AggregatedMyEvent(
      event: event ?? this.event,
      enrollment: enrollment != null ? enrollment() : this.enrollment,
    );
  }

  @override
  String toString() =>
      'AggregatedMyEvent(event: ${event.id}, '
      'enrollment: ${enrollment?.status})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AggregatedMyEvent &&
        other.event == event &&
        other.enrollment == enrollment;
  }

  @override
  int get hashCode => Object.hash(event, enrollment);
}
