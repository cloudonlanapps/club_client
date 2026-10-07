import '../../models/event_staff_member.dart';

/// Static, SDK-free validators for `EventStaffForm`.
class EventStaffFormValidators {
  const EventStaffFormValidators._();

  /// Shown when the event has no organizer.
  static const String organizerRequired = 'An organizer is required';

  /// The organizer: required.
  static String? organizer(EventStaffMember? value) =>
      value == null ? organizerRequired : null;
}
