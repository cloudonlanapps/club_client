import 'package:cl_club_forms/cl_club_forms.dart'
    show ApplicationCreateForm, ApplicationCreateFormState;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        applicationLabelsProvider,
        clApplicationsMasterProvider,
        emptyApplicationClauses,
        emptyApplicationLabels;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show SavingDialogCloseIcon, SavingDialogScope;

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';
import '../models/application_editor_options.dart';
import '../models/application_form_submit.dart';
import '../utils/application_save_refusal.dart';

/// Opens [ApplicationCreateDialog] and resolves to the new draft's id, or
/// null when it was cancelled.
Future<int?> showApplicationCreateDialog(BuildContext context) =>
    showShadDialog<int>(
      context: context,
      builder: (_) => const ApplicationCreateDialog(),
    );

/// **Create application**: `ApplicationCreateForm` — the English title and
/// the print languages — with Cancel and Save. Save creates the draft and
/// closes with its id; the dialog stays open while it saves (form rule 24),
/// and a refused value shows on its field.
class ApplicationCreateDialog extends ConsumerStatefulWidget {
  const ApplicationCreateDialog({super.key});

  @override
  ConsumerState<ApplicationCreateDialog> createState() =>
      ApplicationCreateDialogState();
}

/// State of [ApplicationCreateDialog]: the form's key and the save in
/// flight.
class ApplicationCreateDialogState
    extends ConsumerState<ApplicationCreateDialog> {
  /// Drives the hosted form.
  final GlobalKey<ApplicationCreateFormState> formKey =
      GlobalKey<ApplicationCreateFormState>();

  /// Whether the create is in flight.
  bool saving = false;

  /// Creates the draft and closes with its id.
  Future<void> save() async {
    if (saving) return;
    final values = formKey.currentState?.validate();
    if (values == null) return;
    final navigator = Navigator.of(context);
    setState(() => saving = true);
    try {
      final created = await ApplicationFormSubmit.create(
        values: values,
        notifier: ref.read(clApplicationsMasterProvider.notifier),
      );
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text(ApplicationViewStrings.created)),
      );
      navigator.pop(created.id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      final fieldErrors = ApplicationFormSubmit.fieldErrorsFor(e);
      final language = applicationLanguageRefusal(e);
      if (fieldErrors.isNotEmpty || language != null) {
        formKey.currentState?.showErrors(
          fieldErrors: fieldErrors,
          formError: language,
        );
        return;
      }
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text(ApplicationViewStrings.writeFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // The catalogue's languages; English alone when it cannot be read.
    final labels = ref.watch(applicationLabelsProvider);
    final options = labels.isLoading && !labels.hasValue
        ? null
        : ApplicationEditorOptions.from(
            labels.valueOrNull ?? emptyApplicationLabels,
            emptyApplicationClauses,
          );
    return SavingDialogScope(
      saving: saving,
      child: ShadDialog(
        title: const Text(ApplicationViewStrings.create),
        closeIcon: SavingDialogCloseIcon(saving: saving),
        constraints: const BoxConstraints(
          maxWidth: ApplicationViewSizes.dialogWidth,
        ),
        actions: [
          ShadButton.outline(
            onPressed: saving ? null : () => Navigator.of(context).pop(),
            child: const Text(ApplicationViewStrings.cancel),
          ),
          ShadButton(
            onPressed: saving || options == null ? null : save,
            child: const Text(ApplicationViewStrings.save),
          ),
        ],
        child: options == null
            ? const Center(child: ShadProgress())
            : ApplicationCreateForm(
                key: formKey,
                languageOptions: options.languageOptions,
                enabled: !saving,
                onSubmitted: save,
              ),
      ),
    );
  }
}
