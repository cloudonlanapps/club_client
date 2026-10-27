import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ApplicationLanguageOption,
        ApplicationLibraryTextForm,
        ApplicationLibraryTextFormState;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationLibraryMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show ApplicationLibraryText;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ConfirmDialog, EditableSectionCard;

import '../../constants/application_library_strings.dart';
import '../../constants/application_view_sizes.dart';
import '../../constants/application_view_strings.dart';
import '../../models/application_library_text_form_submit.dart';
import 'application_library_text_read.dart';

/// One of the club's library texts (club_client#389): an
/// [EditableSectionCard] titled with its name, showing where it is used and
/// its text in each language, edited in place with
/// `ApplicationLibraryTextForm`, and deleted after asking.
class ApplicationLibraryTextCard extends ConsumerStatefulWidget {
  const ApplicationLibraryTextCard({
    required this.text,
    required this.languages,
    super.key,
  });

  /// The text.
  final ApplicationLibraryText text;

  /// The languages a library text may be written in.
  final List<ApplicationLanguageOption> languages;

  @override
  ConsumerState<ApplicationLibraryTextCard> createState() =>
      ApplicationLibraryTextCardState();
}

/// State of [ApplicationLibraryTextCard]: the form's key and the delete in
/// flight.
class ApplicationLibraryTextCardState
    extends ConsumerState<ApplicationLibraryTextCard> {
  /// Drives the hosted form.
  final GlobalKey<ApplicationLibraryTextFormState> formKey =
      GlobalKey<ApplicationLibraryTextFormState>();

  /// Whether the delete is in flight.
  bool deleting = false;

  /// Shows [message] as a toast; [failed] makes it destructive.
  void toast(String message, {bool failed = false}) {
    final text = Text(message);
    ShadToaster.of(context).show(
      failed
          ? ShadToast.destructive(description: text)
          : ShadToast(description: text),
    );
  }

  /// Reports a write [error] that is not about a field: the text gone, or
  /// the server not reached.
  void failed(Object error) {
    if (ApplicationLibraryTextFormSubmit.isGone(error)) {
      ref.invalidate(clApplicationLibraryMasterProvider);
      toast(ApplicationLibraryStrings.gone, failed: true);
    } else {
      toast(ApplicationViewStrings.writeFailed, failed: true);
    }
  }

  /// Saves [values]; true once saved.
  Future<bool> save(Map<String, dynamic> values) async {
    try {
      await ApplicationLibraryTextFormSubmit.update(
        id: widget.text.id,
        values: values,
        notifier: ref.read(clApplicationLibraryMasterProvider.notifier),
      );
      if (mounted) toast(ApplicationLibraryStrings.saved);
      return true;
    } on Object catch (e) {
      if (!mounted) return false;
      final fieldErrors = ApplicationLibraryTextFormSubmit.fieldErrorsFor(e);
      if (fieldErrors.isNotEmpty) {
        formKey.currentState?.showErrors(fieldErrors: fieldErrors);
      } else {
        failed(e);
      }
      return false;
    }
  }

  /// Deletes the text, after asking.
  Future<void> delete() async {
    final ok = await ConfirmDialog.show(
      context,
      title: ApplicationLibraryStrings.deleteTitle,
      message: ApplicationLibraryStrings.deleteMessage,
      confirmLabel: ApplicationLibraryStrings.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => deleting = true);
    try {
      await ref
          .read(clApplicationLibraryMasterProvider.notifier)
          .deleteLibraryText(widget.text.id);
      if (mounted) toast(ApplicationLibraryStrings.deleted);
    } on Object catch (e) {
      if (mounted) failed(e);
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    return EditableSectionCard<Map<String, dynamic>>(
      key: ValueKey('application.library.${text.id}'),
      title: text.name,
      canEdit: true,
      editMaxWidth: ApplicationViewSizes.editMaxWidth,
      read: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ApplicationViewSizes.smallGap,
        children: [
          ApplicationLibraryTextRead(text: text),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            enabled: !deleting,
            leading: const Icon(LucideIcons.trash2),
            onPressed: delete,
            child: const Text(ApplicationLibraryStrings.delete),
          ),
        ],
      ),
      editBuilder: ({required enabled}) => ApplicationLibraryTextForm(
        key: formKey,
        initialValues: buildApplicationLibraryTextFormInitialValues(text),
        languages: widget.languages,
        enabled: enabled,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: save,
    );
  }
}
