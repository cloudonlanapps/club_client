import 'package:flutter/widgets.dart';

import '../../../models/evaluation_answer_value.dart';
import '../../../models/evaluation_item_kind.dart';
import '../../../models/evaluation_item_value.dart';
import '../../../models/evaluation_rating_style.dart';
import '../../../utils/evaluation_answer_rules.dart';
import 'evaluation_level_buttons.dart';
import 'evaluation_multiple_choice_input.dart';
import 'evaluation_number_input.dart';
import 'evaluation_range_input.dart';
import 'evaluation_single_choice_input.dart';
import 'evaluation_star_input.dart';
import 'evaluation_text_answer_input.dart';
import 'evaluation_yes_no_input.dart';

/// The input for [item]'s kind, editing the value of [answer]; the coach
/// note is kept as it is. An info text has no input.
class EvaluationAnswerInput extends StatelessWidget {
  /// Edits [answer] to [item].
  const EvaluationAnswerInput({
    required this.item,
    required this.answer,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The question.
  final EvaluationItemValue item;

  /// The current answer.
  final EvaluationAnswerValue answer;

  /// Called with the whole answer after a change.
  final ValueChanged<EvaluationAnswerValue> onChanged;

  /// Whether the answer can change.
  final bool enabled;

  /// Reports [n] as the numeric value.
  void setNum(num? n) => onChanged(answer.copyWith(valueNum: () => n));

  /// Reports [t] as the text value.
  void setText(String? t) => onChanged(answer.copyWith(valueText: () => t));

  @override
  Widget build(BuildContext context) {
    final scale = EvaluationAnswerRules.scaleOf(item);
    final n = answer.valueNum?.toInt();
    return switch (item.kind) {
      EvaluationItemKind.rating => switch (scale.style) {
        EvaluationRatingStyle.stars => EvaluationStarInput(
          min: scale.min,
          max: scale.max,
          value: n,
          enabled: enabled,
          onChanged: setNum,
        ),
        EvaluationRatingStyle.range => EvaluationRangeInput(
          min: scale.min,
          max: scale.max,
          value: n,
          enabled: enabled,
          onChanged: setNum,
        ),
        EvaluationRatingStyle.levels => EvaluationLevelButtons(
          levels: scale.levels,
          value: n,
          enabled: enabled,
          onChanged: setNum,
        ),
      },
      EvaluationItemKind.yesNo => EvaluationYesNoInput(
        value: n == null ? null : n == EvaluationAnswerRules.yesValue,
        labelTrue: item.labelTrue,
        labelFalse: item.labelFalse,
        enabled: enabled,
        onChanged: (v) => setNum(
          v == null
              ? null
              : v
              ? EvaluationAnswerRules.yesValue
              : EvaluationAnswerRules.noValue,
        ),
      ),
      EvaluationItemKind.singleChoice => EvaluationSingleChoiceInput(
        choices: item.choices,
        value: answer.valueText,
        enabled: enabled,
        onChanged: setText,
      ),
      EvaluationItemKind.multipleChoice => EvaluationMultipleChoiceInput(
        choices: item.choices,
        value: answer.choices,
        enabled: enabled,
        onChanged: (v) => onChanged(answer.copyWith(choices: v)),
      ),
      EvaluationItemKind.number => EvaluationNumberInput(
        value: answer.valueNum,
        enabled: enabled,
        onChanged: setNum,
      ),
      EvaluationItemKind.qa => EvaluationTextAnswerInput(
        value: answer.valueText,
        enabled: enabled,
        onChanged: setText,
      ),
      EvaluationItemKind.info => const SizedBox.shrink(),
    };
  }
}
