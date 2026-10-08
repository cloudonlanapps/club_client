import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_item_kind.dart';
import '../../labeled_form_row.dart';
import 'evaluation_item_form_fields.dart';
import 'evaluation_item_form_validators.dart';
import 'evaluation_label_list_form_field.dart';
import 'evaluation_rating_fields.dart';

/// The fields specific to [kind]: a rating's scale, a yes / no question's
/// labels, a choice question's choices. Number, Q & A and info text have
/// none.
class EvaluationItemKindFields extends StatelessWidget {
  /// Fields for [kind], given the form's current [values].
  const EvaluationItemKindFields({
    required this.kind,
    required this.values,
    super.key,
  });

  /// The item's kind.
  final EvaluationItemKind kind;

  /// The form's current values.
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) => switch (kind) {
    EvaluationItemKind.rating => EvaluationRatingFields(values: values),
    EvaluationItemKind.yesNo => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EvaluationSpacing.fieldGap,
      children: [
        Expanded(
          child: LabeledFormRow(
            label: EvaluationStrings.labelTrue,
            field: ShadInputFormField(
              id: EvaluationItemFormFields.labelTrueId,
              placeholder: const Text(EvaluationStrings.yes),
              keyboardType: TextInputType.text,
            ),
          ),
        ),
        Expanded(
          child: LabeledFormRow(
            label: EvaluationStrings.labelFalse,
            field: ShadInputFormField(
              id: EvaluationItemFormFields.labelFalseId,
              placeholder: const Text(EvaluationStrings.no),
              keyboardType: TextInputType.text,
            ),
          ),
        ),
      ],
    ),
    EvaluationItemKind.singleChoice ||
    EvaluationItemKind.multipleChoice => LabeledFormRow(
      label: EvaluationStrings.choices,
      required: true,
      field: EvaluationLabelListFormField(
        id: EvaluationItemFormFields.choicesId,
        addLabel: EvaluationStrings.choice,
        validator: EvaluationItemFormValidators.choices,
      ),
    ),
    EvaluationItemKind.number ||
    EvaluationItemKind.qa ||
    EvaluationItemKind.info => const SizedBox.shrink(),
  };
}
