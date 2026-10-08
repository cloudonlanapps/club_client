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
        EvaluationTemplateCreateForm,
        EvaluationTemplateCreateFormFields,
        EvaluationTemplateCreateFormState;

import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_template_copy.dart';
import '../models/evaluation_template_form_submit.dart';
import '../utils/evaluation_error_message.dart';
import '../widgets/evaluation_item_dialog.dart';
import '../widgets/evaluation_page.dart';
import '../widgets/evaluation_section_title_dialog.dart';
import '../widgets/evaluation_title_bar.dart';
import '../widgets/existing_question_dialog.dart';

/// The template designer (design 4.2, `reviews/templates/new`): a title bar
/// with **Cancel** and **Create** (wrapping under the title when narrow),
/// over the one full create form — the name, then the items and sections,
/// an item edited in a dialog, a section titled in a dialog, and
/// **Existing question** copying one from another template.
///
/// Given [copyOfTemplateId] (**Duplicate**), it opens pre-filled with a
/// copy of that template — "Name (copy)", every question brand new and
/// unlinked ([EvaluationTemplateCopy]) — and creates it as a new template.
/// A name already taken (`TEMPLATE_NAME_TAKEN`) shows under the name.
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
    super.key,
  });

  /// The signed-in coach or admin.
  final UserPrivate currentUser;

  /// The template to start from as a copy; a blank template when `null`.
  final int? copyOfTemplateId;

  /// Called with the new template's id.
  final ValueChanged<int> onCreated;

  /// Leaves without creating.
  final VoidCallback onCancel;

  @override
  ConsumerState<TemplateCreateView> createState() => TemplateCreateViewState();
}

/// State of [TemplateCreateView]: the form and the create in flight.
class TemplateCreateViewState extends ConsumerState<TemplateCreateView> {
  /// The create form.
  final GlobalKey<EvaluationTemplateCreateFormState> formKey =
      GlobalKey<EvaluationTemplateCreateFormState>();

  /// Whether the template is being created.
  bool creating = false;

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
    if (templates != null && templates.isLoading) {
      return const Center(child: ShadProgress());
    }
    final source = templates?.valueOrNull?[copyOf];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !creating) unawaited(cancel());
      },
      child: EvaluationPage(
        children: [
          EvaluationTitleBar(
            title: EvaluationViewStrings.newTemplate,
            actions: [
              ShadButton.outline(
                onPressed: creating ? null : cancel,
                child: const Text(EvaluationViewStrings.cancel),
              ),
              ShadButton(
                onPressed: creating ? null : create,
                child: Text(
                  creating
                      ? EvaluationViewStrings.creating
                      : EvaluationViewStrings.create,
                ),
              ),
            ],
          ),
          EvaluationTemplateCreateForm(
            key: formKey,
            initialValues: source == null
                ? null
                : EvaluationTemplateCopy.initialValues(source),
            enabled: !creating,
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
