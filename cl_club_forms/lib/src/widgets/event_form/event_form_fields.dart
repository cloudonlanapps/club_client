/// Form-local field IDs and value types shared by the event section editors
/// (`EventEligibilityForm`, `EventStaffForm`).
///
/// All SDK-free: the caller's adapter (`cl_club_events`
/// `camp_event_form_helpers`) maps these to/from the `club_sdk_2` `Event`,
/// `Gender`, and `Visibility` types. Mirrors `GroupFormFields`.
class EventFormFields {
  const EventFormFields._();

  static const String titleId = 'title';
  static const String descriptionId = 'description';

  // Eligibility section. The age band's inputs are the shared cluster's
  // (`AgeEligibilityFormFields`).
  static const String genderId = 'gender';

  // Organizer & coaches section.
  static const String organizerNameId = 'organizerName';
  static const String coachNamesId = 'coachNames';
}

/// Gender criterion for an event's eligibility. Form-local mirror of the SDK
/// `Gender`; the caller's adapter maps between them.
enum EventGender {
  male,
  female,
  other,
  preferNotToSay;

  String get label => switch (this) {
    EventGender.male => 'Male',
    EventGender.female => 'Female',
    EventGender.other => 'Other',
    EventGender.preferNotToSay => 'Prefer not to say',
  };
}
