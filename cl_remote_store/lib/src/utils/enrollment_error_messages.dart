import 'package:club_sdk_2/club_sdk_2.dart'
    show SdkErrorCode, ServerException, mapEnrollmentMutationError;

/// The message for a refused approval of a join request (club_core#128):
/// a clash with the member's other events is named plainly; anything else
/// reads as the shared enrollment mapping.
String enrollmentApproveErrorMessage(ServerException e) =>
    e.code == SdkErrorCode.timeConflict
    ? 'This member is already enrolled in an event at the same time.'
    : mapEnrollmentMutationError(e);

/// The message for a refused removal (club_core#130): the server answers
/// `INVALID_STATE` for a member who already left, which the shared mapping
/// would call "no longer open for enrollment".
String enrollmentRemoveErrorMessage(ServerException e) =>
    e.code == SdkErrorCode.invalidState
    ? 'This member has already left the event.'
    : mapEnrollmentMutationError(e);
