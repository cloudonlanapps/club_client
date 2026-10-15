/// Form-local field IDs shared by the event section editors. The
/// Eligibility form's inputs are the shared clusters'
/// (`GenderEligibilityFormFields`, `AgeEligibilityFormFields`).
///
/// All SDK-free: the caller's adapter (`cl_club_events`
/// `camp_event_form_helpers`) maps these to/from the `club_sdk_2` `Event`
/// and `Visibility` types. Mirrors `GroupFormFields`.
class EventFormFields {
  const EventFormFields._();

  static const String titleId = 'title';
  static const String descriptionId = 'description';

  // Organizer & coaches section.
  static const String organizerNameId = 'organizerName';
  static const String coachNamesId = 'coachNames';

  /// The session a programme's new organizer and coaches take over from,
  /// its start as a `DateTime`. A camp or a one-off has no such field.
  static const String effectiveFromId = 'effectiveFrom';
}
