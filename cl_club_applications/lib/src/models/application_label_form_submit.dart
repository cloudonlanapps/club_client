import 'package:cl_club_forms/cl_club_forms.dart'
    show ApplicationLabelFormFields, ApplicationLanguageOption;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ApplicationLabelsNotifier, schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ApplicationLabel, ApplicationText, SdkErrorCode, ServerException;

/// `ApplicationLabelForm`'s initial values from a club label's [text], by
/// language code.
Map<String, dynamic> buildApplicationLabelFormInitialValues(
  Map<String, String> text,
) => {ApplicationLabelFormFields.textId: text};

/// The adapter between `ApplicationLabelForm` and the club's labels (form
/// rule 18, club_client#396): change one label from the form's values.
abstract final class ApplicationLabelFormSubmit {
  /// Changes label [key] to the text of the form's [values]; a club
  /// language left out is stored blank.
  static Future<ApplicationLabel> update({
    required String key,
    required Map<String, dynamic> values,
    required ApplicationLabelsNotifier notifier,
  }) => notifier.updateLabel(key, textOf(values));

  /// The text of [values].
  static ApplicationText textOf(Map<String, dynamic> values) => ApplicationText(
    values[ApplicationLabelFormFields.textId] as Map<String, String>,
  );

  /// The server's name of the text in each of [languages] → the form's
  /// input of it, for a schema refusal (club_client#114); the text as a
  /// whole (English missing) shows on the English input.
  static Map<String, String> schemaFieldIds(
    List<ApplicationLanguageOption> languages,
  ) => {
    'text': ApplicationLabelFormFields.textFieldId(
      ApplicationLabelFormFields.english,
    ),
    for (final language in languages)
      'text.${language.code}': ApplicationLabelFormFields.textFieldId(
        language.code,
      ),
  };

  /// What a schema refusal puts on the form's inputs; empty when [error]
  /// is about nothing the form holds.
  static Map<String, String> fieldErrorsFor(
    Object error,
    List<ApplicationLanguageOption> languages,
  ) => schemaFieldErrors(error, schemaFieldIds(languages));

  /// Whether [error] refuses the write because the label is gone (404
  /// `APPLICATION_LABEL_NOT_FOUND`).
  static bool isGone(Object error) =>
      error is ServerException &&
      error.code == SdkErrorCode.applicationLabelNotFound;
}
