import '../../models/event_staff_member.dart';
import 'event_form_fields.dart';

/// Reads the usernames `EventStaffForm` returns out of its `ShadForm`
/// values, which hold the picked [EventStaffMember]s.
abstract final class EventStaffFormValues {
  /// The organizer's username in [values], or null when there is none.
  static String? organizerUsername(Map<String, dynamic> values) =>
      (values[EventFormFields.organizerNameId] as EventStaffMember?)?.username;

  /// The coaches' usernames in [values], in the order shown.
  static List<String> coachUsernames(Map<String, dynamic> values) => [
    for (final coach
        in (values[EventFormFields.coachNamesId] as List<dynamic>?) ??
            const <dynamic>[])
      (coach as EventStaffMember).username,
  ];
}
