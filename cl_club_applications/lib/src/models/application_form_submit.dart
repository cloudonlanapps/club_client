import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ApplicationClauseFill,
        ApplicationClauseFilled,
        ApplicationClauseRefused,
        ApplicationFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClApplicationsMasterNotifier, schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart';

import '../constants/application_view_strings.dart';
import 'application_form_json.dart';
import 'application_section.dart';

/// The application forms' initial values from [template]: its content as
/// the forms hold it, or nothing for a new one.
Map<String, dynamic> buildApplicationFormInitialValues(
  ApplicationTemplate? template,
) => template == null ? {} : ApplicationFormJson.fromContent(template.content);

/// The adapter between the application forms and the applications master
/// (form rule 18): create from `ApplicationCreateForm`, and a partial
/// update per section that sends that section's fields alone (rule 21).
abstract final class ApplicationFormSubmit {
  /// The server's name of each field a section sends → the form's field id
  /// that holds it, for a schema refusal (club_client#114).
  static const Map<String, String> schemaFieldIds = {
    'languages': ApplicationFormFields.languagesId,
    'facts': ApplicationFormFields.factsId,
    'organisation': ApplicationFormFields.organisationId,
    'title': ApplicationFormFields.titleId,
    'subtitle': ApplicationFormFields.subtitleId,
    'formFooter': ApplicationFormFields.formFooterId,
    'header': ApplicationFormFields.headerId,
    'ageCategories': ApplicationFormFields.ageCategoriesId,
    'selections': ApplicationFormFields.selectionsId,
    'declaration': ApplicationFormFields.declarationId,
    'terms': ApplicationFormFields.termsId,
    'termsNotes': ApplicationFormFields.termsNotesId,
    'labelOverrides': ApplicationFormFields.labelOverridesId,
  };

  /// Creates a draft from `ApplicationCreateForm`'s [values]: its title and
  /// print languages.
  static Future<ApplicationTemplate> create({
    required Map<String, dynamic> values,
    required ClApplicationsMasterNotifier notifier,
  }) => notifier.createApplication(ApplicationFormJson.toContent(values));

  /// The patch that sends exactly the fields [values] holds.
  static ApplicationPatch patchOf(Map<String, dynamic> values) {
    final j = ApplicationFormJson.plain(values);
    T? Function()? field<T>(String key, T? Function(Object?) read) =>
        j.containsKey(key) ? () => read(j[key]) : null;
    return ApplicationPatch(
      languages: field(
        ApplicationFormFields.languagesId,
        ApplicationFormJson.languages,
      ),
      facts: field(ApplicationFormFields.factsId, ApplicationFormJson.facts),
      organisation: field(
        ApplicationFormFields.organisationId,
        ApplicationFormJson.text,
      ),
      title: field(ApplicationFormFields.titleId, ApplicationFormJson.text),
      subtitle: field(
        ApplicationFormFields.subtitleId,
        ApplicationFormJson.text,
      ),
      header: field(ApplicationFormFields.headerId, ApplicationFormJson.header),
      ageCategories: field(
        ApplicationFormFields.ageCategoriesId,
        ApplicationFormJson.ageCategories,
      ),
      selections: field(
        ApplicationFormFields.selectionsId,
        ApplicationFormJson.selections,
      ),
      declaration: field(
        ApplicationFormFields.declarationId,
        ApplicationFormJson.text,
      ),
      formFooter: field(
        ApplicationFormFields.formFooterId,
        ApplicationFormJson.text,
      ),
      terms: field(ApplicationFormFields.termsId, ApplicationFormJson.terms),
      termsNotes: field(
        ApplicationFormFields.termsNotesId,
        ApplicationFormJson.notes,
      ),
      labelOverrides: field(
        ApplicationFormFields.labelOverridesId,
        ApplicationFormJson.labelOverrides,
      ),
    );
  }

  /// Sends [section]'s fields of [values] to draft [id], and no other.
  static Future<ApplicationTemplate> updateSection(
    ApplicationSection section, {
    required int id,
    required Map<String, dynamic> values,
    required ClApplicationsMasterNotifier notifier,
  }) => notifier.updateApplication(
    id,
    patchOf({
      for (final key in section.keys)
        if (values.containsKey(key)) key: values[key],
    }),
  );

