import 'package:flutter/foundation.dart';

/// The value `ProgrammeEndDateForm` returns: the last day a programme runs
/// on, and why.
@immutable
class ProgrammeEndDateValue {
  const ProgrammeEndDateValue({required this.lastDay, this.reason = ''});

  /// The local day the programme last runs on.
  final DateTime lastDay;

  /// Why the end date is set or changed, trimmed; empty when none is given.
  final String reason;

  ProgrammeEndDateValue copyWith({DateTime? lastDay, String? reason}) {
    return ProgrammeEndDateValue(
      lastDay: lastDay ?? this.lastDay,
      reason: reason ?? this.reason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgrammeEndDateValue &&
        other.lastDay == lastDay &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(lastDay, reason);

  @override
  String toString() =>
      'ProgrammeEndDateValue(lastDay: $lastDay, reason: $reason)';
}
