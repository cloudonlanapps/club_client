/// Text of the privacy policy of the submit-documents step.
abstract final class IdentityDocumentsPrivacyPolicyStrings {
  /// The policy's heading.
  static const String title = 'How we handle your Aadhaar';

  /// What the documents are used for.
  static const String purpose =
      'We only use your Aadhaar to confirm your name and date of '
      'birth. Nothing else.';

  /// What they are never used for.
  static const String neverUsedFor =
      'We will never use it for marketing, ads, profiling, or '
      'any unrelated purpose.';

  /// Who sees them, and how they are kept.
  static const String access =
      'Only authorised reviewers can see your files. They are '
      'securely transmitted and stored.';

  /// The policy's paragraphs, in order.
  static const List<String> paragraphs = [purpose, neverUsedFor, access];

  /// The button that closes the policy.
  static const String close = 'Close';
}
