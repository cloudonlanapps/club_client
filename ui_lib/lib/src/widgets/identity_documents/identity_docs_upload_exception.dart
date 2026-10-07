/// Thrown by an upload callback to surface a specific, user-presentable
/// reason an upload failed (e.g. the server has no encryption key
/// configured). The uploader shows [message] verbatim instead of its generic
/// "couldn't upload" fallback.
///
/// SDK-free on purpose: the host (which knows about `ServerException` codes)
/// maps server errors to a friendly [message] and throws this; the uploader
/// stays free of SDK concepts.
class IdentityDocsUploadException implements Exception {
  const IdentityDocsUploadException(this.message);

  /// A complete, user-facing sentence to display under the upload cards.
  final String message;

  @override
  String toString() => 'IdentityDocsUploadException: $message';
}
