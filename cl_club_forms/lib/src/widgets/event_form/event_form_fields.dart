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

/// Who an event is for, by gender: anyone, boys or girls. The form's Gender
/// always holds one of these; [any] is no gender criterion. The caller's
/// adapter maps them to and from the SDK `Gender`.
enum EventGender {
  /// No gender criterion.
  any,

  /// Only boys.
  boys,

  /// Only girls.
  girls;

  /// The entry's text in the Gender field.
  String get label => switch (this) {
    EventGender.any => 'Any',
    EventGender.boys => 'Boys',
    EventGender.girls => 'Girls',
  };

  /// Whether this limits who is eligible; false for [any].
  bool get isCriterion => this != EventGender.any;

  /// The gender [values] hold under [EventFormFields.genderId]; [any] when
  /// they hold none.
  static EventGender of(Map<String, dynamic> values) =>
      values[EventFormFields.genderId] as EventGender? ?? EventGender.any;
}
