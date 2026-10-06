import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;
import 'package:ui_lib/ui_lib.dart'
    show EventTimetableFormValidators, OneOffScheduleFormValidators;

import 'event_save_error.dart';

/// The message for a refused change to an event's schedule, made from its
/// Schedule block: the server's schedule guards each say what to do, and
/// anything else reads as [eventSaveErrorMessage] gives it (a stale version,
/// a clash, an unreachable server, else [fallback]). The raw error is never
/// shown.
String scheduleSaveErrorMessage(Object error, {required String fallback}) {
  if (error is ServerException) {
    final message = switch (error.code) {
      SdkErrorCode.eventAlreadyStarted =>
        'This event has started, so its schedule can no longer be moved.',
      SdkErrorCode.rescheduleLeadTimeViolated =>
        'An event can be moved only up to 30 minutes before it starts.',
      SdkErrorCode.postponeOnly =>
        OneOffScheduleFormValidators.postponeOnlyMessage,
      SdkErrorCode.beyondSchedulingHorizon =>
        'That is further ahead than events can be scheduled. Pick an '
            'earlier date.',
      SdkErrorCode.invalidSessionsTotal =>
        EventTimetableFormValidators.totalMismatchMessage,
      // A one-off's only override is its being called off.
      SdkErrorCode.occurrenceOverridesPresent =>
        'This event is called off. Put it back on before moving it.',
      SdkErrorCode.venueNotFound =>
        'That venue no longer exists. Pick another.',
      _ => null,
    };
    if (message != null) return message;
  }
  return eventSaveErrorMessage(error, fallback: fallback);
}
