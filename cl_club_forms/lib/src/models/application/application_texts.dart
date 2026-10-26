/// Reads a text per language from the JSON of a template, the clause
/// library or the label catalogue.
abstract final class ApplicationTexts {
  /// The texts of [json], a map of language code to text, trimmed: a note
  /// (a key starting with `_`), an empty text and anything that is not a
  /// text are left out. Empty when [json] is no map.
  static Map<String, String> of(Object? json) => {
    if (json is Map)
      for (final entry in json.entries)
        if (entry.key case final String code when !code.startsWith('_'))
          if (entry.value case final String text when text.trim().isNotEmpty)
            code: text.trim(),
  };
}
