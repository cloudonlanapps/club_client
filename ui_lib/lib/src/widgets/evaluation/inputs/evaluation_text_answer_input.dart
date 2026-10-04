import 'package:flutter/widgets.dart';

import '../../../constants/evaluation_strings.dart';
import 'evaluation_text_area.dart';

/// A written (markdown) answer to a Q & A.
class EvaluationTextAnswerInput extends StatelessWidget {
  /// Edits [value].
  const EvaluationTextAnswerInput({
    required this.value,
    required this.onChanged,
    this.placeholder = EvaluationStrings.answerPlaceholder,
    this.enabled = true,
    super.key,
  });

  /// The answer, or `null`.
  final String? value;

  /// Called with the new answer; blank is `null`.
  final ValueChanged<String?> onChanged;

  /// Shown while empty.
  final String placeholder;

  /// Whether the answer can change.
  final bool enabled;

  @override
  Widget build(BuildContext context) => EvaluationTextArea(
    value: value,
    placeholder: placeholder,
    enabled: enabled,
    onChanged: onChanged,
  );
}
