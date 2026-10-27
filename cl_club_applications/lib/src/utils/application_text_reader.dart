import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ApplicationCustomText,
        ApplicationFormFields,
        ApplicationJoinedText,
        ApplicationTextValue;

import '../constants/application_view_strings.dart';
import '../models/application_editor_options.dart';

/// Reads an application template's texts as they print, for the editor's
/// read mode: each text as written, and a fact as its value.
class ApplicationTextReader {
  /// A reader of [template], the forms' JSON, with the library in
  /// [options].
  ApplicationTextReader({required this.template, required this.options});

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

  /// [value] in language [code], English where it has no [code].
  String inLanguage(ApplicationTextValue value, String code) {
    switch (value) {
      case ApplicationCustomText(:final text):
        return text[code] ?? text[ApplicationFormFields.english] ?? '';
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
