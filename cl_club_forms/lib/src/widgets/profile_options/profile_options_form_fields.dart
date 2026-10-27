/// Field ids of `ProfileOptionsForm`, and the keys of a position it holds
/// and returns.
abstract final class ProfileOptionsFormFields {
  /// The club's positions (`List`): each a map of [valueKey] (`String`)
  /// and [labelKey] (`Map<String, String>`, language code to label).
  static const String positionsId = 'positions';

  /// The club's languages (`List`): each a map of [codeKey] and [nameKey]
  /// (`String`s), English ([requiredLabelLanguage]) always first
  /// (club_client#396).
  static const String languagesId = 'languages';

  /// A language's code (`en`, `mr`): the key of a label in it.
  static const String codeKey = 'code';

  /// A language's name, as a member chooses it.
  static const String nameKey = 'name';

  /// The name English has when the options do not list it.
  static const String englishName = 'English';

  /// A position's stored value.
  static const String valueKey = 'value';

  /// A position's labels, by language code.
  static const String labelKey = 'label';

  /// The language every position needs a label in, always one of the
  /// club's languages.
  static const String requiredLabelLanguage = 'en';
}
