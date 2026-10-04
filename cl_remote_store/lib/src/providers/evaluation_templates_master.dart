import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/bump_evaluations_version.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Master provider for the evaluation template library (club_core#173).
///
/// Holds every live template, all pages loaded, keyed by id. Any staff
/// member reads it; only an admin writes. Empty, with no server call,
/// unless [evaluationsProvider] is `true`: the evaluation routes answer 503
/// where the module is off. Lazy, so a member never loads it.
///
/// Each write replaces the template locally with the one the server returns
/// and bumps `evaluationsVersion`. A soft-deleted template stays in the map
/// with `deletedAtUtc` set until the next load, so it can be restored;
/// views filter on `deletedAtUtc == null`.
final AsyncNotifierProvider<
  ClEvaluationTemplatesMasterNotifier,
  Map<int, EvaluationTemplate>
>
clEvaluationTemplatesMasterProvider =
    AsyncNotifierProvider<
      ClEvaluationTemplatesMasterNotifier,
      Map<int, EvaluationTemplate>
    >(ClEvaluationTemplatesMasterNotifier.new);

/// Notifier over the evaluation template library and its writes.
class ClEvaluationTemplatesMasterNotifier
    extends AsyncNotifier<Map<int, EvaluationTemplate>> {
  @override
  Future<Map<int, EvaluationTemplate>> build() async {
    ref.watch(clManualRefreshProvider);
    if (ref.watch(evaluationsProvider) != true) return const {};
    final client = await ref.watch(secureClientProvider.future);
    final templates = await fetchAllPages(client.evaluations.listTemplates);
    return {for (final t in templates) t.id: t};
  }

  /// Creates a template whole, its items inline in [layout]; the server
  /// assigns their ids. Admin only.
  Future<EvaluationTemplate> createTemplate({
    required String name,
    required List<EvaluationLayoutEntry<EvaluationTemplateItem>> layout,
  }) => writeTemplate(
    (source) => source.createTemplate(name: name, layout: layout),
  );

  /// Renames template [id]. Admin only; allowed while the template is used.
  Future<EvaluationTemplate> renameTemplate(int id, String name) =>
      writeTemplate((source) => source.updateTemplate(id, name: name));

  /// Re-lays out template [id]: [layout] must place every item exactly once
  /// (422 `INVALID_LAYOUT`). Admin only.
  Future<EvaluationTemplate> updateLayout(
    int id,
    List<EvaluationLayoutEntry<int>> layout,
  ) => writeTemplate((source) => source.updateTemplate(id, layout: layout));

  /// Adds [item] — new, or a copy carrying `originItemId` — at the end of
  /// template [templateId]'s layout, or of its [section] (created if
  /// absent). Admin only.
  Future<EvaluationTemplate> addItem(
    int templateId,
    EvaluationTemplateItem item, {
    String? section,
  }) => writeTemplate(
    (source) => source.addItem(templateId, item, section: section),
  );

  /// Replaces item [itemId] of template [templateId] whole with [item]; it
  /// keeps its id, type and origin. Admin only.
  Future<EvaluationTemplate> replaceItem(
    int templateId,
    int itemId,
    EvaluationTemplateItem item,
  ) => writeTemplate((source) => source.replaceItem(templateId, itemId, item));

  /// Removes item [itemId] and its place in template [templateId]'s layout.
  /// Admin only.
  Future<EvaluationTemplate> removeItem(int templateId, int itemId) =>
      writeTemplate((source) => source.removeItem(templateId, itemId));

  /// Soft-deletes template [id]; the deleted row stays in the map. Refused
  /// while a live evaluation uses it (422 `TEMPLATE_IN_USE`).
  Future<EvaluationTemplate> deleteTemplate(int id) =>
      writeTemplate((source) => source.deleteTemplate(id));

  /// Restores soft-deleted template [id].
  Future<EvaluationTemplate> restoreTemplate(int id) =>
      writeTemplate((source) => source.restoreTemplate(id));

  /// Replaces or adds [template] in the local map.
  void replaceLocally(EvaluationTemplate template) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData({...current, template.id: template});
  }

  /// After a template write that may have landed: reload the library and
  /// every evaluation view.
  void refetchAfterUncertainWrite() {
    ref.invalidateSelf();
    bumpEvaluationsVersion(ref);
  }

  /// Runs one server write and folds its answer into state; a write that
  /// may have landed reloads instead ([refetchIfWriteUncertain]).
  @protected
  Future<EvaluationTemplate> writeTemplate(
    Future<EvaluationTemplate> Function(EvaluationSource source) write,
  ) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final template = await write(client.evaluations);
      replaceLocally(template);
      bumpEvaluationsVersion(ref);
      return template;
    }, refetch: refetchAfterUncertainWrite);
  }
}
