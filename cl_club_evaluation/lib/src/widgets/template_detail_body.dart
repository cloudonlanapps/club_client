import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationTemplatesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationTemplate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        EvaluationLayoutEditor,
        EvaluationLayoutEntry,
        EvaluationTemplateFormValidators;

import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_layout_adapter.dart';
import '../models/evaluation_template_form_submit.dart';
import '../utils/evaluation_error_message.dart';
import '../utils/evaluation_layout_sync.dart';
import '../utils/evaluation_template_actions.dart';
import 'evaluation_item_dialog.dart';
import 'evaluation_page.dart';
import 'evaluation_rename_dialog.dart';
import 'evaluation_section_title_dialog.dart';
import 'evaluation_summary.dart';
import 'existing_question_dialog.dart';

/// The editable sections of a saved [template]: its name with **Rename**,
/// **Duplicate** and **Delete** (always shown, disabled while in use), and
/// its questions in the layout editor; see `TemplateDetailView`. While the
/// layout is fixed (in use, or a write in flight), an item opens read-only
/// and a section not at all.
class TemplateDetailBody extends ConsumerStatefulWidget {
  /// Edits [template].
  const TemplateDetailBody({
    required this.template,
    required this.onDeleted,
    required this.onDuplicate,
    super.key,
  });

  /// The template as the library holds it.
  final EvaluationTemplate template;

  /// Called once the template is deleted.
  final VoidCallback onDeleted;

  /// Opens the designer with a copy of the template.
  final VoidCallback onDuplicate;

  @override
  ConsumerState<TemplateDetailBody> createState() => TemplateDetailBodyState();
}

/// State of [TemplateDetailBody]: whether a write is in flight, and
/// whether the server has refused one because the template is in use.
class TemplateDetailBodyState extends ConsumerState<TemplateDetailBody> {
  /// Whether a layout write is in flight.
  bool writing = false;

  /// Whether the server refused a write because an evaluation uses the
  /// template — the fallback for a template that came into use after it
  /// was read.
  bool refusedInUse = false;

  /// Whether the questions and layout are fixed: the template says it is
  /// in use, or the server has said so.
  bool get frozen => widget.template.inUse || refusedInUse;

  /// Shows [message] as a toast; [failed] makes it destructive.
  void toast(String message, {bool failed = false}) {
    final text = Text(message);
    ShadToaster.of(context).show(
      failed
          ? ShadToast.destructive(description: text)
          : ShadToast(description: text),
    );
  }

  /// Renames the template through the rename dialog; a refusal (a name
  /// already taken) shows inline there.
  Future<void> rename() async {
    final name = await showEvaluationRenameDialog(
      context,
      title: EvaluationViewStrings.renameTemplate,
      label: EvaluationViewStrings.templateName,
      initial: widget.template.name,
      validator: EvaluationTemplateFormValidators.name,
      onSave: writeName,
    );
    if (name != null && mounted) toast(EvaluationViewStrings.templateRenamed);
  }

  /// Writes [name]; `null` once saved, else the refusal, said for people.
  Future<String?> writeName(String name) async {
    try {
      await EvaluationTemplateFormSubmit.renameTemplate(
        templateId: widget.template.id,
        name: name,
        notifier: ref.read(clEvaluationTemplatesMasterProvider.notifier),
      );
      return null;
    } on Object catch (e) {
      return EvaluationErrorMessage.of(e);
    }
  }

  /// Deletes the template, asking first, and leaves once deleted.
  Future<void> delete() async {
    final deleted = await EvaluationTemplateActions.delete(
      context,
      ref,
      widget.template,
    );
    if (deleted && mounted) widget.onDeleted();
  }

  /// Writes one change of the layout editor, from [before] to [after].
  Future<void> changeLayout(
    List<EvaluationLayoutEntry> before,
    List<EvaluationLayoutEntry> after,
  ) async {
    setState(() => writing = true);
    try {
      await EvaluationLayoutSync.apply(
        templateId: widget.template.id,
        before: before,
        after: after,
        notifier: ref.read(clEvaluationTemplatesMasterProvider.notifier),
      );
      if (mounted) toast(EvaluationViewStrings.questionsUpdated);
    } on Object catch (e) {
      if (!mounted) return;
      if (EvaluationErrorMessage.isTemplateInUse(e)) {
        setState(() => refusedInUse = true);
      }
      toast(EvaluationErrorMessage.of(e), failed: true);
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final layout = EvaluationLayoutAdapter.fromTemplate(
      template.layout,
      template.items,
    );
    return EvaluationPage(
      children: [
        EvaluationSummary(
          title: template.name,
          actions: [
            ShadButton.outline(
              onPressed: rename,
              child: const Text(EvaluationViewStrings.rename),
            ),
            ShadButton.outline(
              onPressed: widget.onDuplicate,
              child: const Text(EvaluationViewStrings.duplicate),
            ),
            ShadButton.outline(
              onPressed: template.inUse ? null : delete,
              child: const Text(EvaluationViewStrings.delete),
            ),
          ],
        ),
        ShadCard(
          title: const Text(EvaluationViewStrings.questions),
          description: frozen
              ? const Text(EvaluationViewStrings.templateFrozen)
              : null,
          child: EvaluationLayoutEditor(
            layout: layout,
            readOnly: frozen || writing,
            onLayoutChanged: (next) => changeLayout(layout, next),
            onEditItem: (item) => showEvaluationItemDialog(context, item),
            onEditSectionTitle: (title) =>
                showEvaluationSectionTitleDialog(context, title),
            onPickExisting: () => showExistingQuestionDialog(context),
            onViewItem: (item) =>
                showEvaluationItemDialog(context, item, readOnly: true),
          ),
        ),
      ],
    );
  }
}
