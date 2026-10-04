import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_answer_value.dart';
import '../../../models/evaluation_item_kind.dart';
import '../../../models/evaluation_item_value.dart';
import '../../../models/evaluation_rating_style.dart';
import '../../../utils/evaluation_answer_rules.dart';
import '../../../utils/evaluation_answer_text.dart';
import '../common/evaluation_markdown_text.dart';
import '../inputs/evaluation_range_input.dart';
import '../inputs/evaluation_star_input.dart';

/// An answer, read-only: stars as filled stars and a short range as its
/// buttons filled up to the value, each with "value / max"; a written
/// answer as markdown, anything else as text; "Not answered" when there is
/// no value.
class EvaluationAnswerRead extends StatelessWidget {
  /// Shows [answer] to [item].
  const EvaluationAnswerRead({
    required this.item,
    required this.answer,
    super.key,
  });

  /// The question.
  final EvaluationItemValue item;

  /// The answer.
  final EvaluationAnswerValue answer;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context).textTheme;
    final text = EvaluationAnswerText.of(item, answer);
    if (text == null) {
      return Text(EvaluationStrings.notAnswered, style: theme.muted);
    }
    final scale = EvaluationAnswerRules.scaleOf(item);
    final n = answer.valueNum?.toInt();
    final Widget? scaleRead = item.kind != EvaluationItemKind.rating
        ? null
        : switch (scale.style) {
            EvaluationRatingStyle.stars => EvaluationStarInput(
              min: scale.min,
              max: scale.max,
              value: n,
              enabled: false,
              onChanged: (_) {},
            ),
            EvaluationRatingStyle.range
                when EvaluationRangeInput.usesButtons(scale.min, scale.max) =>
              EvaluationRangeInput(
                min: scale.min,
                max: scale.max,
                value: n,
                enabled: false,
                onChanged: (_) {},
              ),
            _ => null,
          };
    if (scaleRead != null) {
      return Wrap(
        spacing: EvaluationSpacing.optionGap,
        runSpacing: EvaluationSpacing.optionGap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          scaleRead,
          Text(text, style: theme.muted),
        ],
      );
    }
    return item.kind == EvaluationItemKind.qa
        ? EvaluationMarkdownText(data: text)
        : Text(text, style: theme.p);
  }
}
