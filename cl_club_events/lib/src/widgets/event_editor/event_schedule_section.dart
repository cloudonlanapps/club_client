import 'package:cl_remote_store/cl_remote_store.dart'
    show clOccurrencesProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Event, EventType, lastOccurrenceEndUtc;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/camp_schedule_form_helpers.dart'
    show
        campAttendanceRecordedMessage,
        campRescheduleLockReason,
        hasRecordedAttendance,
        isCampTimetableOnly;
import 'camp_schedule_section.dart';
import 'event_timetable_section.dart';
import 'one_off_schedule_section.dart';
import 'programme_schedule_section.dart';

/// The schedule section of an event detail page, by event type:
///
/// - a camp not yet started edits its whole schedule — dates, times and
///   sessions — in [CampScheduleSection] (a cancelled camp shows it locked);
/// - a camp with attendance recorded keeps its dates, and only its
///   timetable can be corrected, in [EventTimetableSection] (club_core#85).
///   A camp whose start has passed with nothing recorded is still edited
///   whole (club_client#443). Until its sessions load, a started camp is
///   treated as recorded;
/// - a one-off that can still be moved edits its date, times, venue and
///   sessions in [OneOffScheduleSection]; once it has started or is called
///   off it shows them locked and corrects its timetable (club_client#37);
/// - a programme corrects its timetable in place and adjusts its schedule
///   from a chosen session onward, in [ProgrammeScheduleSection]
///   (club_client#38).
class EventScheduleSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (event.type == EventType.oneOff) {
      return OneOffScheduleSection(event: event, canEdit: canEdit);
    }
    if (event.type == EventType.programme) {
      return ProgrammeScheduleSection(event: event, canEdit: canEdit);
    }
    final recorded = canEdit && _attendanceRecorded(ref);
    if (canEdit && isCampTimetableOnly(event, attendanceRecorded: recorded)) {
      return EventTimetableSection(
        event: event,
        canEdit: true,
        note: campAttendanceRecordedMessage,
      );
    }
    return CampScheduleSection(
      event: event,
      canEdit: canEdit,
      lockReason: canEdit
          ? campRescheduleLockReason(event, attendanceRecorded: recorded)
          : null,
    );
  }

  /// Whether the camp has attendance recorded against any of its sessions.
  /// Before the sessions load, a camp whose start has passed counts as
  /// recorded, so the dates are never offered and then withdrawn.
  bool _attendanceRecorded(WidgetRef ref) {
    final occurrences = ref
        .watch(
          clOccurrencesProvider((
            from: event.startTimeUtc,
            to: lastOccurrenceEndUtc(event),
          )),
        )
        .valueOrNull;
    if (occurrences == null) {
      return !event.startTimeUtc.isAfter(DateTime.now().toUtc());
    }
    return hasRecordedAttendance(occurrences, event.id);
  }
}
