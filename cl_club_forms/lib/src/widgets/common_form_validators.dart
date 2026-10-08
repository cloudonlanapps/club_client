import 'form_phone_number.dart';

/// Shared, SDK-free field validators reused across the forms, so a common
/// concept — a name, an email address, a phone number — validates
/// identically everywhere instead of each form re-implementing the rule.
///
/// Each validator returns `null` when valid, else the message to show under
/// the field.
class CommonFormValidators {
  const CommonFormValidators._();

  /// An email address: one `@`, no spaces, and a dot in the domain.
  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// A phone number written in international format: a `+`, a non-zero
  /// first digit, at most 15 digits in all, no spaces or punctuation.
  static final RegExp internationalPhonePattern = RegExp(r'^\+[1-9]\d{1,14}$');

  /// Shown when a required email is missing.
  static const String emailRequired = 'Email is required';

  /// Shown when what is typed is not an email address.
  static const String emailInvalid = 'Enter a valid email';

  /// Shown when a required phone number is missing.
  static const String phoneRequired = 'Phone number is required';

  /// Shown when what is typed is not a phone number of its country.
  static const String phoneInvalid = 'Enter a valid phone number';

  /// Shown when a number that must be typed in international format is
  /// not.
  static const String internationalPhoneFormat =
      'Use the international format: + and the country code, '
      'digits only (e.g. +919876543210)';

  /// An entity display name: required and at least 2 characters. [label]
  /// prefixes the "required" message so each entity reads naturally
  /// (`'Group name'`, `'Venue name'`, `'Event name'`, …) while the rule stays
  /// identical.
  static String? name(String value, {required String label}) {
    final t = value.trim();
    if (t.isEmpty) return '$label is required';
    if (t.length < 2) return 'At least 2 characters';
    return null;
  }

  /// Whether [value], trimmed, reads as an email address
  /// ([emailPattern]).
  static bool isEmail(String value) => emailPattern.hasMatch(value.trim());

  /// A required email address.
  static String? email(String value) =>
      value.trim().isEmpty ? emailRequired : emailOptional(value);

  /// An optional email address: empty passes, anything typed must be one.
  static String? emailOptional(String value) =>
      value.trim().isEmpty || isEmail(value) ? null : emailInvalid;

  /// A required phone number. See [phoneOptional] for the rule.
  static String? phone(String value, {required String defaultCountryCode}) =>
      value.trim().isEmpty
      ? phoneRequired
      : phoneOptional(value, defaultCountryCode: defaultCountryCode);

  /// An optional phone number: empty passes, anything typed must be a valid
  /// number of its country.
  ///
  /// The number is first put in international format the way the hosts'
  /// adapters store it (`FormPhoneNumber.toInternational`): typed without a
  /// country code it takes [defaultCountryCode], the club's (digits only,
  /// as the server reports it: `91`).
  static String? phoneOptional(
    String value, {
    required String defaultCountryCode,
  }) {
    final t = value.trim();
    if (t.isEmpty) return null;
    return FormPhoneNumber.isValid(t, defaultCountryCode: defaultCountryCode)
        ? null
        : phoneInvalid;
  }

  /// An optional phone number that is stored as typed, so must be typed in
  /// international format ([internationalPhonePattern]) and be a valid
  /// number of its country.
  static String? internationalPhone(String value) {
    final t = value.trim();
    if (t.isEmpty) return null;
    if (!internationalPhonePattern.hasMatch(t)) return internationalPhoneFormat;
    return FormPhoneNumber.isValidInternational(t) ? null : phoneInvalid;
  }
}
