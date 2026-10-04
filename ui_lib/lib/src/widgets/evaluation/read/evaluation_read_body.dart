import 'package:flutter/widgets.dart';

import '../../../models/evaluation_answer_value.dart';
import '../../../models/evaluation_layout_entry.dart';
import '../common/evaluation_layout_view.dart';
import '../common/evaluation_markdown_text.dart';
import 'evaluation_question_read.dart';

/// An evaluation read-only (no inputs): the template's [layout] with
/// sections as titled cards, each question's answer, its coach note, and
/// the host's [evidenceBuilder] slot where the item allows evidence. For the
/// member view and the owner's preview — the host leaves private items out
/// of [layout] for the member.
class EvaluationReadBody extends StatelessWidget {
  /// Shows [answers] (by item id) to [layout]'s questions.
  const EvaluationReadBody({
    required this.layout,
    required this.answers,
    this.evidenceBuilder,
    super.key,
  });

  /// The template's items and sections, items with ids.
  final List<EvaluationLayoutEntry> layout;

  /// The answers, by item id.
  final Map<int, EvaluationAnswerValue> answers;

  /// Builds the evidence slot of an item that allows evidence.
  final Widget Function(int itemId)? evidenceBuilder;

  @override
  Widget build(BuildContext context) {
    final evidence = evidenceBuilder;
    return EvaluationLayoutView(
      layout: layout,
      itemBuilder: (item) => item.kind.isQuestion
          ? EvaluationQuestionRead(
              item: item,
              answer: answers[item.id] ?? const EvaluationAnswerValue(),
              evidence: evidence != null && item.allowEvidence
                  ? evidence(item.id!)
                  : null,
            )
          : EvaluationMarkdownText(data: item.text),
    );
  }
}
