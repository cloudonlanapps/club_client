import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ApplicationChoiceOption,
        ApplicationClauseKind,
        ApplicationClauseOption,
        ApplicationFactType,
        ApplicationFormFields,
        ApplicationLabelOption,
        ApplicationLanguageOption;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show ApplicationClauseKind;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ApplicationClause, ApplicationClauseLibrary, ApplicationLabels;
import 'package:flutter/foundation.dart';

import '../constants/application_view_strings.dart';

/// What the application forms choose from, read from the server's label
/// catalogue and clauses list and put in the forms' own types (form
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
      clauses: [for (final c in library.clauses) clause(c)],
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

  /// An entry of the clauses list in the forms' type (club_client#389,
  /// #396): every entry is one of the club's library texts, the seeded
  /// built-in ones among them, by its id, with its name; its text and
  /// heading as written.
  static ApplicationClauseOption clause(ApplicationClause clause) =>
      ApplicationClauseOption(
        id: '${clause.id}',
        kind: kindOf(clause.kind),
        text: clause.text.texts,
        heading: clause.heading?.texts ?? const {},
        name: clause.name,
      );

  /// The SDK's [kind] as the forms name it; a kind the forms do not know
  /// is taken for a note.
  static ApplicationClauseKind kindOf(sdk.ApplicationClauseKind kind) =>
      ApplicationClauseKind.fromJson(kind.wireName) ??
      ApplicationClauseKind.note;

  /// The languages a template may print in, English first.
  final List<ApplicationLanguageOption> languageOptions;

  /// The club's library texts, in the library's order.
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
