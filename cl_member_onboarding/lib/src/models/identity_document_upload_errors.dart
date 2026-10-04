import 'package:club_sdk_2/club_sdk_2.dart';

/// Maps server-side upload failures to user-facing messages for the
/// identity-document submission flow (#754).
///
/// Identity uploads request server-side encryption (`encrypt: true`), which can
/// fail in ways the user should hear about plainly rather than as a generic
/// "try again": the deployment may have no encryption key configured, or the
/// file may exceed the server cap. Pure and SDK-typed so it is unit-testable
/// without a server; the widget layer wraps the result in an SDK-free
/// `IdentityDocsUploadException` for the form to display.
abstract final class IdentityDocumentUploadErrors {
  /// A complete, user-facing sentence for [e], or `null` when [e] is not one of
  /// the known upload-specific cases — callers then fall back to the form's
  /// generic "couldn't upload" message (or rethrow).
  static String? friendlyMessage(ServerException e) => switch (e.code) {
    'ENCRYPTION_NOT_CONFIGURED' =>
      'Secure upload is temporarily unavailable. Please try again later.',
    'ENCRYPTED_FILE_TOO_LARGE' || 'FILE_TOO_LARGE' =>
      'That file is too large. Please choose a smaller image.',
    _ => null,
  };
}
