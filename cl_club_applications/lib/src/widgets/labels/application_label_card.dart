import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ApplicationLabelForm,
        ApplicationLabelFormState,
        ApplicationLanguageOption;
import 'package:cl_remote_store/cl_remote_store.dart'
    show applicationLabelsProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

import '../../constants/application_label_strings.dart';
import '../../constants/application_view_sizes.dart';
import '../../constants/application_view_strings.dart';
import '../../models/application_label_form_submit.dart';
import '../../utils/application_save_refusal.dart';
import '../sections/application_section_read.dart';

/// One of the club's application labels (club_client#396): an
/// [EditableSectionCard] titled with its English text, showing its text in
/// each of the club's [languages], a blank one as **Required** in the error
/// colour, and edited in place with `ApplicationLabelForm`.
class ApplicationLabelCard extends ConsumerStatefulWidget {
  const ApplicationLabelCard({
    required this.labelKey,
    required this.text,
    required this.languages,
    super.key,
  });

  /// The key of a label's card, for tests and the integration suite.
  static Key cardKey(String labelKey) =>
      ValueKey('application.labels.$labelKey');

  /// The label's key (`field.full_name`).
  final String labelKey;

  /// The label's text, by language code.
  final Map<String, String> text;

  /// The club's languages, English first.
  final List<ApplicationLanguageOption> languages;

  @override
  ConsumerState<ApplicationLabelCard> createState() =>
      ApplicationLabelCardState();
}

/// State of [ApplicationLabelCard]: the form's key.
class ApplicationLabelCardState extends ConsumerState<ApplicationLabelCard> {
  /// Drives the hosted form.
  final GlobalKey<ApplicationLabelFormState> formKey =
      GlobalKey<ApplicationLabelFormState>();

  /// Shows [message] as a toast; [failed] makes it destructive.
  void toast(String message, {bool failed = false}) {
    final text = Text(message);
    ShadToaster.of(context).show(
      failed
          ? ShadToast.destructive(description: text)
          : ShadToast(description: text),
    );
  }

  /// Saves [values]; true once saved. A text the server refuses shows on
  /// its input, a language the club does not offer inline in the form;
  /// anything else is a toast.
  Future<bool> save(Map<String, dynamic> values) async {
    try {
      await ApplicationLabelFormSubmit.update(
        key: widget.labelKey,
        values: values,
        notifier: ref.read(applicationLabelsProvider.notifier),
      );
      if (mounted) toast(ApplicationLabelStrings.saved);
      return true;
    } on Object catch (e) {
      if (!mounted) return false;
      final fieldErrors = ApplicationLabelFormSubmit.fieldErrorsFor(
        e,
        widget.languages,
      );
      final language = applicationLanguageRefusal(e);
      if (fieldErrors.isNotEmpty || language != null) {
        formKey.currentState?.showErrors(
          fieldErrors: fieldErrors,
          formError: language,
        );
      } else if (ApplicationLabelFormSubmit.isGone(e)) {
        ref.invalidate(applicationLabelsProvider);
        toast(ApplicationLabelStrings.gone, failed: true);
      } else {
        toast(ApplicationViewStrings.writeFailed, failed: true);
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = widget.text[widget.languages.first.code]?.trim() ?? '';
    return EditableSectionCard<Map<String, dynamic>>(
      key: ApplicationLabelCard.cardKey(widget.labelKey),
      title: english.isEmpty ? widget.labelKey : english,
      canEdit: true,
      editMaxWidth: ApplicationViewSizes.editMaxWidth,
      read: ApplicationSectionRead(
        lines: [
          for (final language in widget.languages)
            (
              label: language.name,
              value: widget.text[language.code]?.trim() ?? '',
            ),
        ],
        required: {for (final language in widget.languages) language.name},
      ),
      editBuilder: ({required enabled}) => ApplicationLabelForm(
        key: formKey,
        initialValues: buildApplicationLabelFormInitialValues(widget.text),
        languages: widget.languages,
        enabled: enabled,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: save,
    );
  }
}
