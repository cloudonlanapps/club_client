import 'package:club_sdk_2/club_sdk_2.dart' show Event, EventType;
import 'package:flutter/material.dart';

import '../../models/camp_schedule_form_helpers.dart'
    show campRescheduleLockReason, campStartedMessage, isCampTimetableOnly;
import 'camp_schedule_section.dart';
import 'event_timetable_section.dart';
import 'one_off_schedule_section.dart';

/// The schedule section of an event detail page, by event type:
///
/// - a camp not yet started edits its whole schedule — dates, times and
///   sessions — in [CampScheduleSection] (a cancelled camp shows it locked);
/// - a camp that has started keeps its dates, and only its timetable can be
///   corrected, in [EventTimetableSection] (club_core#85);
/// - a one-off that can still be moved edits its date, times, venue and
///   sessions in [OneOffScheduleSection]; once it has started or is called
///   off it shows them locked and corrects its timetable (club_client#37);
/// - a programme corrects its timetable in [EventTimetableSection].
class EventScheduleSection extends StatelessWidget {
  const EventScheduleSection({
    required this.event,
    required this.canEdit,
    super.key,
  });

  final Event event;

  /// Whether the viewer may change the schedule (an admin or the event's
  /// organizer).
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    if (event.type == EventType.oneOff) {
      return OneOffScheduleSection(event: event, canEdit: canEdit);
    }
    if (event.type != EventType.camp) {
      return EventTimetableSection(event: event, canEdit: canEdit);
    }
    if (canEdit && isCampTimetableOnly(event)) {
      return EventTimetableSection(
        event: event,
        canEdit: true,
        note: campStartedMessage,
      );
    }
    return CampScheduleSection(
      event: event,
      canEdit: canEdit,
      lockReason: canEdit ? campRescheduleLockReason(event) : null,
    );
  }
}
