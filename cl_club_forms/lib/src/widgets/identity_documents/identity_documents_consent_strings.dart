/// Text of the identity-documents consent form.
abstract final class IdentityDocumentsConsentStrings {
  /// The consent line, before the link.
  static const String lead = 'I agree to the ';

  /// The link in the consent line.
  static const String link = 'Privacy Policy';

  /// The consent line, after the link.
  static const String tail = '.';

  /// Shown on the checkbox when the form is validated without it.
  static const String required =
      'Please agree to the Privacy Policy to continue.';
}
