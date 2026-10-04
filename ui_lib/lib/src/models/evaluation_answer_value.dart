import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The answer to one question, with its coach note. Form-local and SDK-free.
///
/// At most one value is set, by the item's kind: [valueNum] for a rating, a
/// yes / no (1 for yes, 0 for no) or a number; [valueText] for a single
/// choice (the choice value) or a Q & A (markdown); [choices] for a multiple
/// choice. An answer may carry only a [coachNote].
@immutable
class EvaluationAnswerValue {
  /// An answer; all empty by default.
  const EvaluationAnswerValue({
    this.valueNum,
    this.valueText,
    this.choices = const [],
    this.coachNote,
  });

  /// Builds an answer from [toMap]'s output.
  factory EvaluationAnswerValue.fromMap(Map<String, dynamic> map) =>
      EvaluationAnswerValue(
        valueNum: map['valueNum'] as num?,
        valueText: map['valueText'] as String?,
        choices: List<String>.from(map['choices'] as List? ?? const []),
        coachNote: map['coachNote'] as String?,
      );

  /// Builds an answer from [toJson]'s output.
  factory EvaluationAnswerValue.fromJson(String source) =>
      EvaluationAnswerValue.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// A rating, yes / no (1 / 0) or number.
  final num? valueNum;

  /// A single-choice value or a Q & A answer.
  final String? valueText;

  /// A multiple-choice answer's choice values, in choice order.
  final List<String> choices;

  /// The coach note on this answer, which the member sees.
  final String? coachNote;

  /// Whether a value is given (a coach note alone is not one).
  bool get hasValue =>
      valueNum != null ||
      (valueText != null && valueText!.trim().isNotEmpty) ||
      choices.isNotEmpty;

  /// Whether a coach note is written.
  bool get hasCoachNote => coachNote != null && coachNote!.trim().isNotEmpty;

  /// Whether nothing is given: no value and no note.
  bool get isEmpty => !hasValue && !hasCoachNote;

  /// A copy with the given fields replaced; nullable fields take a getter so
  /// they can be cleared.
  EvaluationAnswerValue copyWith({
    num? Function()? valueNum,
    String? Function()? valueText,
    List<String>? choices,
    String? Function()? coachNote,
  }) => EvaluationAnswerValue(
    valueNum: valueNum != null ? valueNum() : this.valueNum,
    valueText: valueText != null ? valueText() : this.valueText,
    choices: choices ?? this.choices,
    coachNote: coachNote != null ? coachNote() : this.coachNote,
  );

  /// The answer as a map.
  Map<String, dynamic> toMap() => {
    'valueNum': valueNum,
    'valueText': valueText,
    'choices': choices,
    'coachNote': coachNote,
  };

  /// The answer as JSON.
  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'EvaluationAnswerValue(valueNum: $valueNum, valueText: $valueText, '
      'choices: $choices, coachNote: $coachNote)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationAnswerValue &&
          other.valueNum == valueNum &&
          other.valueText == valueText &&
          listEquals(other.choices, choices) &&
          other.coachNote == coachNote;

  @override
  int get hashCode =>
      Object.hash(valueNum, valueText, Object.hashAll(choices), coachNote);
}
