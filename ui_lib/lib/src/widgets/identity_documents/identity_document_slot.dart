import 'package:flutter/foundation.dart';

import '../../constants/identity_documents.dart';

/// One identity-document item — either an orphan (uploaded, not yet linked
/// to the user gallery) or a linked gallery item. The form treats both the
/// same; the host distinguishes via [id] inside its onDiscard callback.
@immutable
class IdentityDocumentSlot {
  const IdentityDocumentSlot({
    required this.id,
    required this.uri,
    required this.mimeType,
    required this.sizeBytes,
    this.fileName,
  });

  /// Server-side identifier (typically the uploaded media uuid). Opaque to
  /// the form. Passed back to `onDiscard` so the host can locate the row in
  /// `/uploaded` and `/gallery` as needed.
  final String id;

  /// Server URI used for preview rendering. Set as soon as the host's
  /// onUpload completes.
  final String uri;

  final String mimeType;
  final int sizeBytes;
  final String? fileName;

  @override
  bool operator ==(Object other) =>
      other is IdentityDocumentSlot && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Static configuration for an identity-documents form.
@immutable
class IdentityDocumentsFormConfig {
  const IdentityDocumentsFormConfig({
    this.maxCount = kIdentityDocumentMaxCount,
    this.allowedMimeTypes = kIdentityDocumentAllowedMediaTypes,
    this.maxBytes = kIdentityDocumentMaxBytes,
  });

  final int maxCount;
  final Set<String> allowedMimeTypes;
  final int maxBytes;

  static const IdentityDocumentsFormConfig defaults =
      IdentityDocumentsFormConfig();
}

/// Reason a pre-pick validation rejected a file.
enum IdentityDocumentRejectionReason {
  unsupportedMimeType,
  fileTooLarge,
}

/// Outcome of a pre-pick validation.
@immutable
class IdentityDocumentValidationResult {
  const IdentityDocumentValidationResult.accepted()
    : accepted = true,
      reason = null;

  const IdentityDocumentValidationResult.rejected(
    IdentityDocumentRejectionReason this.reason,
  ) : accepted = false;

  final bool accepted;
  final IdentityDocumentRejectionReason? reason;

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

/// Pre-pick validation helpers for identity-document uploads.
abstract class IdentityDocumentsFormValidators {
  static IdentityDocumentValidationResult acceptFile({
    required String mimeType,
    required int sizeBytes,
    IdentityDocumentsFormConfig config = IdentityDocumentsFormConfig.defaults,
  }) {
    if (!config.allowedMimeTypes.contains(mimeType)) {
      return const IdentityDocumentValidationResult.rejected(
        IdentityDocumentRejectionReason.unsupportedMimeType,
      );
    }
    if (sizeBytes > config.maxBytes) {
      return const IdentityDocumentValidationResult.rejected(
        IdentityDocumentRejectionReason.fileTooLarge,
      );
    }
    return const IdentityDocumentValidationResult.accepted();
  }
}