  /// Sends the print languages, organisation, title, subtitle and footer.
  static Future<ApplicationTemplate> updateHeading({
    required int id,
    required Map<String, dynamic> values,
    required ClApplicationsMasterNotifier notifier,
  }) => updateSection(
    ApplicationSection.heading,
    id: id,
    values: values,
    notifier: notifier,
  );

  /// Sends the facts.
  static Future<ApplicationTemplate> updateFacts({
    required int id,
    required Map<String, dynamic> values,
    required ClApplicationsMasterNotifier notifier,
  }) => updateSection(
    ApplicationSection.facts,
    id: id,
    values: values,
    notifier: notifier,
  );

  /// Sends the header items.
  static Future<ApplicationTemplate> updateHeader({
    required int id,
    required Map<String, dynamic> values,
    required ClApplicationsMasterNotifier notifier,
  }) => updateSection(
    ApplicationSection.header,
    id: id,
    values: values,
    notifier: notifier,
  );

  /// Sends the age categories.
  static Future<ApplicationTemplate> updateAgeCategories({
    required int id,
    required Map<String, dynamic> values,
    required ClApplicationsMasterNotifier notifier,
  }) => updateSection(
    ApplicationSection.ageCategories,
    id: id,
    values: values,
    notifier: notifier,
  );

  /// Sends the additional selections.
  static Future<ApplicationTemplate> updateSelections({
    required int id,
    required Map<String, dynamic> values,
    required ClApplicationsMasterNotifier notifier,
  }) => updateSection(
    ApplicationSection.selections,
    id: id,
    values: values,
    notifier: notifier,
  );

  /// Sends the declaration.
  static Future<ApplicationTemplate> updateDeclaration({
    required int id,
    required Map<String, dynamic> values,
    required ClApplicationsMasterNotifier notifier,
  }) => updateSection(
    ApplicationSection.declaration,
    id: id,
    values: values,
    notifier: notifier,
  );

  /// Sends the terms.
  static Future<ApplicationTemplate> updateTerms({
    required int id,
    required Map<String, dynamic> values,
    required ClApplicationsMasterNotifier notifier,
  }) => updateSection(
    ApplicationSection.terms,
    id: id,
    values: values,
    notifier: notifier,
  );

  /// Sends the notes under the terms.
  static Future<ApplicationTemplate> updateNotes({
    required int id,
    required Map<String, dynamic> values,
    required ClApplicationsMasterNotifier notifier,
  }) => updateSection(
    ApplicationSection.notes,
    id: id,
    values: values,
    notifier: notifier,
  );

  /// Sends the label overrides.
  static Future<ApplicationTemplate> updateLabels({
    required int id,
    required Map<String, dynamic> values,
    required ClApplicationsMasterNotifier notifier,
  }) => updateSection(
    ApplicationSection.labels,
    id: id,
    values: values,
    notifier: notifier,
  );

  /// Fills library clause [clause] for the editor to insert
  /// (club_client#336): each gap takes the fact of [template] that [facts]
  /// names for it (gap → fact name). Gives the filled text in the forms'
  /// type, or, when the server refuses or cannot be reached, the message
  /// the form shows under its clause list. The template is not changed.
  static Future<ApplicationClauseFill> fillClause({
    required String clause,
    required Map<String, String> facts,
    required ApplicationTemplate template,
    required ClApplicationsMasterNotifier notifier,
  }) async {
    final saved = template.content.facts;
    try {
      final filled = await notifier.fillClause(
        clause,
        facts: {
          for (final MapEntry(key: gap, value: name) in facts.entries)
            if (saved[name] case final ApplicationFact fact) gap: fact,
        },
      );
      return ApplicationClauseFilled(
        text: filled.text.texts,
        heading: filled.heading?.texts ?? const {},
      );
    } on Object catch (e) {
      return ApplicationClauseRefused(
        e is ServerException &&
                e.code == SdkErrorCode.applicationInvalidReference
            ? ApplicationViewStrings.clauseNotFilled
            : ApplicationViewStrings.clauseFillFailed,
      );
    }
  }

  /// What a schema refusal puts on the form's fields; empty when [error]
  /// is about nothing the form holds.
  static Map<String, String> fieldErrorsFor(Object error) =>
      schemaFieldErrors(error, schemaFieldIds);

  /// Whether [error] refuses a write because the template is no longer a
  /// draft (422 `INVALID_STATE`).
  static bool isNotDraft(Object error) =>
      error is ServerException && error.code == SdkErrorCode.invalidState;
}
