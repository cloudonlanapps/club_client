import '../common_form_validators.dart';

/// Static, SDK-free validators for the event form fields. Mirrors
/// `VenueFormValidators` / `GroupFormValidators`.
class EventFormValidators {
  const EventFormValidators._();

  /// Event title: required, at least 2 characters (shared entity-name rule).
  static String? title(String value) =>
      CommonFormValidators.name(value, label: 'Event name');
}
