import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/evaluation_layout_callbacks.dart';
import '../../../models/evaluation_layout_entry.dart';
import '../layout/evaluation_layout_editor.dart';

/// A form field holding a template's layout, edited with
/// [EvaluationLayoutEditor].
class EvaluationLayoutFormField
    extends ShadFormBuilderField<List<EvaluationLayoutEntry>> {
  /// Edits the layout under [id].
  EvaluationLayoutFormField({
    required String super.id,
    required String label,
    required EvaluationEditItem onEditItem,
    required EvaluationEditSectionTitle onEditSectionTitle,
    EvaluationPickExisting? onPickExisting,
    bool readOnly = false,
    super.onChanged,
    super.key,
  }) : super(
         // ShadForm deep-copies values into untyped lists.
         fromValueTransformer: (v) => [
           for (final e in v as List? ?? const []) e as EvaluationLayoutEntry,
         ],
         label: Text(label),
         builder: (state) => EvaluationLayoutEditor(
           layout: state.value ?? const [],
           readOnly: readOnly,
           onLayoutChanged: state.didChange,
           onEditItem: onEditItem,
           onEditSectionTitle: onEditSectionTitle,
           onPickExisting: onPickExisting,
         ),
       );
}
