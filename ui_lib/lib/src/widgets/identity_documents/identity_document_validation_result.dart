import 'package:flutter/foundation.dart';

import 'identity_document_rejection_reason.dart';

/// Whether a picked file may be uploaded.
@immutable
class IdentityDocumentValidationResult {
  const IdentityDocumentValidationResult.accepted()
    : accepted = true,
      reason = null;

  const IdentityDocumentValidationResult.rejected(
    IdentityDocumentRejectionReason this.reason,
  ) : accepted = false;

  /// Whether the file may be uploaded.
  final bool accepted;

  /// Why it may not; null when [accepted].
  final IdentityDocumentRejectionReason? reason;

  /// What to tell the member; null when [accepted].
  String? get message {
    switch (reason) {
      case IdentityDocumentRejectionReason.unsupportedMimeType:
        return "We can't open that file. Please pick a photo "
            '(JPG, PNG, or WEBP).';
      case IdentityDocumentRejectionReason.fileTooLarge:
        return 'That file is too big. Please pick one under 5 MB.';
      case null:
        return null;
    }
  }
}
