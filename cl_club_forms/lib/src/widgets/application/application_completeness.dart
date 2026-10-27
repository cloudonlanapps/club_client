import '../../models/application/application_custom_text.dart';
import '../../models/application/application_joined_text.dart';
import '../../models/application/application_text_value.dart';
import 'application_form_fields.dart';

/// What an application template still lacks before it can be saved, as the
/// server checks it: the title, the declaration and the footer line must be
/// there, and they, each term (heading and body), each note's text and
/// each selection must have text in every print language. Header items,
/// attributions and age-category names may stay English only.
abstract final class ApplicationCompleteness {
  /// The texts that must be there whatever the languages.
  static const List<String> requiredTexts = [
    ApplicationFormFields.titleId,
    ApplicationFormFields.declarationId,
    ApplicationFormFields.formFooterId,
  ];

  /// Where [template], a template's JSON, lacks a text, by its place
  /// (`title`, `terms[1].body`, `terms_notes[0].text`, `selections[2]`), in
  /// the order the form prints them.
  static List<String> missingTexts(Map<String, Object?> template) =>
      missingLanguages(template).keys.toList();

  /// What [template], a template's JSON, lacks, by place as in
  /// [missingTexts] and in the same order: the codes of the print
  /// languages each text is not written in, in the template's print order
  /// (club_client#387). An empty list is a required text with nothing
  /// written.
  static Map<String, List<String>> missingLanguages(
    Map<String, Object?> template,
  ) {
    final languages = languagesOf(template);
    final found = <String, List<String>>{};

    void need(String place, Object? json) {
      final value = ApplicationTextValue.fromJson(json);
      if (value == null) return;
      final lacking = lackingLanguages(value, languages);
      if (lacking.isNotEmpty) found[place] = lacking;
    }

    for (final key in requiredTexts) {
      if (ApplicationTextValue.fromJson(template[key]) == null) {
        found[key] = const [];
      } else {
        need(key, template[key]);
      }
    }
    final terms = listOf(template[ApplicationFormFields.termsId]);
    for (var i = 0; i < terms.length; i++) {
      final term = terms[i];
      final place = '${ApplicationFormFields.termsId}[$i]';
      if (term is Map) {
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

  /// Whether [value] prints in every one of [languages].
  static bool isComplete(ApplicationTextValue value, List<String> languages) =>
      lackingLanguages(value, languages).isEmpty;

  /// Those of [languages] that [value], or a part of it, is not written
  /// in, in the order of [languages].
  static List<String> lackingLanguages(
    ApplicationTextValue value,
    List<String> languages,
  ) => switch (value) {
    ApplicationJoinedText(:final parts) => [
      for (final code in languages)
        if (parts.any((part) => lackingLanguages(part, [code]).isNotEmpty))
          code,
    ],
    ApplicationCustomText(:final text) => [
      for (final code in languages)
        if (!(text[code]?.isNotEmpty ?? false)) code,
    ],
    _ => languages,
  };
}
