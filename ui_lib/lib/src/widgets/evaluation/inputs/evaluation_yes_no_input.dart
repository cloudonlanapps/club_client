import 'package:flutter/widgets.dart';

import '../../../constants/evaluation_strings.dart';
import 'evaluation_option_buttons.dart';

/// A yes / no answer as two buttons, labelled [labelTrue] and [labelFalse]
/// (Yes and No by default).
class EvaluationYesNoInput extends StatelessWidget {
  /// Edits [value].
  const EvaluationYesNoInput({
    required this.value,
    required this.onChanged,
    this.labelTrue,
    this.labelFalse,
    this.enabled = true,
    super.key,
  });

  /// The answer, or `null`.
  final bool? value;

  /// Called with the new answer, or `null` when cleared.
  final ValueChanged<bool?> onChanged;

  /// Label of yes; Yes when `null` or blank.
  final String? labelTrue;

  /// Label of no; No when `null` or blank.
  final String? labelFalse;

  /// Whether taps change the value.
  final bool enabled;

  @override
  Widget build(BuildContext context) => EvaluationOptionButtons<bool>(
    options: [
      (true, labelOr(labelTrue, EvaluationStrings.yes)),
      (false, labelOr(labelFalse, EvaluationStrings.no)),
    ],
    selected: value,
    enabled: enabled,
    onChanged: onChanged,
  );

  /// [label], or [fallback] when it is `null` or blank.
  static String labelOr(String? label, String fallback) =>
      label == null || label.trim().isEmpty ? fallback : label;
}
