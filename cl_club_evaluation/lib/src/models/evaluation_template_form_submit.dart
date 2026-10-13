import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEvaluationTemplatesMasterNotifier, schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:ui_lib/ui_lib.dart'
    show
        EvaluationItemValue,
        EvaluationLayoutEntry,
        EvaluationTemplateCreateFormFields;

import 'evaluation_item_adapter.dart';
import 'evaluation_layout_adapter.dart';

/// Form → SDK for evaluation templates (form rule 18): the create form
/// whole, and each section edit of an existing template on its own.
abstract final class EvaluationTemplateFormSubmit {
  /// The server's name for a template's name.
  static const String serverName = 'name';

  /// The server's name for a template's sections and questions.
  static const String serverLayout = 'layout';

  /// The fields of a new template, as the server names them in a schema
  /// rejection (club_client#114), each with the id of the form field that
  /// holds it.
  static const Map<String, String> schemaFieldIds = {
    serverName: EvaluationTemplateCreateFormFields.nameId,
    serverLayout: EvaluationTemplateCreateFormFields.layoutId,
  };

  /// What the create form shows on its fields for a template the server
  /// refused with [error] at its schema. Empty when [error] names no field.
  static Map<String, String> createFieldErrors(Object error) =>
      schemaFieldErrors(error, schemaFieldIds);

  /// What the rename dialog shows on the name for a rename that failed with
  /// [error]: the server's reason when its schema rejects the name, else
  /// [fallback].
  static String renameRefusal(Object error, {required String fallback}) =>
      schemaFieldErrors(error, const {serverName: serverName})[serverName] ??
      fallback;

  /// Creates the template the create form's [values] describe (keyed by
  /// `EvaluationTemplateCreateFormFields`), its items inline.
  static Future<sdk.EvaluationTemplate> create({
    required Map<String, dynamic> values,
    required ClEvaluationTemplatesMasterNotifier notifier,
  }) => notifier.createTemplate(
    name: values[EvaluationTemplateCreateFormFields.nameId] as String,
    layout: EvaluationLayoutAdapter.toCreateLayout(
      values[EvaluationTemplateCreateFormFields.layoutId]
          as List<EvaluationLayoutEntry>,
    ),
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
