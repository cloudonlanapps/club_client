/// Validators shared by the club identity section forms (`ClubDetailsForm`,
/// `ClubContactForm`, `ClubLanguageForm`; club_core#20).
///
/// Every field of the club's identity is optional — an empty value is left
/// out of the document and the reader falls back — so each validator passes
/// an empty value and checks the shape of anything given. Each returns
/// `null` when valid, else the message to show under the field.
class ClubIdentityFormValidators {
  const ClubIdentityFormValidators._();

  /// E.164: a `+`, a non-zero country digit, at most 15 digits in all, no
  /// spaces or punctuation.
  static final RegExp e164Pattern = RegExp(r'^\+[1-9]\d{1,14}$');

  /// One `@`, no spaces, and a dot in the domain.
  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// A bare ISO 639 language code: two or three lowercase letters, as a
  /// locale's `languageCode` reads.
  static final RegExp languageCodePattern = RegExp(r'^[a-z]{2,3}$');

  /// The URL schemes a public link may use.
  static const Set<String> urlSchemes = {'http', 'https'};

  /// A phone number in international (E.164) format, e.g. `+919876543210`.
  static String? phone(String value) {
    final t = value.trim();
    if (t.isEmpty) return null;
    if (!e164Pattern.hasMatch(t)) {
      return 'Use the international format: + and the country code, '
          'digits only (e.g. +919876543210)';
    }
    return null;
  }

  /// An email address.
  static String? email(String value) {
    final t = value.trim();
    if (t.isEmpty) return null;
    if (!emailPattern.hasMatch(t)) return 'Enter a valid email address';
    return null;
  }

  /// An absolute `http(s)` link with a host.
  static String? url(String value) {
    final t = value.trim();
    if (t.isEmpty) return null;
    final uri = Uri.tryParse(t);
    if (uri == null ||
        !uri.isAbsolute ||
        !urlSchemes.contains(uri.scheme) ||
        uri.host.isEmpty) {
      return 'Enter the full link, starting with https://';
    }
    return null;
  }

  /// A language code to add translations for.
  static String? languageCode(String value) {
    final t = value.trim();
    if (!languageCodePattern.hasMatch(t)) {
      return 'Use a two- or three-letter language code in lowercase, '
          'e.g. mr or hi';
    }
    return null;
  }

  /// A language code to add to [listed]: a [languageCode] that is not
  /// already there.
  static String? newLanguageCode(String value, List<String> listed) {
    final t = value.trim();
    return languageCode(t) ??
        (listed.contains(t) ? '$t is already offered' : null);
  }
}
