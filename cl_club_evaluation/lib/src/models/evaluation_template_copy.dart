import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:ui_lib/ui_lib.dart'
    show
        EvaluationLayoutEntry,
        EvaluationTemplateCreateForm,
        EvaluationTemplateCreateFormFields;

import '../constants/evaluation_view_strings.dart';
import 'evaluation_layout_adapter.dart';

/// SDK → form for **Duplicate** (client-side, no server round trip): a
/// template as the designer's initial values, its name marked as a copy
/// and every item brand new — no id and no `originItemId` — so the new
/// template may change any content.
abstract final class EvaluationTemplateCopy {
  /// [template] as `EvaluationTemplateCreateForm` initial values.
  static Map<String, dynamic> initialValues(sdk.EvaluationTemplate template) {
    final layout = EvaluationLayoutAdapter.fromTemplate(
      template.layout,
      template.items,
    );
    return {
      ...EvaluationTemplateCreateForm.emptyValues,
      EvaluationTemplateCreateFormFields.nameId: EvaluationViewStrings.copyName(
        template.name,
      ),
      EvaluationTemplateCreateFormFields.layoutId: [
        for (final entry in layout) fresh(entry),
      ],
    };
  }

  /// [entry] with its items' ids and origins removed.
  static EvaluationLayoutEntry fresh(EvaluationLayoutEntry entry) {
    final items = [
      for (final item in entry.items)
        item.copyWith(id: () => null, originItemId: () => null),
    ];
    return entry.isSection
        ? EvaluationLayoutEntry.section(
            title: entry.sectionTitle!,
            items: items,
          )
        : EvaluationLayoutEntry.item(items.single);
  }
}
