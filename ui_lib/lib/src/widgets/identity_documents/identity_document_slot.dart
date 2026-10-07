import 'package:flutter/foundation.dart';

/// One identity-document item — either an orphan (uploaded, not yet linked
/// to the user gallery) or a linked gallery item. The uploader treats both
/// the same; the host distinguishes via [id] inside its discard callback.
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
  /// the uploader. Passed back to the discard callback so the host can
  /// locate the row in `/uploaded` and `/gallery` as needed.
  final String id;

  /// Server URI used for preview rendering. Set as soon as the host's
  /// upload completes.
  final String uri;

  /// The file's media type.
  final String mimeType;

  /// The file's size.
  final int sizeBytes;

  /// The file's name, when known.
  final String? fileName;

  @override
  bool operator ==(Object other) =>
      other is IdentityDocumentSlot && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
