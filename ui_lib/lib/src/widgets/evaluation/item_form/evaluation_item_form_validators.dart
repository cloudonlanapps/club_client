import '../../../constants/evaluation_strings.dart';
import '../../../utils/evaluation_choice_values.dart';

/// Static, SDK-free validators of `EvaluationItemForm`. Each returns the
/// error message, or `null` when valid.
abstract final class EvaluationItemFormValidators {
  /// A question's text: required.
  static String? question(String value) =>
      value.trim().isEmpty ? EvaluationStrings.questionRequired : null;

  /// An info text's markdown: required.
  static String? infoText(String value) =>
      value.trim().isEmpty ? EvaluationStrings.infoTextRequired : null;

  /// A scale's lowest value: a whole number.
  static String? rateMin(String value) =>
      int.tryParse(value.trim()) == null ? EvaluationStrings.wholeNumber : null;

  /// A scale's highest value: a whole number above [min].
  static String? rateMax(String value, String min) {
    final hi = int.tryParse(value.trim());
    if (hi == null) return EvaluationStrings.wholeNumber;
    final lo = int.tryParse(min.trim());
    return lo != null && lo >= hi ? EvaluationStrings.rangeOrder : null;
  }

  /// Labelled levels: at least one, each labelled, labels distinct.
  static String? levels(List<String>? labels) {
    final list = labels ?? const <String>[];
    if (list.isEmpty) return EvaluationStrings.levelsRequired;
    if (list.any((l) => l.trim().isEmpty)) {
      return EvaluationStrings.levelLabelRequired;
    }
    final seen = <String>{};
    return list.every((l) => seen.add(l.trim().toLowerCase()))
        ? null
        : EvaluationStrings.levelsDistinct;
  }

  /// Choices: at least one, each label giving a value, values distinct.
  static String? choices(List<String>? labels) {
    final list = labels ?? const <String>[];
    if (list.isEmpty) return EvaluationStrings.choicesRequired;
    final values = [for (final l in list) EvaluationChoiceValues.valueFor(l)];
    if (values.any((v) => v.isEmpty)) {
      return EvaluationStrings.choiceLabelRequired;
    }
    return values.toSet().length == values.length
        ? null
        : EvaluationStrings.choicesDistinct;
  }

  /// The answers requiring a coach note: only with the comment area on.
  static String? requireCommentFor(
    List<Object>? rule, {
    required bool showCommentArea,
  }) => (rule ?? const []).isNotEmpty && !showCommentArea
      ? EvaluationStrings.ruleNeedsCommentArea
      : null;
}
