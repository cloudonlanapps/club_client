import '../common_form_validators.dart';

/// Validators shared by the club identity section forms (`ClubDetailsForm`,
/// `ClubContactForm`, `ClubLanguageForm`; club_core#20).
///
/// Every field of the club's identity is optional — an empty value is left
/// out of the document and the reader falls back — so each validator passes
/// an empty value and checks the shape of anything given. Each returns
/// `null` when valid, else the message to show under the field.
class ClubIdentityFormValidators {
  const ClubIdentityFormValidators._();

  /// A bare ISO 639 language code: two or three lowercase letters, as a
  /// locale's `languageCode` reads.
  static final RegExp languageCodePattern = RegExp(r'^[a-z]{2,3}$');

  /// The URL schemes a public link may use.
  static const Set<String> urlSchemes = {'http', 'https'};

  /// Shown when what is typed is not an email address.
  static const String emailInvalid = 'Enter a valid email address';

  /// A phone number in international (E.164) format, e.g. `+919876543210`,
  /// valid for its country (`CommonFormValidators.internationalPhone`).
  static String? phone(String value) =>
      CommonFormValidators.internationalPhone(value);

  /// An email address (`CommonFormValidators.isEmail`).
  static String? email(String value) =>
      value.trim().isEmpty || CommonFormValidators.isEmail(value)
      ? null
      : emailInvalid;

  /// A full `http(s)` link with a host, with or without a fragment.
  static String? url(String value) {
    final t = value.trim();
    if (t.isEmpty) return null;
    final uri = Uri.tryParse(t);
    if (uri == null || !urlSchemes.contains(uri.scheme) || uri.host.isEmpty) {
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
