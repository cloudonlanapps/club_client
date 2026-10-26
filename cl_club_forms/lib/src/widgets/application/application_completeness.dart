import '../../models/application/application_clause_option.dart';
import '../../models/application/application_clause_text.dart';
import '../../models/application/application_custom_text.dart';
import '../../models/application/application_fact_text.dart';
import '../../models/application/application_joined_text.dart';
import '../../models/application/application_text_value.dart';
import 'application_form_fields.dart';

/// What an application template still lacks before it can be saved, as the
/// server checks it: the title, the declaration and the footer line must be
/// there, and they, each term (heading and body), each note's text and
/// each selection must have text in every print language. Header items,
/// attributions and age-category names may stay English only.
///
/// A fact prints in every language. A clause has the texts the library
/// gives it; one the library does not have lacks them all.
abstract final class ApplicationCompleteness {
  /// The texts that must be there whatever the languages.
  static const List<String> requiredTexts = [
    ApplicationFormFields.titleId,
    ApplicationFormFields.declarationId,
    ApplicationFormFields.formFooterId,
  ];

  /// Where [template], a template's JSON, lacks a text, by its place
  /// (`title`, `terms[1].body`, `terms_notes[0].text`, `selections[2]`), in
  /// the order the form prints them. [clauses] is the library, by id.
  static List<String> missingTexts(
    Map<String, Object?> template, {
    required Map<String, ApplicationClauseOption> clauses,
  }) {
    final languages = languagesOf(template);
    final found = <String>[];

    void need(String place, Object? json, {bool heading = false}) {
      final value = ApplicationTextValue.fromJson(json);
      if (value != null &&
          !isComplete(value, languages, clauses, heading: heading)) {
        found.add(place);
      }
    }

    for (final key in requiredTexts) {
      if (ApplicationTextValue.fromJson(template[key]) == null) {
        found.add(key);
      } else {
        need(key, template[key]);
      }
    }
    final terms = listOf(template[ApplicationFormFields.termsId]);
    for (var i = 0; i < terms.length; i++) {
      final term = terms[i];
      final place = '${ApplicationFormFields.termsId}[$i]';
      if (term is Map && term.containsKey(ApplicationTextValue.clauseKey)) {
        need('$place.${ApplicationFormFields.headingKey}', term, heading: true);
        need('$place.${ApplicationFormFields.bodyKey}', term);
      } else if (term is Map) {
        need(
          '$place.${ApplicationFormFields.headingKey}',
          term[ApplicationFormFields.headingKey],
        );
        need(
          '$place.${ApplicationFormFields.bodyKey}',
          term[ApplicationFormFields.bodyKey],
        );
      }
    }
    final notes = listOf(template[ApplicationFormFields.termsNotesId]);
    for (var i = 0; i < notes.length; i++) {
      need(
        '${ApplicationFormFields.termsNotesId}[$i].'
        '${ApplicationFormFields.textKey}',
        noteText(notes[i]),
      );
    }
    final selections = listOf(template[ApplicationFormFields.selectionsId]);
    for (var i = 0; i < selections.length; i++) {
      need('${ApplicationFormFields.selectionsId}[$i]', selections[i]);
    }
    return found;
  }

  /// The print languages of [template]; English alone when it names none.
  static List<String> languagesOf(Map<String, Object?> template) {
    final raw = template[ApplicationFormFields.languagesId];
    final languages = [
      if (raw is List) ...raw.whereType<String>(),
    ];
    return languages.isEmpty
        ? const [ApplicationFormFields.english]
        : languages;
  }

  /// [json] as a list; empty when it is none.
  static List<Object?> listOf(Object? json) => json is List ? json : const [];

  /// The text of a note: under its [ApplicationFormFields.textKey], or the
  /// note itself when it is a text value on its own.
  static Object? noteText(Object? note) =>
      note is Map && note.containsKey(ApplicationFormFields.textKey)
      ? note[ApplicationFormFields.textKey]
      : note;

  /// Whether [value] prints in every one of [languages]: for a clause, its
  /// text, or its heading when [heading].
  static bool isComplete(
    ApplicationTextValue value,
    List<String> languages,
    Map<String, ApplicationClauseOption> clauses, {
    bool heading = false,
  }) {
    Map<String, String> texts;
    switch (value) {
      case ApplicationFactText():
        return true;
      case ApplicationJoinedText(:final parts):
        return parts.every((part) => isComplete(part, languages, clauses));
      case ApplicationClauseText(:final clause):
        final option = clauses[clause];
        if (option == null) return false;
        texts = heading ? option.heading : option.text;
      case ApplicationCustomText(:final text):
        texts = text;
      default:
        return false;
    }
    return languages.every((code) => texts[code]?.isNotEmpty ?? false);
  }
}
