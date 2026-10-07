/// Text of the identity-document uploader.
abstract final class IdentityDocumentsStrings {
  /// Label of the add card once a first image is there.
  static const String addBackSide = 'Add back side';

  /// Explains the second card while it is still offered.
  static const String backSideHint =
      'Only add a second image if your Aadhaar front and back '
      'are separate photos.';

  /// Shown when an upload fails for a reason the host did not name.
  static const String uploadFailed =
      "Couldn't upload that file. Please try again.";

  /// Shown when removing a file fails.
  static const String removeFailed =
      "Couldn't remove that file. Please try again.";

  /// Stands in for a file with no name.
  static const String unnamedImage = 'Image';
}
