import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../constants/form_spacing.dart';
import '../../../models/evaluation_rating_style.dart';
import '../../labeled_form_row.dart';
import 'evaluation_item_form_fields.dart';
import 'evaluation_item_form_validators.dart';
import 'evaluation_label_list_form_field.dart';

/// A rating's scale fields: the style, then the lowest and highest values
/// for stars and ranges, or the labelled levels.
class EvaluationRatingFields extends StatelessWidget {
  /// Fields given the form's current [values].
  const EvaluationRatingFields({required this.values, super.key});

  /// The form's current values.
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    final style =
        values[EvaluationItemFormFields.ratingStyleId]
            as EvaluationRatingStyle? ??
        EvaluationRatingStyle.stars;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        LabeledFormRow(
          label: EvaluationStrings.scale,
          field: ShadSelectFormField<EvaluationRatingStyle>(
            id: EvaluationItemFormFields.ratingStyleId,
            options: [
              for (final s in EvaluationRatingStyle.values)
                ShadOption(value: s, child: Text(s.label)),
            ],
            selectedOptionBuilder: (_, s) => Text(s.label),
          ),
        ),
        if (style == EvaluationRatingStyle.levels)
          LabeledFormRow(
            label: EvaluationStrings.levels,
            required: true,
            field: EvaluationLabelListFormField(
              id: EvaluationItemFormFields.levelsId,
              addLabel: EvaluationStrings.level,
              numbered: true,
              validator: EvaluationItemFormValidators.levels,
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: EvaluationSpacing.fieldGap,
            children: [
              Expanded(
                child: LabeledFormRow(
                  label: EvaluationStrings.rateMin,
                  required: true,
                  field: ShadInputFormField(
                    id: EvaluationItemFormFields.rateMinId,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    validator: EvaluationItemFormValidators.rateMin,
                  ),
                ),
              ),
              Expanded(
                child: LabeledFormRow(
                  label: EvaluationStrings.rateMax,
                  required: true,
                  field: ShadInputFormField(
                    id: EvaluationItemFormFields.rateMaxId,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    validator: (v) => EvaluationItemFormValidators.rateMax(
                      v,
                      '${values[EvaluationItemFormFields.rateMinId] ?? ''}',
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
