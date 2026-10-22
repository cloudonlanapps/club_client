import 'package:flutter/widgets.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../models/evaluation_answer_value.dart';
import '../../../models/evaluation_item_value.dart';
import '../common/evaluation_question_header.dart';
import '../inputs/evaluation_answer_input.dart';
import '../inputs/evaluation_coach_note_input.dart';

/// One question to fill in: its header, its input, the coach note where the
/// item shows a comment area, and the host's [evidence] slot. The input and
/// the coach note count as one field for [onFocusChange]: moving between
/// them keeps the focus in the question.
class EvaluationQuestionFill extends StatelessWidget {
  /// Fills [answer] to [item].
  const EvaluationQuestionFill({
    required this.item,
    required this.answer,
    required this.onChanged,
    this.evidence,
    this.enabled = true,
    this.onFocusChange,
    super.key,
  });

  /// The question.
  final EvaluationItemValue item;

  /// The current answer.
  final EvaluationAnswerValue answer;

  /// Called with the whole answer after a change.
  final ValueChanged<EvaluationAnswerValue> onChanged;

  /// The evidence slot, where the item allows evidence.
  final Widget? evidence;

  /// Whether the answer can change.
  final bool enabled;

  /// Told when the focus enters (`true`) or leaves (`false`) the answer's
  /// input and coach note.
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: EvaluationSpacing.questionGap,
    children: [
      EvaluationQuestionHeader(item: item),
      Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: onFocusChange,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: EvaluationSpacing.questionGap,
          children: [
            EvaluationAnswerInput(
              item: item,
              answer: answer,
              enabled: enabled,
              onChanged: onChanged,
            ),
            if (item.showCommentArea)
              EvaluationCoachNoteInput(
                value: answer.coachNote,
                enabled: enabled,
                onChanged: (note) =>
                    onChanged(answer.copyWith(coachNote: () => note)),
              ),
          ],
        ),
      ),
      ?evidence,
    ],
  );
}
