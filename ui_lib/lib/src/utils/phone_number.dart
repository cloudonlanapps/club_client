/// Phone numbers in international format (`+<country code><number>`).
///
/// Pure and SDK-free: a form's adapter calls it where a typed phone is
/// saved, passing the club's default country code in. A number already in
/// international format comes back unchanged, so it is equally safe on a
/// number read back from the server, including one stored before numbers
/// were normalised.
abstract final class PhoneNumber {
  /// What opens a number that carries its own country code.
  static const String internationalPrefix = '+';

  /// The international call prefix people type in place of
  /// [internationalPrefix].
  static const String internationalCallPrefix = '00';

  /// The trunk prefix of a national number, dropped once before the country
  /// code is added.
  static const String trunkPrefix = '0';

  /// The punctuation people group digits with: spaces, dashes, dots and
  /// brackets.
  static final RegExp grouping = RegExp(r'[\s\-.()\[\]]');

  /// Anything that is not a digit.
  static final RegExp nonDigit = RegExp('[^0-9]');

  /// A number once its [grouping] is removed: digits, with an optional
  /// leading [internationalPrefix].
  static final RegExp dialable = RegExp(r'^\+?[0-9]+$');

  /// Whether [value] is a number that can be called: digits, optionally
  /// grouped and optionally starting with [internationalPrefix], and
  /// nothing else.
  static bool isDialable(String value) =>
      dialable.hasMatch(value.replaceAll(grouping, ''));

  /// [typed] in international format, completed with [defaultCountryCode]
  /// (digits only, as the server reports it: `91`) when it carries no
  /// country code of its own.
  ///
  /// * spaces, dashes, dots and brackets are removed;
  /// * a number starting with `+` is kept;
  /// * a number starting with `00` has it replaced by `+`;
  /// * any other number loses one leading `0` and is prefixed with
  ///   `+<defaultCountryCode>`.
  ///
  /// Returns `''` when nothing is left after the punctuation is removed.
  static String toInternational(
    String typed, {
    required String defaultCountryCode,
  }) {
    final number = typed.replaceAll(grouping, '');
    if (number.isEmpty) return '';
    if (number.startsWith(internationalPrefix)) return number;
    if (number.startsWith(internationalCallPrefix)) {
      final rest = number.substring(internationalCallPrefix.length);
      return '$internationalPrefix$rest';
    }
    final national = number.startsWith(trunkPrefix)
        ? number.substring(trunkPrefix.length)
        : number;
    return '$internationalPrefix$defaultCountryCode$national';
  }

  /// [toInternational] for an optional field: `null` when [typed] is absent
  /// or holds no number.
  static String? toInternationalOrNull(
    String? typed, {
    required String defaultCountryCode,
  }) {
    if (typed == null) return null;
    final number = toInternational(
      typed,
      defaultCountryCode: defaultCountryCode,
    );
    return number.isEmpty ? null : number;
  }
}
