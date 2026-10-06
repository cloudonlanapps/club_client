import 'package:club_sdk_2/club_sdk_2.dart'
    show SdkErrorCode, ServerException, StaleVersionException;

import '../models/event_cancellation_messages.dart';
import 'event_save_error.dart';

/// The message for a refused cancel, undo-cancel, call-off or reinstate
/// (club_client#40).
///
/// Each refusal of the server's `cancel`, `undo-cancel`, `drop` and
/// `reinstate` reads as a fixed message; a stale version, a missing
/// permission, a deleted event and an unreachable server are worded by
/// [eventSaveErrorMessage], which also logs the error with [stackTrace].
/// The raw error never reaches the user.
String eventCancellationErrorMessage(
  Object error, {
  required String fallback,
  StackTrace? stackTrace,
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
    SdkErrorCode.pastOccurrence => EventCancellationMessages.alreadyHappened,
    SdkErrorCode.cancelledOccurrence =>
      EventCancellationMessages.alreadyCalledOff,
    SdkErrorCode.invalidState => EventCancellationMessages.cannotReinstate,
    SdkErrorCode.invalidEventType => EventCancellationMessages.wrongEventType,
    _ => general,
  };
}
