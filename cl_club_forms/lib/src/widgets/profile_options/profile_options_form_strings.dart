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

  /// Hint in an empty language name.
  static const String languagePlaceholder = 'Language name';

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
}
