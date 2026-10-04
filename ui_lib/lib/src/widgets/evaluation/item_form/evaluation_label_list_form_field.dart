import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'evaluation_label_list_editor.dart';

/// A form field holding a list of labels (levels or choices) under [id].
class EvaluationLabelListFormField extends ShadFormBuilderField<List<String>> {
  /// Edits the labels under [id].
  EvaluationLabelListFormField({
    required String super.id,
    required String label,
    required String addLabel,
    bool numbered = false,
    super.validator,
    super.key,
  }) : super(
         // ShadForm deep-copies values into untyped lists.
         fromValueTransformer: (v) => [
           for (final l in v as List? ?? const []) '$l',
         ],
         label: Text(label),
         builder: (state) => EvaluationLabelListEditor(
           labels: state.value ?? const [],
           addLabel: addLabel,
           numbered: numbered,
           onChanged: state.didChange,
         ),
       );
}
