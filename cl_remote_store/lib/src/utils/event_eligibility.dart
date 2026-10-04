import 'package:club_sdk_2/club_sdk_2.dart';

/// Why a [UserPrivate] is ineligible for an [Event].
///
/// `genderMissing` / `dobMissing` indicate the event constrains that
/// axis but the user has not filled in the matching profile field —
/// the caller should ask the user (or the admin) to update the profile
/// first.
///
/// `genderMismatch` / `dobOutOfWindow` indicate the user has the data
/// filled in, but it falls outside the event's criteria — the user
/// genuinely does not qualify.
enum EligibilityFailureReason {
  genderMissing,
  genderMismatch,
  dobMissing,
  dobOutOfWindow,
}

class EligibilityFailure {
  const EligibilityFailure(this.reason, this.message);

  final EligibilityFailureReason reason;
  final String message;

  @override
  String toString() => 'EligibilityFailure($reason, $message)';
}

/// Pure-function eligibility check.
///
/// Returns `null` when [user] satisfies the structured criteria on
/// [event] (gender and the date-of-birth window). Returns the first
/// failure otherwise — the caller can either present the reason to the
/// user or block the network call entirely.
///
/// The check mirrors the server's `check_event_eligibility` so the
/// client can avoid a round-trip whenever the profile data is locally
/// known to disqualify the user.
EligibilityFailure? checkEventEligibility({
  required Event event,
  required UserPrivate user,
}) {
  if (event.gender != null) {
    if (user.gender == null) {
      return const EligibilityFailure(
        EligibilityFailureReason.genderMissing,
        'This event is restricted by gender. Update the user profile '
        'before enrolling.',
      );
    }
    if (user.gender != event.gender) {
      return EligibilityFailure(
        EligibilityFailureReason.genderMismatch,
        'This event is restricted to ${event.gender!.label} members.',
      );
    }
  }

  final dobLowerBound = event.dobOnOrAfterUtc;
  final dobUpperBound = event.dobOnOrBeforeUtc;
  if (dobLowerBound != null || dobUpperBound != null) {
    final dob = user.dateOfBirthUtc;
    if (dob == null) {
      return const EligibilityFailure(
        EligibilityFailureReason.dobMissing,
        'This event has an age requirement. Add the date of birth to '
        'the user profile before enrolling.',
      );
    }
    if (dobLowerBound != null && dob.isBefore(dobLowerBound)) {
      return const EligibilityFailure(
        EligibilityFailureReason.dobOutOfWindow,
        'This user is older than the event allows.',
      );
    }
    if (dobUpperBound != null && dob.isAfter(dobUpperBound)) {
      return const EligibilityFailure(
        EligibilityFailureReason.dobOutOfWindow,
        'This user is younger than the event allows.',
      );
    }
  }

  return null;
}
