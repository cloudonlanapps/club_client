import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

import 'identity_documents_submit_strings.dart';

/// SDK → form adapter for the submit-documents step (its consent form,
/// `IdentityDocumentsConsentForm`, lives SDK-free in `cl_club_forms`).
abstract final class IdentityDocumentsFormSubmit {
  /// What the step shows inline for a submission that failed with [error]:
  /// the server refusing it because no identity document is attached. That
  /// names no field. Null when the failure is not about what the step
  /// holds; the host then reports a failed submission.
  static String? formErrorFor(Object error) =>
      error is ServerException &&
          error.code == SdkErrorCode.identityDocumentRequired
      ? IdentityDocumentsSubmitStrings.needsDocument
      : null;
}
