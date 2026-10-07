import 'package:flutter/foundation.dart';

import '../../constants/identity_documents.dart';

/// What the identity-document uploader accepts.
@immutable
class IdentityDocumentsUploadConfig {
  const IdentityDocumentsUploadConfig({
    this.maxCount = kIdentityDocumentMaxCount,
    this.allowedMimeTypes = kIdentityDocumentAllowedMediaTypes,
    this.maxBytes = kIdentityDocumentMaxBytes,
  });

  /// The default limits.
  static const IdentityDocumentsUploadConfig defaults =
      IdentityDocumentsUploadConfig();

  /// How many files a member may upload.
  final int maxCount;

  /// The media types accepted.
  final Set<String> allowedMimeTypes;

  /// The largest file accepted.
  final int maxBytes;
}
