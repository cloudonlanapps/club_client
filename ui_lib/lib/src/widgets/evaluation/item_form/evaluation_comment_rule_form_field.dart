import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';

/// A form field holding the answers that make the coach note required: one
/// checkbox per answer the question can take, as (value, label). Turned off
/// by its form, the checkboxes show greyed.
class EvaluationCommentRuleFormField
    extends ShadFormBuilderField<List<Object>> {
  /// Chooses among [options] under [id].
  EvaluationCommentRuleFormField({
    required String super.id,
    required List<(Object, String)> options,
    super.validator,
    super.key,
  }) : super(
         // ShadForm deep-copies values into untyped lists.
         fromValueTransformer: (v) => [
           for (final o in v as List? ?? const []) o as Object,
         ],
         builder: (state) {
           final chosen = state.value ?? const <Object>[];
           return Wrap(
             spacing: EvaluationSpacing.fieldGap,
             runSpacing: EvaluationSpacing.smallGap,
             children: [
               for (final (value, text) in options)
                 ShadCheckbox(
                   value: chosen.contains(value),
                   enabled:
                       (state
                               as ShadFormBuilderFieldState<
                                 ShadFormBuilderField<List<Object>>,
                                 List<Object>
                               >)
                           .enabled,
                   label: Text(text),
                   onChanged: (on) => state.didChange([
                     for (final (v, _) in options)
                       if (v == value ? on : chosen.contains(v)) v,
                   ]),
                 ),
             ],
           );
         },
       );
}
