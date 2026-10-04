import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Where a row of the layout outline sits: the top-level [entry], and for an
/// item inside a section, its index [child] there. A section's own header
/// row has no [child].
@immutable
class EvaluationLayoutPosition {
  /// The row at [entry] (and [child] within it).
  const EvaluationLayoutPosition({required this.entry, this.child});

  /// Builds a position from [toMap]'s output.
  factory EvaluationLayoutPosition.fromMap(Map<String, dynamic> map) =>
      EvaluationLayoutPosition(
        entry: map['entry'] as int? ?? 0,
        child: map['child'] as int?,
      );

  /// Builds a position from [toJson]'s output.
  factory EvaluationLayoutPosition.fromJson(String source) =>
      EvaluationLayoutPosition.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// Index of the top-level entry.
  final int entry;

  /// Index within the section, for an item inside one.
  final int? child;

  /// Whether the row is an item inside a section.
  bool get isInSection => child != null;

  /// A copy with the given fields replaced.
  EvaluationLayoutPosition copyWith({int? entry, int? Function()? child}) =>
      EvaluationLayoutPosition(
        entry: entry ?? this.entry,
        child: child != null ? child() : this.child,
      );

  /// The position as a map.
  Map<String, dynamic> toMap() => {'entry': entry, 'child': child};

  /// The position as JSON.
  String toJson() => json.encode(toMap());

  @override
  String toString() => 'EvaluationLayoutPosition(entry: $entry, child: $child)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationLayoutPosition &&
          other.entry == entry &&
          other.child == child;

  @override
  int get hashCode => Object.hash(entry, child);
}
