import 'dart:convert';

import 'package:flutter/foundation.dart';

/// One choice of a single- or multiple-choice question: its stored [value]
/// (derived from the label, never typed) and the [text] the reader sees.
@immutable
class EvaluationChoice {
  /// A choice worth [value], labelled [text].
  const EvaluationChoice({required this.value, required this.text});

  /// Builds a choice from [toMap]'s output.
  factory EvaluationChoice.fromMap(Map<String, dynamic> map) =>
      EvaluationChoice(
        value: map['value'] as String? ?? '',
        text: map['text'] as String? ?? '',
      );

  /// Builds a choice from [toJson]'s output.
  factory EvaluationChoice.fromJson(String source) =>
      EvaluationChoice.fromMap(json.decode(source) as Map<String, dynamic>);

  /// The stored value.
  final String value;

  /// The label.
  final String text;

  /// A copy with the given fields replaced.
  EvaluationChoice copyWith({String? value, String? text}) =>
      EvaluationChoice(value: value ?? this.value, text: text ?? this.text);

  /// The choice as a map.
  Map<String, dynamic> toMap() => {'value': value, 'text': text};

  /// The choice as JSON.
  String toJson() => json.encode(toMap());

  @override
  String toString() => 'EvaluationChoice(value: $value, text: $text)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationChoice && other.value == value && other.text == text;

  @override
  int get hashCode => Object.hash(value, text);
}
