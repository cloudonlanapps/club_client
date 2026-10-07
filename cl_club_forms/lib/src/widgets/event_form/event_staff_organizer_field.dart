import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_staff_member.dart';
import '../../models/event_staff_pickers.dart';
import 'event_staff_organizer_row.dart';

/// `ShadForm` field for an event's organizer: its value is the member
/// picked, null while there is none. **Transfer** asks [PickOrganizer] for
/// another and takes the answer as the value; a cancelled pick changes
/// nothing.
class EventStaffOrganizerField extends ShadFormBuilderField<EventStaffMember> {
  EventStaffOrganizerField({
    required PickOrganizer onPick,
    super.id,
    super.initialValue,
    super.validator,
    super.enabled,
    super.key,
  }) : super(
         builder: (state) => EventStaffOrganizerRow(
           organizer: state.value,
           enabled: state.widget.enabled,
           onTransfer: () async {
             final picked = await onPick();
             if (picked != null && state.mounted) state.didChange(picked);
           },
         ),
       );
}
