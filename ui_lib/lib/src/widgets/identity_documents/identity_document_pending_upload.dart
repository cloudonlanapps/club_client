import 'package:flutter/foundation.dart';

/// A file picked and still on its way to the server.
@immutable
class IdentityDocumentPendingUpload {
  const IdentityDocumentPendingUpload({
    required this.key,
    required this.filename,
  });

  /// Tells one upload in flight from another.
  final String key;

  /// The picked file's name.
  final String filename;
}
