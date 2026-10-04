import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEvaluationTemplatesMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:ui_lib/ui_lib.dart'
    show
        EvaluationItemValue,
        EvaluationLayoutEntry,
        EvaluationTemplateCreateValue;

import 'evaluation_item_adapter.dart';
import 'evaluation_layout_adapter.dart';

/// Form → SDK for evaluation templates (form rule 18): the create form
/// whole, and each section edit of an existing template on its own.
abstract final class EvaluationTemplateFormSubmit {
  /// Creates the template [values] describe, its items inline.
  static Future<sdk.EvaluationTemplate> create({
    required EvaluationTemplateCreateValue values,
    required ClEvaluationTemplatesMasterNotifier notifier,
  }) => notifier.createTemplate(
    name: values.name,
    layout: EvaluationLayoutAdapter.toCreateLayout(values.layout),
  );

  /// Renames template [templateId] to [name].
  static Future<sdk.EvaluationTemplate> renameTemplate({
    required int templateId,
    required String name,
    required ClEvaluationTemplatesMasterNotifier notifier,
  }) => notifier.renameTemplate(templateId, name);

  /// Re-lays out template [templateId] as [layout] (every item with its
  /// id).
  static Future<sdk.EvaluationTemplate> updateLayout({
    required int templateId,
    required List<EvaluationLayoutEntry> layout,
    required ClEvaluationTemplatesMasterNotifier notifier,
  }) => notifier.updateLayout(
    templateId,
    EvaluationLayoutAdapter.toIdLayout(layout),
  );

  /// Adds new [item] to template [templateId], at the end of [section]
  /// (created if absent) or of the layout.
  static Future<sdk.EvaluationTemplate> addItem({
    required int templateId,
    required EvaluationItemValue item,
    required ClEvaluationTemplatesMasterNotifier notifier,
    String? section,
  }) => notifier.addItem(
    templateId,
    EvaluationItemAdapter.toSdk(item),
    section: section,
  );

  /// Replaces [item] (which has its id) of template [templateId] in place.
  static Future<sdk.EvaluationTemplate> replaceItem({
    required int templateId,
    required EvaluationItemValue item,
    required ClEvaluationTemplatesMasterNotifier notifier,
  }) => notifier.replaceItem(
    templateId,
    item.id!,
    EvaluationItemAdapter.toSdk(item),
  );

  /// Removes item [itemId] from template [templateId].
  static Future<sdk.EvaluationTemplate> removeItem({
    required int templateId,
    required int itemId,
    required ClEvaluationTemplatesMasterNotifier notifier,
  }) => notifier.removeItem(templateId, itemId);
}
