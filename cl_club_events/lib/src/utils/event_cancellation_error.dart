import 'package:cl_club_forms/cl_club_forms.dart'
    show EventCancellationFormFields;
import 'package:club_sdk_2/club_sdk_2.dart'
    show SdkErrorCode, ServerException, StaleVersionException;

import '../models/event_cancellation_messages.dart';
import '../models/event_schema_fields.dart';
import 'event_refusal.dart';
import 'event_save_error.dart';

/// The message for a refused cancel, undo-cancel, call-off or reinstate
/// (club_client#40).
///
/// Each refusal of the server's `cancel`, `undo-cancel`, `drop` and
/// `reinstate` reads as a fixed message; a stale version, a missing
/// permission, a deleted event and an unreachable server are worded by
/// [eventSaveErrorMessage], which also logs the error with [stackTrace].
/// The raw error never reaches the user. [aboutSession] words the
/// refusals of one session's cancel for a session rather than an event.
String eventCancellationErrorMessage(
  Object error, {
  required String fallback,
  StackTrace? stackTrace,
  bool aboutSession = false,
}) {
  final general = eventSaveErrorMessage(
    error,
    fallback: fallback,
    stackTrace: stackTrace,
  );
  if (error is! ServerException || error is StaleVersionException) {
    return general;
  }
  return switch (error.code) {
    SdkErrorCode.cancellationLeadTimeViolated =>
      EventCancellationMessages.tooClose,
    SdkErrorCode.effectiveTimeInPast => EventCancellationMessages.sessionInPast,
    SdkErrorCode.effectiveTimeNotSessionBoundary =>
      EventCancellationMessages.notASession,
    SdkErrorCode.eventAlreadyCancelled =>
      EventCancellationMessages.alreadyCancelled,
    SdkErrorCode.eventNotCancelled => EventCancellationMessages.notCancelled,
    SdkErrorCode.pastOccurrence =>
      aboutSession
          ? EventCancellationMessages.sessionAlreadyStarted
          : EventCancellationMessages.alreadyHappened,
    SdkErrorCode.cancelledOccurrence =>
      aboutSession
          ? EventCancellationMessages.sessionAlreadyCancelled
          : EventCancellationMessages.alreadyCalledOff,
    SdkErrorCode.invalidState => EventCancellationMessages.cannotReinstate,
    SdkErrorCode.invalidEventType => EventCancellationMessages.wrongEventType,
    _ => general,
  };
}

/// Whether the refusal [error] is about the session a camp's cancellation
/// starts from: too close, already past, or no longer a session.
bool eventCancellationIsAboutSession(Object error) =>
    error is ServerException &&
    error is! StaleVersionException &&
    (error.code == SdkErrorCode.cancellationLeadTimeViolated ||
        error.code == SdkErrorCode.effectiveTimeInPast ||
        error.code == SdkErrorCode.effectiveTimeNotSessionBoundary);

/// Where the cancellation form shows a cancel or a call-off that failed
/// with [error], worded by [message], or `null` when the failure is a
/// toast: on the session a camp ([isCamp]) is cancelled from when the
/// refusal is about it, on the field a schema rejection names, else inline.
EventFormRefusal? eventCancellationRefusal(
  Object error, {
  required bool isCamp,
  required String message,
  required String fallback,
}) => eventFormRefusal(
  error,
  message: message,
  fallback: fallback,
  schemaFieldIds: EventSchemaFields.cancellation,
  fieldId: isCamp && eventCancellationIsAboutSession(error)
      ? EventCancellationFormFields.fromSessionId
      : null,
);
