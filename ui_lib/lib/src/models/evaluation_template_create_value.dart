import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'evaluation_layout_entry.dart';

/// What `EvaluationTemplateCreateForm` submits: a new template's [name] and
/// its [layout], items inline (ids `null`; the server assigns them).
@immutable
class EvaluationTemplateCreateValue {
  /// A new template named [name] with [layout].
  const EvaluationTemplateCreateValue({
    required this.name,
    required this.layout,
  });

  /// Builds a value from [toMap]'s output.
  factory EvaluationTemplateCreateValue.fromMap(Map<String, dynamic> map) =>
      EvaluationTemplateCreateValue(
        name: map['name'] as String? ?? '',
        layout: [
          for (final e in map['layout'] as List? ?? const [])
            EvaluationLayoutEntry.fromMap(e as Map<String, dynamic>),
        ],
      );

  /// Builds a value from [toJson]'s output.
  factory EvaluationTemplateCreateValue.fromJson(String source) =>
      EvaluationTemplateCreateValue.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// The template's name, trimmed.
  final String name;

  /// The items and sections, in order.
  final List<EvaluationLayoutEntry> layout;

  /// A copy with the given fields replaced.
  EvaluationTemplateCreateValue copyWith({
    String? name,
    List<EvaluationLayoutEntry>? layout,
  }) => EvaluationTemplateCreateValue(
    name: name ?? this.name,
    layout: layout ?? this.layout,
  );

  /// The value as a map.
  Map<String, dynamic> toMap() => {
    'name': name,
    'layout': [for (final e in layout) e.toMap()],
  };

  /// The value as JSON.
  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'EvaluationTemplateCreateValue(name: $name, layout: $layout)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationTemplateCreateValue &&
          other.name == name &&
          listEquals(other.layout, layout);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(layout));
}
