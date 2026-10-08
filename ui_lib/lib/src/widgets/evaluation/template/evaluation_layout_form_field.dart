import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/evaluation_layout_callbacks.dart';
import '../../../models/evaluation_layout_entry.dart';
import '../layout/evaluation_layout_editor.dart';

/// A form field holding a template's layout, edited with
/// [EvaluationLayoutEditor]. Turned off — by [enabled] or by its form — the
/// editor stays on screen, greyed.
class EvaluationLayoutFormField
    extends ShadFormBuilderField<List<EvaluationLayoutEntry>> {
  /// Edits the layout under [id].
  EvaluationLayoutFormField({
    required String super.id,
    required EvaluationEditItem onEditItem,
    required EvaluationEditSectionTitle onEditSectionTitle,
    EvaluationPickExisting? onPickExisting,
    super.enabled,
    super.onChanged,
    super.key,
  }) : super(
         // ShadForm deep-copies values into untyped lists.
         fromValueTransformer: (v) => [
           for (final e in v as List? ?? const []) e as EvaluationLayoutEntry,
         ],
         builder: (state) => EvaluationLayoutEditor(
           layout: state.value ?? const [],
           enabled:
               (state
                       as ShadFormBuilderFieldState<
                         ShadFormBuilderField<List<EvaluationLayoutEntry>>,
                         List<EvaluationLayoutEntry>
                       >)
                   .enabled,
           onLayoutChanged: state.didChange,
           onEditItem: onEditItem,
           onEditSectionTitle: onEditSectionTitle,
           onPickExisting: onPickExisting,
         ),
       );
}
