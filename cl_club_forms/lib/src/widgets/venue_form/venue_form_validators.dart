import '../common_form_validators.dart';

/// Static, SDK-free validators for the venue form fields.
class VenueFormValidators {
  const VenueFormValidators._();

  /// Venue name: required, at least 2 characters (shared entity-name rule).
  static String? name(String value) =>
      CommonFormValidators.name(value, label: 'Venue name');
}
