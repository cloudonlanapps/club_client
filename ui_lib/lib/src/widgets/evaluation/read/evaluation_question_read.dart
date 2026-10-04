import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_answer_value.dart';
import '../../../models/evaluation_item_value.dart';
import '../common/evaluation_markdown_text.dart';
import '../common/evaluation_question_header.dart';
import 'evaluation_answer_read.dart';

/// One question with its answer, coach note and evidence, read-only.
class EvaluationQuestionRead extends StatelessWidget {
  /// Shows [answer] to [item].
  const EvaluationQuestionRead({
    required this.item,
    required this.answer,
    this.evidence,
    super.key,
  });

  /// The question.
  final EvaluationItemValue item;

  /// The answer.
  final EvaluationAnswerValue answer;

  /// The evidence slot, where the item allows evidence.
  final Widget? evidence;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context).textTheme;
    final note = answer.hasCoachNote ? answer.coachNote : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EvaluationSpacing.questionGap,
      children: [
        EvaluationQuestionHeader(item: item),
        EvaluationAnswerRead(item: item, answer: answer),
        if (note != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: EvaluationSpacing.smallGap,
            children: [
              Text(EvaluationStrings.coachNote, style: theme.small),
              EvaluationMarkdownText(data: note),
            ],
          ),
        ?evidence,
      ],
    );
  }
}
