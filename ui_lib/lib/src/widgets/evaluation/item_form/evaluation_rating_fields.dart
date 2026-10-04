import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_rating_style.dart';
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
      spacing: EvaluationSpacing.fieldGap,
      children: [
        ShadSelectFormField<EvaluationRatingStyle>(
          id: EvaluationItemFormFields.ratingStyleId,
          label: const Text(EvaluationStrings.scale),
          options: [
            for (final s in EvaluationRatingStyle.values)
              ShadOption(value: s, child: Text(s.label)),
          ],
          selectedOptionBuilder: (_, s) => Text(s.label),
        ),
        if (style == EvaluationRatingStyle.levels)
          EvaluationLabelListFormField(
            id: EvaluationItemFormFields.levelsId,
            label: EvaluationStrings.levels,
            addLabel: EvaluationStrings.level,
            numbered: true,
            validator: EvaluationItemFormValidators.levels,
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: EvaluationSpacing.fieldGap,
            children: [
              Expanded(
                child: ShadInputFormField(
                  id: EvaluationItemFormFields.rateMinId,
                  label: const Text(EvaluationStrings.rateMin),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  validator: EvaluationItemFormValidators.rateMin,
                ),
              ),
              Expanded(
                child: ShadInputFormField(
                  id: EvaluationItemFormFields.rateMaxId,
                  label: const Text(EvaluationStrings.rateMax),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  validator: (v) => EvaluationItemFormValidators.rateMax(
                    v,
                    '${values[EvaluationItemFormFields.rateMinId] ?? ''}',
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
