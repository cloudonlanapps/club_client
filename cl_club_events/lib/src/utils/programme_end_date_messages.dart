import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

import 'schedule_save_error.dart';

/// Shown when a programme that had no end date is given one.
const String programmeEndDateSetMessage = 'End date set.';

/// Shown when a programme's end date is moved.
const String programmeEndDateChangedMessage = 'End date changed.';

/// Shown when a programme's end date is removed.
const String programmeEndDateClearedMessage = 'End date cleared.';

/// Shown when the server refuses an end-date change because the end was
/// set, cleared or passed in the meantime.
const String programmeEndDateOutdatedMessage =
    "This programme's end date has changed or has passed. Close this and "
    'check its schedule.';

/// Shown when an end-date change fails with no more specific explanation.
const String programmeEndDateFailedMessage =
    'Could not change the end date. Please try again.';

/// Whether the refusal [error] of an end-date change is about the day
/// chosen: too far ahead, or a last session too close to now.
bool programmeEndDateIsAboutLastDay(Object error) =>
    error is ServerException &&
    (error.code == SdkErrorCode.beyondSchedulingHorizon ||
        error.code == SdkErrorCode.cutoffTooSoon);

/// What to tell the admin when an end-date change fails with [error].
String programmeEndDateFailureOf(Object error) {
  if (error is ServerException && error.code == SdkErrorCode.invalidState) {
    return programmeEndDateOutdatedMessage;
  }
  return scheduleSaveErrorMessage(
    error,
    fallback: programmeEndDateFailedMessage,
  );
}
