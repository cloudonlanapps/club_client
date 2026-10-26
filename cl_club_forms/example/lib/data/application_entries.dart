import 'package:cl_club_forms/cl_club_forms.dart';

import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'application_samples.dart';

/// The forms of an application template: creating a draft, then one per
/// section.
abstract final class ApplicationEntries {
  /// The entries, in the order shown.
  static List<FormDemoEntry> get all => [
    FormDemoEntry(
      id: 'application-create',
      title: 'Application create form',
      group: FormDemoGroup.applications,
      formType: ApplicationCreateForm,
      builder: (key) => ApplicationCreateForm(
        key: key,
        languageOptions: ApplicationSamples.languageOptions,
      ),
    ),
    FormDemoEntry(
      id: 'application-heading',
      title: 'Application heading form',
      group: FormDemoGroup.applications,
      formType: ApplicationHeadingForm,
      builder: (key) => ApplicationHeadingForm(
        key: key,
        initialValues: ApplicationSamples.template,
        languageOptions: ApplicationSamples.languageOptions,
        facts: ApplicationSamples.facts,
      ),
    ),
    FormDemoEntry(
      id: 'application-facts',
      title: 'Application facts form',
      group: FormDemoGroup.applications,
      formType: ApplicationFactsForm,
      builder: (key) => ApplicationFactsForm(
        key: key,
        initialValues: ApplicationSamples.template,
        languages: ApplicationSamples.printLanguages,
        choices: ApplicationSamples.choices,
      ),
    ),
    FormDemoEntry(
      id: 'application-header',
      title: 'Application header form',
      group: FormDemoGroup.applications,
      formType: ApplicationHeaderForm,
      builder: (key) => ApplicationHeaderForm(
        key: key,
        initialValues: ApplicationSamples.template,
        languages: ApplicationSamples.printLanguages,
        facts: ApplicationSamples.facts,
        clauses: ApplicationSamples.clauses,
      ),
    ),
    FormDemoEntry(
      id: 'application-age-categories',
      title: 'Application age categories form',
      group: FormDemoGroup.applications,
      formType: ApplicationAgeCategoriesForm,
      builder: (key) => ApplicationAgeCategoriesForm(
        key: key,
        initialValues: ApplicationSamples.template,
        languages: ApplicationSamples.printLanguages,
      ),
    ),
    FormDemoEntry(
      id: 'application-selections',
      title: 'Application selections form',
      group: FormDemoGroup.applications,
      formType: ApplicationSelectionsForm,
      builder: (key) => ApplicationSelectionsForm(
        key: key,
        initialValues: ApplicationSamples.template,
        languages: ApplicationSamples.printLanguages,
        facts: ApplicationSamples.facts,
        clauses: ApplicationSamples.clauses,
      ),
    ),
    FormDemoEntry(
      id: 'application-declaration',
      title: 'Application declaration form',
      group: FormDemoGroup.applications,
      formType: ApplicationDeclarationForm,
      builder: (key) => ApplicationDeclarationForm(
        key: key,
        initialValues: ApplicationSamples.template,
        languages: ApplicationSamples.printLanguages,
        facts: ApplicationSamples.facts,
        clauses: ApplicationSamples.clauses,
      ),
    ),
    FormDemoEntry(
      id: 'application-terms',
      title: 'Application terms form',
      group: FormDemoGroup.applications,
      formType: ApplicationTermsForm,
      builder: (key) => ApplicationTermsForm(
        key: key,
        initialValues: ApplicationSamples.template,
        languages: ApplicationSamples.printLanguages,
        facts: ApplicationSamples.facts,
        clauses: ApplicationSamples.clauses,
      ),
    ),
    FormDemoEntry(
      id: 'application-notes',
      title: 'Application notes form',
      group: FormDemoGroup.applications,
      formType: ApplicationNotesForm,
      builder: (key) => ApplicationNotesForm(
        key: key,
        initialValues: ApplicationSamples.template,
        languages: ApplicationSamples.printLanguages,
        facts: ApplicationSamples.facts,
        clauses: ApplicationSamples.clauses,
      ),
    ),
    FormDemoEntry(
      id: 'application-labels',
      title: 'Application labels form',
      group: FormDemoGroup.applications,
      formType: ApplicationLabelsForm,
      builder: (key) => ApplicationLabelsForm(
        key: key,
        initialValues: ApplicationSamples.template,
        labels: ApplicationSamples.labels,
        languages: ApplicationSamples.printLanguages,
      ),
    ),
  ];
}
