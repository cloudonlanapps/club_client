import 'package:cl_club_forms/cl_club_forms.dart' show EventStaffMember;
import 'package:ui_lib/ui_lib.dart' show PickerUser;

/// A picked user → `EventStaffForm`'s form-local [EventStaffMember].
EventStaffMember eventStaffMemberOf(PickerUser user) =>
    EventStaffMember(username: user.username, displayName: user.displayName);
