import 'dart:convert';

import 'package:meta/meta.dart';

/// Tracks version counters for resources that use date-range queries.
///
/// Read-only providers watch specific versions via `.select()` and refetch
/// when the version they care about is bumped by a master provider mutation.
@immutable
class ResourceVersionState {
  const ResourceVersionState({
    this.occurrencesVersion = 0,
    this.creditsVersion = 0,
    this.evaluationsVersion = 0,
  });

  factory ResourceVersionState.fromMap(Map<String, dynamic> map) {
    return ResourceVersionState(
      occurrencesVersion: map['occurrencesVersion'] as int? ?? 0,
      creditsVersion: map['creditsVersion'] as int? ?? 0,
      evaluationsVersion: map['evaluationsVersion'] as int? ?? 0,
    );
  }

  factory ResourceVersionState.fromJson(String source) =>
      ResourceVersionState.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// Bumped when occurrence data changes (reschedule, cancel, undo-cancel).
  final int occurrencesVersion;

  /// Bumped when anything that moves credit changes: a credit action, an
  /// attendance mark or clear, a leave decision, an enrollment change
  /// (club_core#102). Every credit provider watches it.
  final int creditsVersion;

  /// Bumped by every evaluation and evaluation-template write
  /// (club_core#173), so the member's published evaluations and their media
  /// refetch.
  final int evaluationsVersion;

  ResourceVersionState copyWith({
    int? occurrencesVersion,
    int? creditsVersion,
    int? evaluationsVersion,
  }) {
    return ResourceVersionState(
      occurrencesVersion: occurrencesVersion ?? this.occurrencesVersion,
      creditsVersion: creditsVersion ?? this.creditsVersion,
      evaluationsVersion: evaluationsVersion ?? this.evaluationsVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'occurrencesVersion': occurrencesVersion,
      'creditsVersion': creditsVersion,
      'evaluationsVersion': evaluationsVersion,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'ResourceVersionState(occurrencesVersion: $occurrencesVersion, '
      'creditsVersion: $creditsVersion, '
      'evaluationsVersion: $evaluationsVersion)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResourceVersionState &&
        other.occurrencesVersion == occurrencesVersion &&
        other.creditsVersion == creditsVersion &&
        other.evaluationsVersion == evaluationsVersion;
  }

  @override
  int get hashCode => Object.hash(
    occurrencesVersion,
    creditsVersion,
    evaluationsVersion,
  );
}
