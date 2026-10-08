import 'package:cl_club_forms/cl_club_forms.dart'
    show EventFormFields, EventStaffMember;
import 'package:ui_lib/ui_lib.dart' show PickerUser;

/// A picked user → `EventStaffForm`'s form-local [EventStaffMember].
EventStaffMember eventStaffMemberOf(PickerUser user) =>
    EventStaffMember(username: user.username, displayName: user.displayName);

/// Builds the `EventStaffForm.initialValues` map from an event's
/// [organizer] (none when null) and [coaches], each as the form's
/// [EventStaffMember]. A programme's also holds [from], the session its
/// change takes effect from when the form opens.
Map<String, dynamic> buildEventStaffFormInitialValues({
  PickerUser? organizer,
  List<PickerUser> coaches = const [],
  DateTime? from,
}) => {
  EventFormFields.organizerNameId: organizer == null
      ? null
      : eventStaffMemberOf(organizer),
  EventFormFields.coachNamesId: [
    for (final coach in coaches) eventStaffMemberOf(coach),
  ],
  EventFormFields.effectiveFromId: ?from,
};
