import '../../../models/application/application_custom_text.dart';
import '../../../models/application/application_fact_type.dart';
import '../application_form_fields.dart';

/// Reads and shapes the facts of an application: the template's `facts`
/// map becomes the rows the facts form holds, one per fact with its name
/// under [ApplicationFormFields.nameKey], and the rows become the map
/// again.
abstract final class ApplicationFactValues {
  /// The facts of [json], the template's `facts` map, as rows; notes left
  /// out.
  static List<Map<String, Object?>> rows(Object? json) => [
    if (json is Map)
      for (final entry in json.entries)
        if (entry.key case final String name when !name.startsWith('_'))
          row(name, entry.value),
  ];

  /// The fact [name] holding [json], as a row: its name, its type (a name
  /// when it has none known) and only the value its type takes.
  static Map<String, Object?> row(String name, Object? json) {
    final fact = json is Map ? json : const <Object?, Object?>{};
    final type =
        ApplicationFactType.fromJson(fact[ApplicationFormFields.typeKey]) ??
        ApplicationFactType.name;
    final value = fact[ApplicationFormFields.valueKey];
    return {
      ApplicationFormFields.nameKey: name,
      ApplicationFormFields.typeKey: type.jsonName,
      ...switch (type) {
        ApplicationFactType.name => {
          ApplicationFormFields.valueKey: nameValue(value),
        },
        ApplicationFactType.date || ApplicationFactType.time => {
          ApplicationFormFields.valueKey: value is String ? value : '',
        },
        ApplicationFactType.dateRange => {
          ApplicationFormFields.fromKey: text(
            fact[ApplicationFormFields.fromKey],
          ),
          ApplicationFormFields.toKey: text(fact[ApplicationFormFields.toKey]),
        },
        ApplicationFactType.amount => {
          if (value is num) ApplicationFormFields.valueKey: value.toInt(),
        },
        ApplicationFactType.choices => {
          ApplicationFormFields.valueKey: [
            if (value is List) ...value.whereType<String>(),
          ],
        },
      },
    };
  }

  /// [value] if it is a text, else `''`.
  static String text(Object? value) => value is String ? value : '';

  /// A name's value: one text when only English is given, else a text per
  /// language; `''` for none.
  static Object nameValue(Object? json) {
    if (json is String) return json.trim();
    final texts = ApplicationCustomText.fromJson(json).text;
    if (texts.keys.every((code) => code == ApplicationFormFields.english)) {
      return texts[ApplicationFormFields.english] ?? '';
    }
    return texts;
  }

  /// The rows of [json] as the template's `facts` map, by name.
  static Map<String, Map<String, Object?>> factsOut(Object? json) => {
    if (json is List)
      for (final row in json.whereType<Map<Object?, Object?>>())
        text(row[ApplicationFormFields.nameKey]).trim(): {
          for (final entry in row.entries)
            if (entry.key != ApplicationFormFields.nameKey)
              entry.key! as String: entry.value,
        },
  };
}
