/// Field ids of `ProfileOptionsForm`, and the keys of a position it holds
/// and returns.
abstract final class ProfileOptionsFormFields {
  /// The club's positions (`List`): each a map of [valueKey] (`String`)
  /// and [labelKey] (`Map<String, String>`, language code to label).
  static const String positionsId = 'positions';

  /// The club's languages (`List<String>`), by name.
  static const String languagesId = 'languages';

  /// A position's stored value.
  static const String valueKey = 'value';

  /// A position's labels, by language code.
  static const String labelKey = 'label';

  /// The language every position needs a label in.
  static const String requiredLabelLanguage = 'en';
}
