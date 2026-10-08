import '../../models/event_staff_member.dart';
import '../event_schedule/programme_schedule_adjust_form_validators.dart';

/// Static, SDK-free validators for `EventStaffForm`.
class EventStaffFormValidators {
  const EventStaffFormValidators._();

  /// Shown when the event has no organizer.
  static const String organizerRequired = 'An organizer is required';

  /// The organizer: required.
  static String? organizer(EventStaffMember? value) =>
      value == null ? organizerRequired : null;

  /// Shown when a programme has no upcoming session a change could start
  /// from.
  static const String noUpcomingSession =
      'This programme has no upcoming session to change its organizer and '
      'coaches from.';

  /// The session a programme's change takes effect from: one of [options],
  /// the upcoming session starts of its present schedule.
  static String? from(DateTime? value, List<DateTime> options) =>
      options.isEmpty
      ? noUpcomingSession
      : ProgrammeScheduleAdjustFormValidators.from(value, options);
}
