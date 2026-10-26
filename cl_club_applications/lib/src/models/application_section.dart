import 'package:cl_club_forms/cl_club_forms.dart' show ApplicationFormFields;

/// The sections the editor shows an application template in, in order;
/// each edits its own [keys] of the template's form JSON.
enum ApplicationSection {
  /// The print languages, the organisation, title, subtitle and footer line.
  heading('Languages and titles', [
    ApplicationFormFields.languagesId,
    ApplicationFormFields.organisationId,
    ApplicationFormFields.titleId,
    ApplicationFormFields.subtitleId,
    ApplicationFormFields.formFooterId,
  ]),

  /// The facts the texts refer to.
  facts('Facts', [ApplicationFormFields.factsId]),

  /// The header strip.
  header('Header', [ApplicationFormFields.headerId]),

  /// The age categories.
  ageCategories('Age categories', [ApplicationFormFields.ageCategoriesId]),

  /// The additional selections.
  selections('Additional selections', [ApplicationFormFields.selectionsId]),

  /// The declaration above the signatures.
  declaration('Declaration', [ApplicationFormFields.declarationId]),

  /// The terms on page 2.
  terms('Terms', [ApplicationFormFields.termsId]),

  /// The notes under the terms.
  notes('Notes', [ApplicationFormFields.termsNotesId]),

  /// The standard labels the template overrides.
  labels('Labels', [ApplicationFormFields.labelOverridesId]);

  const ApplicationSection(this.title, this.keys);

  /// The section's heading.
  final String title;

  /// The keys of the template's form JSON the section edits.
  final List<String> keys;

  /// The section's key, for tests and the integration suite.
  String get cardKey => 'application.section.$name';
}
