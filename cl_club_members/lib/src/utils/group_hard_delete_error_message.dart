import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

/// The message for a refused permanent delete of a group: a live group must
/// be soft-deleted first (`HARD_DELETE_NEEDS_SOFT_DELETE`, club_server#526);
/// anything else gets a fixed line, never the raw error.
String groupHardDeleteErrorMessage(ServerException e) =>
    e.code == SdkErrorCode.hardDeleteNeedsSoftDelete
    ? 'Soft-delete this group first, then permanently delete it.'
    : 'Could not delete group.';
