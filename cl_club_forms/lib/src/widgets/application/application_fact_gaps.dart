import '../../models/application/application_fact_gap.dart';
import 'application_completeness.dart';
import 'application_form_fields.dart';

/// The `{name}` gaps of an application template that name no fact of it
/// (club_client#389), found as the server's Save finds them
/// (club_server#126, `APPLICATION_UNKNOWN_FACT`), so the editor can list
/// them and keep Save off first.
///
/// A gap is `{name}` with `name` a lowercase letter then lowercase letters,
/// digits or `_`; any other brace text (`{Venue}`, `{ x }`, `{1st}`) is
/// literal. The texts checked are the organisation, title, subtitle, each
/// header item (each line of one held as lines), each selection, the
/// declaration, the footer line, each term's heading and body, and each
/// note's text and attribution. Label overrides, age-category names and
/// fact values print as written and are not checked.
abstract final class ApplicationFactGaps {
  /// A gap, its name in group 1.
  static final RegExp gapPattern = RegExp(r'\{([a-z][a-z0-9_]*)\}');

  /// The texts checked that hold one text each, before the header items.
  static const List<String> leadingTexts = [
    ApplicationFormFields.organisationId,
    ApplicationFormFields.titleId,
    ApplicationFormFields.subtitleId,
  ];

  /// The texts checked that hold one text each, after the selections.
  static const List<String> middleTexts = [
    ApplicationFormFields.declarationId,
    ApplicationFormFields.formFooterId,
  ];

  /// The parts of a term checked, in order.
  static const List<String> termParts = [
    ApplicationFormFields.headingKey,
    ApplicationFormFields.bodyKey,
  ];

  /// The parts of a note checked, in order.
  static const List<String> noteParts = [
    ApplicationFormFields.textKey,
    ApplicationFormFields.attributionKey,
  ];

  /// Each gap of [template], a template's JSON, naming none of its facts,
  /// in print order: by place, then the print languages before any other
  /// language the text has, then as the text reads. A gap repeated in one
  /// text is listed once.
  static List<ApplicationFactGap> unknown(Map<String, Object?> template) {
    final facts = template[ApplicationFormFields.factsId];
    final known = facts is Map ? facts.keys.toSet() : const <Object?>{};
    final languages = ApplicationCompleteness.languagesOf(template);
    return [
      for (final (place, text) in printedTexts(template))
        for (final language in [
          for (final code in languages)
            if (text.containsKey(code)) code,
          for (final code in text.keys)
            if (!languages.contains(code)) code,
        ])
          for (final name in namesIn(text[language]!))
            if (!known.contains(name))
              ApplicationFactGap(place: place, language: language, name: name),
    ];
  }

  /// The gap names in [text], each once, in the order it reads.
  static List<String> namesIn(String text) => [
    ...{for (final match in gapPattern.allMatches(text)) match.group(1)!},
  ];

  /// Every text of [template] a gap may sit in, by place, in print order;
  /// a text with nothing written is left out.
  static List<(String, Map<String, String>)> printedTexts(
    Map<String, Object?> template,
  ) {
    final found = <(String, Map<String, String>)>[];
    void add(String place, Object? json) {
      final text = textOf(json);
      if (text.isNotEmpty) found.add((place, text));
    }

    for (final key in leadingTexts) {
      add(key, template[key]);
    }
    final header = ApplicationCompleteness.listOf(
      template[ApplicationFormFields.headerId],
    );
    for (var i = 0; i < header.length; i++) {
      final place = '${ApplicationFormFields.headerId}[$i]';
      if (header[i] case final List<Object?> lines) {
        for (var j = 0; j < lines.length; j++) {
          add('$place[$j]', lines[j]);
        }
      } else {
        add(place, header[i]);
      }
    }
    final selections = ApplicationCompleteness.listOf(
      template[ApplicationFormFields.selectionsId],
    );
    for (var i = 0; i < selections.length; i++) {
      add('${ApplicationFormFields.selectionsId}[$i]', selections[i]);
    }
    for (final key in middleTexts) {
      add(key, template[key]);
    }
    final terms = ApplicationCompleteness.listOf(
      template[ApplicationFormFields.termsId],
    );
    for (var i = 0; i < terms.length; i++) {
      for (final part in termParts) {
        add(
          '${ApplicationFormFields.termsId}[$i].$part',
          partOf(terms[i], part),
        );
      }
    }
    final notes = ApplicationCompleteness.listOf(
      template[ApplicationFormFields.termsNotesId],
    );
    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      for (final part in noteParts) {
        add(
          '${ApplicationFormFields.termsNotesId}[$i].$part',
          part == ApplicationFormFields.textKey
              ? ApplicationCompleteness.noteText(note)
              : partOf(note, part),
        );
      }
    }
    return found;
  }

  /// [json]'s [part] when it is a map; null otherwise.
  static Object? partOf(Object? json, String part) =>
      json is Map ? json[part] : null;

  /// The text [json] holds by language, as written: its entries whose
  /// language and text are strings.
  static Map<String, String> textOf(Object? json) => {
    if (json is Map)
      for (final entry in json.entries)
        if (entry.key case final String code)
          if (entry.value case final String text) code: text,
  };
}
