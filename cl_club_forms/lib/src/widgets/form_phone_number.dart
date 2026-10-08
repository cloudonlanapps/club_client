import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// A typed phone number as the forms judge it: put in international format
/// (`+<country code><number>`) the way the hosts' adapters store it, then
/// checked as a number of its country.
///
/// Pure and SDK-free. The validators are in `CommonFormValidators`
/// (`phone`, `phoneOptional`, `internationalPhone`).
abstract final class FormPhoneNumber {
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

  /// A number in international format: [internationalPrefix], then digits
  /// only.
  static final RegExp international = RegExp(r'^\+[0-9]+$');

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

  /// Whether [number], in international format, is a valid number of the
  /// country its country code names. Letters, a number too short or too
  /// long for that country, and a country code that does not exist are
  /// not.
  static bool isValidInternational(String number) {
    if (!international.hasMatch(number)) return false;
    try {
      final parsed = PhoneNumber.parse(number);
      return parsed.isValid() && parsed.international == number;
    } on PhoneNumberException {
      return false;
    }
  }

  /// Whether [typed] is a valid phone number once [toInternational] has
  /// completed it with [defaultCountryCode].
  static bool isValid(String typed, {required String defaultCountryCode}) =>
      isValidInternational(
        toInternational(typed, defaultCountryCode: defaultCountryCode),
      );
}
