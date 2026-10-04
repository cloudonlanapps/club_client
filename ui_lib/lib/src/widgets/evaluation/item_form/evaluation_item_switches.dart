import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_item_kind.dart';
import '../../../utils/evaluation_answer_rules.dart';
import 'evaluation_comment_rule_form_field.dart';
import 'evaluation_item_form_fields.dart';
import 'evaluation_item_form_validators.dart';
import 'evaluation_item_form_values.dart';

/// The item's switches: Required, the comment area with the answers that
/// require a coach note, evidence, and Private — each where [kind] has it.
class EvaluationItemSwitches extends StatelessWidget {
  /// Switches for [kind], given the form's current [values].
  const EvaluationItemSwitches({
    required this.kind,
    required this.values,
    super.key,
  });

  /// The item's kind.
  final EvaluationItemKind kind;

  /// The form's current values.
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    final commentArea =
        values[EvaluationItemFormFields.showCommentAreaId] == true;
    final options = kind.hasCommentArea && commentArea
        ? EvaluationAnswerRules.answerOptions(
            EvaluationItemFormValues.toItem(values, kind: kind),
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EvaluationSpacing.fieldGap,
      children: [
        if (kind.isQuestion)
          ShadSwitchFormField(
            id: EvaluationItemFormFields.isRequiredId,
            initialValue: values[EvaluationItemFormFields.isRequiredId] == true,
            inputLabel: const Text(EvaluationStrings.required),
          ),
        if (kind.hasCommentArea)
          ShadSwitchFormField(
            id: EvaluationItemFormFields.showCommentAreaId,
            initialValue: commentArea,
            inputLabel: const Text(EvaluationStrings.commentArea),
            inputSublabel: const Text(EvaluationStrings.commentAreaHint),
          ),
        if (options != null && options.isNotEmpty)
          EvaluationCommentRuleFormField(
            id: EvaluationItemFormFields.requireCommentForId,
            label: EvaluationStrings.requireCommentFor,
            options: options,
            validator: (rule) => EvaluationItemFormValidators.requireCommentFor(
              rule,
              showCommentArea: commentArea,
            ),
          ),
        if (kind.allowsEvidence)
          ShadSwitchFormField(
            id: EvaluationItemFormFields.allowEvidenceId,
            initialValue:
                values[EvaluationItemFormFields.allowEvidenceId] == true,
            inputLabel: const Text(EvaluationStrings.allowEvidence),
            inputSublabel: const Text(EvaluationStrings.allowEvidenceHint),
          ),
        ShadSwitchFormField(
          id: EvaluationItemFormFields.isPrivateId,
          initialValue: values[EvaluationItemFormFields.isPrivateId] == true,
          inputLabel: const Text(EvaluationStrings.private),
          inputSublabel: const Text(EvaluationStrings.privateHint),
        ),
      ],
    );
  }
}
