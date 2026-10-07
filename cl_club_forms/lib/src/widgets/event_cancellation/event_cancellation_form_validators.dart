import 'event_cancellation_form_fields.dart';

/// Static, SDK-free validators for `EventCancellationForm`.
class EventCancellationFormValidators {
  const EventCancellationFormValidators._();

  /// Shown when no reason is typed.
  static const String reasonRequired = 'A reason is required';

  /// Shown when the reason is longer than the server accepts.
  static const String reasonTooLong =
      'Keep the reason within '
      '${EventCancellationFormFields.reasonMaxLength} characters';

  /// Shown when no session is picked.
  static const String fromSessionRequired = 'Choose a session';

  /// The reason: required, at most
  /// [EventCancellationFormFields.reasonMaxLength] characters.
  static String? reason(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return reasonRequired;
    if (trimmed.length > EventCancellationFormFields.reasonMaxLength) {
      return reasonTooLong;
    }
    return null;
  }

  /// The session to cancel from: required.
  static String? fromSession(DateTime? value) =>
      value == null ? fromSessionRequired : null;
}
