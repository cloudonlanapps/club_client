/// Text of the submit-documents step.
abstract final class IdentityDocumentsSubmitStrings {
  /// What the step asks for, above the upload cards.
  static const String intro =
      'We need a clear photo of your Aadhaar card to confirm '
      'your name and date of birth.';

  /// The button that sends the application to review.
  static const String submit = 'Submit';

  /// The same button while the application is being sent.
  static const String submitting = 'Submitting…';

  /// The button that leaves the step for another time.
  static const String doLater = "I'll do it later";

  /// Why Submit is disabled with no document uploaded.
  static const String needsDocument = 'Add at least one document to continue.';

  /// Heading of the collapsed help section.
  static const String tipsTitle = 'Tips for a clean upload';

  /// The help section's points.
  static const List<String> tips = [
    'Regular or masked Aadhaar are both accepted.',
    'Name and date of birth must be readable.',
    'File size must be under 2 MB.',
    'If taking a fresh photo, use good light and hold the camera steady.',
  ];
}
