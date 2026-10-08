import 'package:shadcn_ui/shadcn_ui.dart';

import 'evaluation_label_list_editor.dart';

/// A form field holding a list of labels (levels or choices) under [id].
/// Turned off by its form, its rows and its add button show greyed.
class EvaluationLabelListFormField extends ShadFormBuilderField<List<String>> {
  /// Edits the labels under [id].
  EvaluationLabelListFormField({
    required String super.id,
    required String addLabel,
    bool numbered = false,
    super.validator,
    super.key,
  }) : super(
         // ShadForm deep-copies values into untyped lists.
         fromValueTransformer: (v) => [
           for (final l in v as List? ?? const []) '$l',
         ],
         builder: (state) => EvaluationLabelListEditor(
           labels: state.value ?? const [],
           enabled:
               (state
                       as ShadFormBuilderFieldState<
                         ShadFormBuilderField<List<String>>,
                         List<String>
                       >)
                   .enabled,
           addLabel: addLabel,
           numbered: numbered,
           onChanged: state.didChange,
         ),
       );
}
