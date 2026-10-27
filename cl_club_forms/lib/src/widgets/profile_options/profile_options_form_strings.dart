/// Labels, hints and messages of `ProfileOptionsForm`.
abstract final class ProfileOptionsFormStrings {
  /// Label of the list of positions.
  static const String positions = 'Positions';

  /// Label of the list of languages.
  static const String languages = 'Languages';

  /// Label of a position's stored value.
  static const String positionValue = 'Value';

  /// Text of the button that adds a position.
  static const String addPosition = 'Add position';

  /// Text of the button that adds a language.
  static const String addLanguage = 'Add language';

  /// Label of a language's name.
  static const String languageName = 'Name';

  /// Label of a language's code.
  static const String languageCode = 'Code';

  /// Hint in an empty language name.
  static const String languagePlaceholder = 'Language name';

  /// Hint in an empty language code.
  static const String codePlaceholder = 'e.g. hi';

  /// The row of English, always offered: its [name] and [code].
  static String fixedLanguage(String name, String code) => '$name ($code)';

  /// What the row of English says beside it.
  static const String fixedLanguageHint = 'Always offered';

  /// Shown when a position has no value.
  static const String positionValueRequired = 'Each position needs a value';

  /// Shown when two positions have the same value.
  static String positionValueTwice(String value) =>
      'Two positions have the value "$value"';

  /// Shown when a position has no label in the required language, named
  /// [language].
  static String positionLabelRequired(String language) =>
      'Each position needs a label in $language';

  /// Shown when a language has no name.
  static const String languageNameRequired = 'Each language needs a name';

  /// Shown when a language is listed twice.
  static String languageTwice(String name) => '"$name" is listed twice';

  /// Shown when a language has no code.
  static const String languageCodeRequired = 'Each language needs a code';

  /// Shown when [code] is not written as a language code.
  static String languageCodeInvalid(String code) =>
      '"$code" is not a language code: use lowercase letters, like hi or kok';

  /// Shown when two languages have the code [code].
  static String languageCodeTwice(String code) =>
      'The code "$code" is listed twice';
}
