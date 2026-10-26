import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ApplicationClauseOption,
        ApplicationClauseText,
        ApplicationCustomText,
        ApplicationFactText,
        ApplicationFormFields,
        ApplicationJoinedText,
        ApplicationTextValue;

import '../constants/application_view_strings.dart';
import '../models/application_editor_options.dart';

/// Reads an application template's texts as they print, for the editor's
/// read mode: a clause with its gaps filled by the template's facts, a fact
/// as its value, custom text as written. A clause the library lacks reads
/// as its id; a gap with no fact as `{gap}`.
class ApplicationTextReader {
  /// A reader of [template], the forms' JSON, with the library in
  /// [options].
  ApplicationTextReader({required this.template, required this.options})
    : clauses = options.clausesById;

  /// Separates the parts of a joined text.
  static const String partSeparator = ' · ';

  /// Separates a text's languages.
  static const String languageSeparator = ' / ';

  /// Separates a range's ends.
  static const String rangeSeparator = ' – ';

  /// Separates the choices of a fact.
  static const String choiceSeparator = ', ';

  /// The template, as the forms hold it.
  final Map<String, dynamic> template;

  /// The library and catalogue.
  final ApplicationEditorOptions options;

  /// The library's clauses by id.
  final Map<String, ApplicationClauseOption> clauses;

  /// The print language codes.
  List<String> get languages => [
    for (final l in options.printLanguages(template)) l.code,
  ];

  /// [json], a text, in every print language, each once; `''` for none.
  String read(Object? json) {
    final value = ApplicationTextValue.fromJson(json);
    if (value == null) return '';
    final texts = <String>[];
    for (final code in languages) {
      final text = inLanguage(value, code);
      if (text.isNotEmpty && !texts.contains(text)) texts.add(text);
    }
    return texts.join(languageSeparator);
  }

  /// The heading of a rule clause [json] names, in every print language;
  /// `''` when it names none.
  String clauseHeading(Object? json) {
    final value = ApplicationTextValue.fromJson(json);
    if (value is! ApplicationClauseText) return '';
    final heading = clauses[value.clause]?.heading ?? const {};
    return {
      for (final code in languages)
        if (heading[code] ?? heading[ApplicationFormFields.english]
            case final String text)
          text,
    }.join(languageSeparator);
  }

  /// [value] in language [code], English where it has no [code].
  String inLanguage(ApplicationTextValue value, String code) {
    switch (value) {
      case ApplicationCustomText(:final text):
        return text[code] ?? text[ApplicationFormFields.english] ?? '';
      case ApplicationFactText(:final fact):
        return fact.isEmpty ? '' : factValue(fact, code);
      case ApplicationClauseText(:final clause, :final args):
        final option = clauses[clause];
        if (option == null) return clause;
        var text =
            option.text[code] ??
            option.text[ApplicationFormFields.english] ??
            '';
        for (final gap in option.gaps.keys) {
          final fact = args[gap];
          if (fact != null) {
            text = text.replaceAll('{$gap}', factValue(fact, code));
          }
        }
        return text;
      case ApplicationJoinedText(:final parts):
        return [
          for (final part in parts) inLanguage(part, code),
        ].where((t) => t.isNotEmpty).join(partSeparator);
      default:
        return '';
    }
  }

  /// The fact [name]'s value as it prints in [code]; its name in braces
  /// when the template has no such fact.
  String factValue(String name, String code) {
    final facts = template[ApplicationFormFields.factsId];
    final fact = facts is Map ? facts[name] : null;
    if (fact is! Map) return '{$name}';
    final value = fact[ApplicationFormFields.valueKey];
    return switch (fact[ApplicationFormFields.typeKey]) {
      'date' => day(value),
      'date_range' =>
        '${day(fact[ApplicationFormFields.fromKey])}$rangeSeparator'
            '${day(fact[ApplicationFormFields.toKey])}',
      'choices' => [
        for (final id in value is List ? value.whereType<String>() : <String>[])
          choice(id, code),
      ].join(choiceSeparator),
      _ when value is Map =>
        '${value[code] ?? value[ApplicationFormFields.english] ?? ''}',
      _ => value == null ? '' : '$value',
    };
  }

  /// The library's choice [id] in [code].
  String choice(String id, String code) {
    for (final option in options.choices) {
      if (option.id == id) {
        return option.text[code] ??
            option.text[ApplicationFormFields.english] ??
            id;
      }
    }
    return id;
  }

  /// A day as the forms hold it (`2026-11-19`) as shown (`19 Nov 2026`).
  static String day(Object? stored) {
    final parts = stored is String ? stored.split('-') : const <String>[];
    final numbers = [for (final p in parts) int.tryParse(p)];
    if (numbers.length != 3 || numbers.contains(null)) return '';
    final [year, month, date] = numbers;
    const months = ApplicationViewStrings.months;
    if (month! < 1 || month > months.length) return '';
    return '$date ${months[month - 1]} $year';
  }
}
