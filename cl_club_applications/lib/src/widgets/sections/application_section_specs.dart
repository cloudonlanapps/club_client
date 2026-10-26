import 'package:cl_club_forms/cl_club_forms.dart';

import '../../models/application_form_submit.dart';
import '../../models/application_section.dart';
import 'application_section_spec.dart';

/// The spec of each editor section: which `cl_club_forms` form it hosts,
/// with what, and which `ApplicationFormSubmit` method saves it.
abstract final class ApplicationSectionSpecs {
  /// The spec of [section].
  static ApplicationSectionSpec of(ApplicationSection section) =>
      switch (section) {
        ApplicationSection.heading =>
          TypedApplicationSectionSpec<ApplicationHeadingFormState>(
            build: (key, t, o, {required enabled}) => ApplicationHeadingForm(
              key: key,
              initialValues: t,
              languageOptions: o.languageOptions,
              facts: o.factTypes(t),
              enabled: enabled,
            ),
            save: ApplicationFormSubmit.updateHeading,
            onValidate: (s) => s.validate(),
            onIsDirty: (s) => s.isDirty,
            onShowErrors: (s, f, e) =>
                s.showErrors(fieldErrors: f, formError: e),
          ),
        ApplicationSection.facts =>
          TypedApplicationSectionSpec<ApplicationFactsFormState>(
            build: (key, t, o, {required enabled}) => ApplicationFactsForm(
              key: key,
              initialValues: t,
              languages: o.printLanguages(t),
              choices: o.choices,
              enabled: enabled,
            ),
            save: ApplicationFormSubmit.updateFacts,
            onValidate: (s) => s.validate(),
            onIsDirty: (s) => s.isDirty,
            onShowErrors: (s, f, e) =>
                s.showErrors(fieldErrors: f, formError: e),
          ),
        ApplicationSection.header =>
          TypedApplicationSectionSpec<ApplicationHeaderFormState>(
            build: (key, t, o, {required enabled}) => ApplicationHeaderForm(
              key: key,
              initialValues: t,
              languages: o.printLanguages(t),
              facts: o.factTypes(t),
              clauses: o.clauses,
              enabled: enabled,
            ),
            save: ApplicationFormSubmit.updateHeader,
            onValidate: (s) => s.validate(),
            onIsDirty: (s) => s.isDirty,
            onShowErrors: (s, f, e) =>
                s.showErrors(fieldErrors: f, formError: e),
          ),
        ApplicationSection.ageCategories =>
          TypedApplicationSectionSpec<ApplicationAgeCategoriesFormState>(
            build: (key, t, o, {required enabled}) =>
                ApplicationAgeCategoriesForm(
                  key: key,
                  initialValues: t,
                  languages: o.printLanguages(t),
                  enabled: enabled,
                ),
            save: ApplicationFormSubmit.updateAgeCategories,
            onValidate: (s) => s.validate(),
            onIsDirty: (s) => s.isDirty,
            onShowErrors: (s, f, e) =>
                s.showErrors(fieldErrors: f, formError: e),
          ),
        ApplicationSection.selections =>
          TypedApplicationSectionSpec<ApplicationSelectionsFormState>(
            build: (key, t, o, {required enabled}) => ApplicationSelectionsForm(
              key: key,
              initialValues: t,
              languages: o.printLanguages(t),
              facts: o.factTypes(t),
              clauses: o.clauses,
              enabled: enabled,
            ),
            save: ApplicationFormSubmit.updateSelections,
            onValidate: (s) => s.validate(),
            onIsDirty: (s) => s.isDirty,
            onShowErrors: (s, f, e) =>
                s.showErrors(fieldErrors: f, formError: e),
          ),
        ApplicationSection.declaration =>
          TypedApplicationSectionSpec<ApplicationDeclarationFormState>(
            build: (key, t, o, {required enabled}) =>
                ApplicationDeclarationForm(
                  key: key,
                  initialValues: t,
                  languages: o.printLanguages(t),
                  facts: o.factTypes(t),
                  clauses: o.clauses,
                  enabled: enabled,
                ),
            save: ApplicationFormSubmit.updateDeclaration,
            onValidate: (s) => s.validate(),
            onIsDirty: (s) => s.isDirty,
            onShowErrors: (s, f, e) =>
                s.showErrors(fieldErrors: f, formError: e),
          ),
        ApplicationSection.terms =>
          TypedApplicationSectionSpec<ApplicationTermsFormState>(
            build: (key, t, o, {required enabled}) => ApplicationTermsForm(
              key: key,
              initialValues: t,
              languages: o.printLanguages(t),
              facts: o.factTypes(t),
              clauses: o.clauses,
              enabled: enabled,
            ),
            save: ApplicationFormSubmit.updateTerms,
            onValidate: (s) => s.validate(),
            onIsDirty: (s) => s.isDirty,
            onShowErrors: (s, f, e) =>
                s.showErrors(fieldErrors: f, formError: e),
          ),
        ApplicationSection.notes =>
          TypedApplicationSectionSpec<ApplicationNotesFormState>(
            build: (key, t, o, {required enabled}) => ApplicationNotesForm(
              key: key,
              initialValues: t,
              languages: o.printLanguages(t),
              facts: o.factTypes(t),
              clauses: o.clauses,
              enabled: enabled,
            ),
            save: ApplicationFormSubmit.updateNotes,
            onValidate: (s) => s.validate(),
            onIsDirty: (s) => s.isDirty,
            onShowErrors: (s, f, e) =>
                s.showErrors(fieldErrors: f, formError: e),
          ),
        ApplicationSection.labels =>
          TypedApplicationSectionSpec<ApplicationLabelsFormState>(
            build: (key, t, o, {required enabled}) => ApplicationLabelsForm(
              key: key,
              initialValues: t,
              labels: o.labels,
              languages: o.printLanguages(t),
              enabled: enabled,
            ),
            save: ApplicationFormSubmit.updateLabels,
            onValidate: (s) => s.validate(),
            onIsDirty: (s) => s.isDirty,
            onShowErrors: (s, f, e) =>
                s.showErrors(fieldErrors: f, formError: e),
          ),
      };
}
