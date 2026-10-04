import 'dart:convert';

import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:meta/meta.dart';

/// What the "Existing question" picker searches for (club_core#173): text
/// in an item's question and, optionally, one item type. The key of
/// `clEvaluationItemSearchProvider`.
@immutable
class EvaluationItemSearchQuery {
  const EvaluationItemSearchQuery({this.search, this.type});

  factory EvaluationItemSearchQuery.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    return EvaluationItemSearchQuery(
      search: map['search'] as String?,
      type: type == null ? null : EvaluationItemType.fromWire(type),
    );
  }

  factory EvaluationItemSearchQuery.fromJson(String source) =>
      EvaluationItemSearchQuery.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// Text to match in the item; null or empty matches every item.
  final String? search;

  /// The item type to keep; null keeps every type.
  final EvaluationItemType? type;

  /// A copy with the given fields replaced.
  EvaluationItemSearchQuery copyWith({
    String? Function()? search,
    EvaluationItemType? Function()? type,
  }) {
    return EvaluationItemSearchQuery(
      search: search != null ? search() : this.search,
      type: type != null ? type() : this.type,
    );
  }

  /// This query as a map.
  Map<String, dynamic> toMap() => <String, dynamic>{
    'search': search,
    'type': type?.wireName,
  };

  /// This query as JSON.
  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'EvaluationItemSearchQuery(search: $search, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvaluationItemSearchQuery &&
        other.search == search &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(search, type);
}
