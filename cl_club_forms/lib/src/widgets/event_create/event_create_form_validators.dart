/// Pure validators for `EventCreateForm`. Reused by the form's fields and by
/// its cross-field `handleSubmit` gate; SDK-free so tests can call them
/// directly.
class EventCreateFormValidators {
  EventCreateFormValidators._();

  /// Title is required (non-blank).
  static String? title(String value) =>
      value.trim().isEmpty ? 'Title is required' : null;

  /// A venue must be selected before the event can be created.
  static String? venue(int? value) =>
      value == null ? 'Please select a venue' : null;
}
