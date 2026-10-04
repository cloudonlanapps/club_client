import '../models/evaluation_choice.dart';

/// Derives choice values from their labels, so the designer never types a
/// value: lower case, with every run of characters that are not letters or
/// digits replaced by one separator.
abstract final class EvaluationChoiceValues {
  /// Joins the words of a derived value.
  static const String separator = '_';

  /// Runs of characters that are neither letters nor digits, in any script.
  static final RegExp nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  /// The value [label] stands for; empty when it has no letter or digit.
  static String valueFor(String label) => label
      .trim()
      .toLowerCase()
      .replaceAll(nonWord, separator)
      .replaceAll(RegExp('^$separator+|$separator+\$'), '');

  /// [labels] as choices, each valued from its trimmed label.
  static List<EvaluationChoice> fromLabels(List<String> labels) => [
    for (final l in labels)
      EvaluationChoice(value: valueFor(l), text: l.trim()),
  ];
}
