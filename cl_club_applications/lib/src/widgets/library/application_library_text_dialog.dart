import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ApplicationLanguageOption,
        ApplicationLibraryTextForm,
        ApplicationLibraryTextFormState;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationLibraryMasterProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show SavingDialogCloseIcon, SavingDialogScope;

import '../../constants/application_library_strings.dart';
import '../../constants/application_view_sizes.dart';
import '../../constants/application_view_strings.dart';
import '../../models/application_library_text_form_submit.dart';
import '../../utils/application_save_refusal.dart';

/// Opens [ApplicationLibraryTextDialog], to add a text written in
/// [languages] to the club's library.
Future<void> showApplicationLibraryTextDialog(
  BuildContext context, {
  required List<ApplicationLanguageOption> languages,
}) => showShadDialog<void>(
  context: context,
  builder: (_) => ApplicationLibraryTextDialog(languages: languages),
);

/// **Add text** (club_client#389): `ApplicationLibraryTextForm` with
/// Cancel and Save. Save adds the text to the club's library and closes;
/// the dialog stays open while it saves (form rule 24), and a refused
/// value shows on its field.
class ApplicationLibraryTextDialog extends ConsumerStatefulWidget {
  const ApplicationLibraryTextDialog({required this.languages, super.key});

  /// The languages a library text may be written in.
  final List<ApplicationLanguageOption> languages;

  @override
  ConsumerState<ApplicationLibraryTextDialog> createState() =>
      ApplicationLibraryTextDialogState();
}

/// State of [ApplicationLibraryTextDialog]: the form's key and the save in
/// flight.
class ApplicationLibraryTextDialogState
    extends ConsumerState<ApplicationLibraryTextDialog> {
  /// Drives the hosted form.
  final GlobalKey<ApplicationLibraryTextFormState> formKey =
      GlobalKey<ApplicationLibraryTextFormState>();

  /// Whether the create is in flight.
  bool saving = false;

  /// Adds the text and closes.
  Future<void> save() async {
    if (saving) return;
    final values = formKey.currentState?.validate();
    if (values == null) return;
    final navigator = Navigator.of(context);
    setState(() => saving = true);
    try {
      await ApplicationLibraryTextFormSubmit.create(
        values: values,
        notifier: ref.read(clApplicationLibraryMasterProvider.notifier),
      );
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text(ApplicationLibraryStrings.added)),
      );
      navigator.pop();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      final fieldErrors = ApplicationLibraryTextFormSubmit.fieldErrorsFor(e);
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
  Widget build(BuildContext context) => SavingDialogScope(
    saving: saving,
    child: ShadDialog(
      title: const Text(ApplicationLibraryStrings.add),
      closeIcon: SavingDialogCloseIcon(saving: saving),
      constraints: const BoxConstraints(
        maxWidth: ApplicationViewSizes.editMaxWidth,
      ),
      actions: [
        ShadButton.outline(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          child: const Text(ApplicationViewStrings.cancel),
        ),
        ShadButton(
          onPressed: saving ? null : save,
          child: const Text(ApplicationViewStrings.save),
        ),
      ],
      child: ApplicationLibraryTextForm(
        key: formKey,
        languages: widget.languages,
        enabled: !saving,
      ),
    ),
  );
}
