import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/evaluation_answer_value.dart';
import '../../../models/evaluation_item_value.dart';
import '../../../utils/evaluation_answer_rules.dart';
import 'evaluation_fill_fields.dart';
import 'evaluation_question_fill.dart';

/// One question as a field of the fill form: it holds the answer and, when
/// the form validates, checks a required answer and a coach note the answer
/// requires, showing the error under the question.
class EvaluationQuestionFormField
    extends ShadFormBuilderField<EvaluationAnswerValue> {
  /// Fills [item] (which must have an id).
  EvaluationQuestionFormField({
    required EvaluationItemValue item,
    required ValueChanged<EvaluationAnswerValue> onAnswerChanged,
    Widget? evidence,
    bool enabled = true,
    super.key,
  }) : super(
         id: EvaluationFillFields.idFor(item.id!),
         validator: (answer) => EvaluationAnswerRules.validate(
           item,
           answer ?? const EvaluationAnswerValue(),
         ),
         builder: (state) => EvaluationQuestionFill(
           item: item,
           answer: state.value ?? const EvaluationAnswerValue(),
           evidence: evidence,
           enabled: enabled,
           onChanged: (answer) {
             state.didChange(answer);
             onAnswerChanged(answer);
           },
         ),
       );
}
