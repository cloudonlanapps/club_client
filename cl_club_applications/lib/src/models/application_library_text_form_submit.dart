import 'package:cl_club_forms/cl_club_forms.dart'
    show ApplicationClauseKind, ApplicationLibraryTextFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClApplicationLibraryMasterNotifier, schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show ApplicationClauseKind;
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        ApplicationLibraryText,
        ApplicationLibraryTextInput,
        ApplicationLibraryTextPatch,
        ApplicationText,
        SdkErrorCode,
        ServerException;

import 'application_editor_options.dart';

/// `ApplicationLibraryTextForm`'s initial values from [text]: its kind,
/// name, heading and text as written; nothing for a new one.
Map<String, dynamic> buildApplicationLibraryTextFormInitialValues(
  ApplicationLibraryText? text,
) => text == null
    ? {}
    : {
        ApplicationLibraryTextFormFields.kindId:
            ApplicationEditorOptions.kindOf(
              text.kind,
            ),
        ApplicationLibraryTextFormFields.nameId: text.name,
        ApplicationLibraryTextFormFields.headingId: text.heading?.texts,
        ApplicationLibraryTextFormFields.textId: text.text.texts,
      };

/// The adapter between `ApplicationLibraryTextForm` and the club library's
/// master (form rule 18, club_client#389): create a text, or change one,
/// from the form's values.
abstract final class ApplicationLibraryTextFormSubmit {
  /// The server's name of each field sent → the form's field id that holds
  /// it, for a schema refusal (club_client#114).
  static const Map<String, String> schemaFieldIds = {
    'kind': ApplicationLibraryTextFormFields.kindId,
    'name': ApplicationLibraryTextFormFields.nameId,
    'heading': ApplicationLibraryTextFormFields.headingId,
    'text': ApplicationLibraryTextFormFields.textId,
  };

  /// Adds a text from the form's [values].
  static Future<ApplicationLibraryText> create({
    required Map<String, dynamic> values,
    required ClApplicationLibraryMasterNotifier notifier,
  }) => notifier.createLibraryText(
    ApplicationLibraryTextInput(
      kind: kindOf(values),
      name: nameOf(values),
      heading: headingOf(values),
      text: textOf(values),
    ),
  );

  /// Changes text [id] to the form's [values]; a heading the form leaves
  /// out (not a term, or left empty) is cleared.
  static Future<ApplicationLibraryText> update({
    required int id,
    required Map<String, dynamic> values,
    required ClApplicationLibraryMasterNotifier notifier,
  }) => notifier.updateLibraryText(
    id,
    ApplicationLibraryTextPatch(
      kind: kindOf(values),
      name: nameOf(values),
      heading: () => headingOf(values),
      text: textOf(values),
    ),
  );

  /// The kind of [values], as the SDK names it.
  static sdk.ApplicationClauseKind kindOf(Map<String, dynamic> values) {
    final kind = values[ApplicationLibraryTextFormFields.kindId];
    return sdk.ApplicationClauseKind.fromWire(
      (kind as ApplicationClauseKind).jsonName,
    );
  }

  /// The name of [values].
  static String nameOf(Map<String, dynamic> values) =>
      values[ApplicationLibraryTextFormFields.nameId] as String;

  /// The heading of [values]; null for none.
  static ApplicationText? headingOf(Map<String, dynamic> values) =>
      switch (values[ApplicationLibraryTextFormFields.headingId]) {
        final Map<String, String> heading when heading.isNotEmpty =>
          ApplicationText(heading),
        _ => null,
      };

  /// The text of [values].
  static ApplicationText textOf(Map<String, dynamic> values) => ApplicationText(
    values[ApplicationLibraryTextFormFields.textId] as Map<String, String>,
  );

  /// What a schema refusal puts on the form's fields; empty when [error]
  /// is about nothing the form holds.
  static Map<String, String> fieldErrorsFor(Object error) =>
      schemaFieldErrors(error, schemaFieldIds);

  /// Whether [error] refuses a write because the text is gone (404
  /// `APPLICATION_LIBRARY_TEXT_NOT_FOUND`).
  static bool isGone(Object error) =>
      error is ServerException &&
      error.code == SdkErrorCode.applicationLibraryTextNotFound;
}
