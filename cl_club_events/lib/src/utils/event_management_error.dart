import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

import '../models/event_management_messages.dart';
import 'event_save_error.dart';

/// The server's code for a restore refused because the event's venue is
/// deleted (club_server `routers/events.py`, `restore_event`).
const String venueIsDeletedCode = 'VENUE_IS_DELETED';

/// The toast for a refused Event Management action (club_client#36).
///
/// The refusals of archive, unarchive and delete read as fixed messages;
/// anything else is worded by [eventSaveErrorMessage], which also logs the
/// error with [stackTrace]. The raw error never reaches the toast.
String eventManagementErrorMessage(
  Object error, {
  required String fallback,
  StackTrace? stackTrace,
}) {
  final general = eventSaveErrorMessage(
    error,
    fallback: fallback,
    stackTrace: stackTrace,
  );
  if (error is! ServerException) return general;
  return switch (error.code) {
    venueIsDeletedCode => EventManagementMessages.venueIsDeleted,
    SdkErrorCode.hardDeleteNeedsSoftDelete =>
      EventManagementMessages.deleteNeedsArchive,
    SdkErrorCode.nothingToRestore => EventManagementMessages.notArchived,
    _ => general,
  };
}
