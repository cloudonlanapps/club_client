/// Field-id constants of the `ShadForm` inside `EventMarketingDetailsForm`,
/// and the values of its open-slots choice.
class EventMarketingDetailsFormFields {
  const EventMarketingDetailsFormFields._();

  /// How long the event runs, said in words.
  static const String durationTextId = 'durationText';

  /// When it meets, said in words.
  static const String scheduleTextId = 'scheduleText';

  /// Who may join, said in words.
  static const String eligibilityTextId = 'eligibilityText';

  /// A note under the eligibility.
  static const String eligibilityNoteId = 'eligibilityNote';

  /// The last day to register (`DateTime?`, the day picked).
  static const String registrationDeadlineId = 'registrationDeadline';

  /// Whether places are open: one of the open-slots values.
  static const String openSlotsId = 'openSlots';

  /// A line pressing visitors to register (`Only 3 places left`).
  static const String urgencyTextId = 'urgencyText';

  /// The number to call about the event.
  static const String contactNumberId = 'contactNumber';

  /// Open slots not said either way.
  static const String openSlotsUnset = '';

  /// Places are open.
  static const String openSlotsOpen = 'open';

  /// The event is full.
  static const String openSlotsFull = 'full';
}
