/// Why a picked file was refused before it was uploaded.
enum IdentityDocumentRejectionReason {
  /// Not one of the accepted media types.
  unsupportedMimeType,

  /// Larger than the size limit.
  fileTooLarge,
}
