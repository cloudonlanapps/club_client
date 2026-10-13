import 'package:cl_remote_store/cl_remote_store.dart' show schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ServerException, StaleVersionException;

/// Where a form shows a save the server refused: on the fields the refusal
/// is about, or as its inline form-level message.
typedef EventFormRefusal = ({
  Map<String, String> fieldErrors,
  String? formError,
});

/// The status the server answers with when it is the one failing.
const int serverFailureStatus = 500;

/// The statuses of a session that ended and of a missing permission.
const Set<int> notAllowedStatuses = {401, 403};

/// Whether a save that failed with [error] is shown in the form — the
/// server refusing what was sent, worded by [message] — rather than in a
/// toast.
///
/// A toast is for a failure that is not about what was typed: the server
/// not reached or failing, a session or a permission that is gone, an event
/// someone else changed, and anything the host has no words for ([message]
/// is then its [fallback]).
bool isRefusalToShowInForm(
  Object error, {
  required String message,
  required String fallback,
}) =>
    error is ServerException &&
    error is! StaleVersionException &&
    error.statusCode < serverFailureStatus &&
    !notAllowedStatuses.contains(error.statusCode) &&
    message != fallback;

/// Where a form shows a save that failed with [error], or `null` when the
/// failure is a toast (worded by [message]).
///
/// A value the server's schema rejects shows on the field of
/// [schemaFieldIds] it names, with the server's reason (club_client#114).
/// Any other refusal to show in the form ([isRefusalToShowInForm]) shows
/// [message] on [fieldId], or inline when [fieldId] is `null`.
EventFormRefusal? eventFormRefusal(
  Object error, {
  required String message,
  required String fallback,
  required Map<String, String> schemaFieldIds,
  String? fieldId,
}) {
  final schemaErrors = schemaFieldErrors(error, schemaFieldIds);
  if (schemaErrors.isNotEmpty) {
    return (fieldErrors: schemaErrors, formError: null);
  }
  if (!isRefusalToShowInForm(error, message: message, fallback: fallback)) {
    return null;
  }
  return fieldId == null
      ? (fieldErrors: const {}, formError: message)
      : (fieldErrors: {fieldId: message}, formError: null);
}
