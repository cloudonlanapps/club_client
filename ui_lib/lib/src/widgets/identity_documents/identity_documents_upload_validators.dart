import 'identity_document_rejection_reason.dart';
import 'identity_document_validation_result.dart';
import 'identity_documents_upload_config.dart';

/// Checks a picked file before it is uploaded.
abstract final class IdentityDocumentsUploadValidators {
  /// Whether a file of [mimeType] and [sizeBytes] fits [config].
  static IdentityDocumentValidationResult acceptFile({
    required String mimeType,
    required int sizeBytes,
    IdentityDocumentsUploadConfig config =
        IdentityDocumentsUploadConfig.defaults,
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
