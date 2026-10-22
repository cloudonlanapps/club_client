import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationTemplatesMasterProvider, evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        ConfirmDialog,
        EvaluationLayoutEntry,
        EvaluationTemplateCreateForm,
        EvaluationTemplateCreateFormFields,
        EvaluationTemplateCreateFormState;

import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_template_copy.dart';
import '../models/evaluation_template_form_submit.dart';
import '../utils/evaluation_error_message.dart';
import '../widgets/evaluation_item_dialog.dart';
import '../widgets/evaluation_section_title_dialog.dart';
import '../widgets/existing_question_dialog.dart';
import '../widgets/template_create_title_bar.dart';
import '../widgets/template_editor_page.dart';

/// The template designer (design 4.2, `reviews/templates/new`): a title bar
/// with **Cancel** and **Create** (wrapping under the title when narrow),
/// over the one full create form — the name, then the items and sections,
/// an item edited in a dialog, a section titled in a dialog, and
/// **Existing question** copying one from another template.
///
/// Given [copyOfTemplateId] (**Duplicate**), it opens pre-filled with a
/// copy of that template — "Name (copy)", every question brand new and
/// unlinked ([EvaluationTemplateCopy]) — and creates it as a new template.
/// Given [initialValues] instead (**Import**, club_client#27), it opens
/// pre-filled with them, as read from a template file. A name already
/// taken (`TEMPLATE_NAME_TAKEN`) shows under the name.
///
/// Beside the form, or switched with it on a narrow screen, the template's
/// live preview as the review form (club_client#28), following the
/// unsaved layout.
///
/// Leaving a changed form, by Cancel or back, asks first (form rule 20).
/// While the template is created the form is turned off, and neither
/// Cancel nor system back leaves.
/// Open to coaches and admins. Renders nothing unless the server runs
/// evaluations.
class TemplateCreateView extends ConsumerStatefulWidget {
  /// The designer, for [currentUser], a coach or an admin.
  const TemplateCreateView({
    required this.currentUser,
    required this.onCreated,
    required this.onCancel,
    this.copyOfTemplateId,
    this.initialValues,
    super.key,
  }) : assert(
         copyOfTemplateId == null || initialValues == null,
         'A template starts from a copy or from initial values, not both.',
       );

  /// The signed-in coach or admin.
  final UserPrivate currentUser;

  /// The template to start from as a copy; a blank template when `null`.
  final int? copyOfTemplateId;

  /// The designer's initial values, read from an imported template file;
  /// a blank template when `null`.
  final Map<String, dynamic>? initialValues;

  /// Called with the new template's id.
  final ValueChanged<int> onCreated;

  /// Leaves without creating.
  final VoidCallback onCancel;

  @override
  ConsumerState<TemplateCreateView> createState() => TemplateCreateViewState();
}

/// State of [TemplateCreateView]: the form, its layout so far and the
/// create in flight.
class TemplateCreateViewState extends ConsumerState<TemplateCreateView> {
  /// The create form.
  final GlobalKey<EvaluationTemplateCreateFormState> formKey =
      GlobalKey<EvaluationTemplateCreateFormState>();

  /// Whether the template is being created.
  bool creating = false;

  /// The layout as the form last reported it; `null` until it changes,
  /// when the preview shows the initial values' layout.
  List<EvaluationLayoutEntry>? draftLayout;

  /// Leaves, asking first when the form has changed.
  Future<void> cancel() async {
    if (formKey.currentState?.isDirty ?? false) {
      final discard = await ConfirmDialog.show(
        context,
        title: EvaluationViewStrings.discardTitle,
        message: EvaluationViewStrings.discardMessage,
        confirmLabel: EvaluationViewStrings.discard,
        cancelLabel: EvaluationViewStrings.keepEditing,
        destructive: true,
      );
      if (!discard) return;
    }
    widget.onCancel();
  }

  /// Validates the form and creates the template.
  Future<void> create() async {
    final values = formKey.currentState?.validate();
    if (values == null) return;
    setState(() => creating = true);
    final toaster = ShadToaster.of(context);
    try {
      final template = await EvaluationTemplateFormSubmit.create(
        values: values,
        notifier: ref.read(clEvaluationTemplatesMasterProvider.notifier),
      );
      toaster.show(
        const ShadToast(
          description: Text(EvaluationViewStrings.templateCreated),
        ),
      );
      widget.onCreated(template.id);
    } on Object catch (e) {
      if (EvaluationErrorMessage.isTemplateNameTaken(e)) {
        formKey.currentState?.showErrors(
          fieldErrors: {
            EvaluationTemplateCreateFormFields.nameId:
                EvaluationErrorMessage.of(e),
          },
        );
      } else if (EvaluationTemplateFormSubmit.createFieldErrors(e)
          case final fieldErrors when fieldErrors.isNotEmpty) {
        formKey.currentState?.showErrors(fieldErrors: fieldErrors);
      } else {
        toaster.show(
          ShadToast.destructive(
            description: Text(EvaluationErrorMessage.of(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.currentUser.roles.isCoach || widget.currentUser.isAdmin,
      'TemplateCreateView called for ${widget.currentUser.username}, who is '
      'neither a coach nor an admin. Screen gate failed.',
    );
    if (ref.watch(evaluationsProvider) != true) return const SizedBox.shrink();
    final copyOf = widget.copyOfTemplateId;
    final templates = copyOf == null
        ? null
        : ref.watch(clEvaluationTemplatesMasterProvider);
    // Only the first load shows the spinner: a reload keeps the editor and
    // what is being typed (club_client#162).
    if (templates != null && templates.isLoading && !templates.hasValue) {
      return const Center(child: ShadProgress());
    }
    final source = templates?.valueOrNull?[copyOf];
    final initialValues = source == null
        ? widget.initialValues
        : EvaluationTemplateCopy.initialValues(source);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !creating) unawaited(cancel());
      },
      child: TemplateEditorPage(
        layout:
            draftLayout ?? EvaluationTemplateCreateForm.layoutIn(initialValues),
        header: TemplateCreateTitleBar(
          creating: creating,
          onCancel: cancel,
          onCreate: create,
        ),
        editor: [
          EvaluationTemplateCreateForm(
            key: formKey,
            initialValues: initialValues,
            enabled: !creating,
            onLayoutChanged: (layout) => setState(() => draftLayout = layout),
            onEditItem: (item) => showEvaluationItemDialog(context, item),
            onEditSectionTitle: (title) =>
                showEvaluationSectionTitleDialog(context, title),
            onPickExisting: () => showExistingQuestionDialog(context),
          ),
        ],
      ),
    );
  }
}
