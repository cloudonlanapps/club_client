import 'package:cl_club_forms/cl_club_forms.dart' show EventCreateFormFields;
import 'package:cl_remote_store/cl_remote_store.dart' show schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

import '../models/event_schema_fields.dart';
import 'event_save_error.dart';
import 'schedule_save_error.dart';

/// Where the create form shows a refused create: on the fields the refusal
/// is about, or as its inline form-level message.
typedef EventCreateRefusal = ({
  Map<String, String> fieldErrors,
  String? formError,
});

/// How a create the server refused reads in the create form, or `null`
/// when the refusal is about nothing the form holds (the view then says so
/// in a toast worded with [fallback]).
///
/// A venue that no longer exists shows on the venue; a schedule too far
/// ahead, or sessions that do not add up, on the schedule; a clash with
/// another booking inline. The messages are fixed: the raw error is never
/// shown. A value the server's schema rejects shows on its field, with the
/// server's reason (club_client#114).
EventCreateRefusal? eventCreateRefusal(
  Object error, {
  required String fallback,
}) {
  if (error is! ServerException) return null;
  switch (error.code) {
    case SdkErrorCode.venueNotFound:
      return (
        fieldErrors: {
          EventCreateFormFields.venueId: scheduleSaveErrorMessage(
            error,
            fallback: fallback,
          ),
        },
        formError: null,
      );
    case SdkErrorCode.beyondSchedulingHorizon:
    case SdkErrorCode.invalidSessionsTotal:
      return (
        fieldErrors: {
          EventCreateFormFields.scheduleId: scheduleSaveErrorMessage(
            error,
            fallback: fallback,
          ),
        },
        formError: null,
      );
    case SdkErrorCode.conflict:
    case SdkErrorCode.timeConflict:
    case SdkErrorCode.scheduleConflict:
      return (
        fieldErrors: const {},
        formError: eventSaveErrorMessage(error, fallback: fallback),
      );
    default:
      // What the schema rejects shows on the field it names.
      final fieldErrors = schemaFieldErrors(error, EventSchemaFields.create);
      return fieldErrors.isEmpty
          ? null
          : (fieldErrors: fieldErrors, formError: null);
  }
}
