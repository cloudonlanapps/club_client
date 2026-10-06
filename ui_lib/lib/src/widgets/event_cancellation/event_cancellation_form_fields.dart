/// Field-id constants and limits of the `ShadForm` inside
/// `EventCancellationForm`.
class EventCancellationFormFields {
  EventCancellationFormFields._();

  /// The session the cancellation starts from: the start (`DateTime`) of
  /// one of the form's `EventCancellationSession`s.
  static const String fromSessionId = 'fromSession';

  /// The reason given to the enrolled members.
  static const String reasonId = 'reason';

  /// Longest reason the server accepts.
  static const int reasonMaxLength = 500;
}
