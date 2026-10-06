import 'package:flutter/foundation.dart';

/// One upcoming session an `EventCancellationForm` can cancel from: its
/// start, which is the value the form returns, and the text shown for it.
@immutable
class EventCancellationSession {
  const EventCancellationSession({required this.start, required this.label});

  /// The session's start; identifies it.
  final DateTime start;

  /// How the session reads in the select, e.g. its local date and time.
  final String label;

  @override
  String toString() => 'EventCancellationSession(start: $start, label: $label)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventCancellationSession &&
          other.start == start &&
          other.label == label;

  @override
  int get hashCode => Object.hash(start, label);
}
