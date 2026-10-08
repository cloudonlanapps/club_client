import 'identity_documents_consent_strings.dart';

/// Pure validators for `IdentityDocumentsConsentForm`.
class IdentityDocumentsConsentFormValidators {
  const IdentityDocumentsConsentFormValidators._();

  /// The member must agree to the privacy policy. Takes the checkbox's value
  /// the way a checkbox field hands it to its validator.
  // ignore: avoid_positional_boolean_parameters
  static String? consent(bool accepted) =>
      accepted ? null : IdentityDocumentsConsentStrings.required;
}
