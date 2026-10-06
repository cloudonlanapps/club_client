import 'package:club_sdk_2/club_sdk_2.dart' show Event;
import 'package:flutter/material.dart';

import 'event_timetable_section.dart';
import 'programme_schedule_actions.dart';
import 'programme_schedule_read.dart';

/// The Schedule block of a programme's detail page: its present terms (and
/// the day the next ones start, while a change is pending), the timetable
/// correction of [EventTimetableSection], and, for an admin or the
/// organizer, the actions that change the schedule from a session onward
/// ([ProgrammeScheduleActions]).
class ProgrammeScheduleSection extends StatelessWidget {
  const ProgrammeScheduleSection({
    required this.event,
    required this.canEdit,
    super.key,
  });

  final Event event;

  /// Whether the viewer may change the schedule (an admin or the
  /// programme's organizer).
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return EventTimetableSection(
      event: event,
      canEdit: canEdit,
      read: canEdit ? ProgrammeScheduleRead(event: event) : null,
      actions: canEdit ? ProgrammeScheduleActions(event: event) : null,
    );
  }
}
