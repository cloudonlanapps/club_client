import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ApplicationChoiceOption,
        ApplicationClauseKind,
        ApplicationClauseOption,
        ApplicationFactType,
        ApplicationFormFields,
        ApplicationLabelOption,
        ApplicationLanguageOption;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ApplicationClause, ApplicationClauseLibrary, ApplicationLabels;
import 'package:flutter/foundation.dart';

import '../constants/application_view_strings.dart';

/// What the application forms choose from, read from the server's label
/// catalogue and clause library and put in the forms' own types (form
/// rule 7).
@immutable
class ApplicationEditorOptions {
  const ApplicationEditorOptions({
    required this.languageOptions,
    required this.clauses,
    required this.choices,
    required this.labels,
  });

  /// The options of [labels] and [library].
  factory ApplicationEditorOptions.from(
    ApplicationLabels labels,
    ApplicationClauseLibrary library,
  ) {
    final codes = [
      ApplicationFormFields.english,
      for (final code in labels.languages)
        if (code != ApplicationFormFields.english) code,
    ];
    return ApplicationEditorOptions(
      languageOptions: [for (final code in codes) language(code)],
      clauses: [
        for (final e in library.clauses.entries) clause(e.key, e.value),
      ],
      choices: [
        for (final e in library.choices.entries)
          ApplicationChoiceOption(id: e.key, text: e.value),
      ],
      labels: [
        for (final e in labels.labels.entries)
          ApplicationLabelOption(id: e.key, text: e.value),
      ],
    );
  }

  /// The language [code], named.
  static ApplicationLanguageOption language(String code) =>
      ApplicationLanguageOption(
        code: code,
        name: ApplicationViewStrings.languageNames[code] ?? code,
      );

  /// The library's clause [id] in the forms' type: a kind the forms do not
  /// know is taken for a note, a gap of a type they do not know left out.
  static ApplicationClauseOption clause(String id, ApplicationClause clause) =>
      ApplicationClauseOption(
        id: id,
        kind:
            ApplicationClauseKind.fromJson(clause.kind) ??
            ApplicationClauseKind.note,
        text: clause.text,
        heading: clause.heading ?? const {},
        gaps: {
          for (final e in clause.gaps.entries)
            if (ApplicationFactType.fromJson(e.value.wireName)
                case final ApplicationFactType type)
              e.key: type,
        },
      );

  /// The languages a template may print in, English first.
  final List<ApplicationLanguageOption> languageOptions;

  /// The clause library, in its order.
  final List<ApplicationClauseOption> clauses;

  /// The choices a `choices` fact may name.
  final List<ApplicationChoiceOption> choices;

  /// The label catalogue, in its order.
  final List<ApplicationLabelOption> labels;

  /// The print languages of [template], the forms' JSON, each named.
  List<ApplicationLanguageOption> printLanguages(
    Map<String, dynamic> template,
  ) {
    final raw = template[ApplicationFormFields.languagesId];
    final codes = [if (raw is List) ...raw.whereType<String>()];
    return [
      for (final code
          in codes.isEmpty ? [ApplicationFormFields.english] : codes)
        language(code),
    ];
  }

  /// The type of each of [template]'s facts, by name.
  Map<String, ApplicationFactType> factTypes(Map<String, dynamic> template) =>
      ApplicationFactType.ofFacts(template[ApplicationFormFields.factsId]);
}
