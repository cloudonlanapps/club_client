import 'package:cl_remote_store/cl_remote_store.dart'
    show clSingleOccurrenceProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Event, OccurrenceStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/one_off_schedule_form_helpers.dart';
import 'event_timetable_section.dart';
import 'one_off_reschedule_section.dart';

/// The Schedule block of a one-off's detail page:
///
/// - while the one-off can still be moved, its date, times, venue and
///   sessions are edited in place in [OneOffRescheduleSection];
/// - once it has started, is about to, or is called off, an editor sees the
///   schedule locked with the reason, and corrects only its timetable, in
///   [EventTimetableSection].
class OneOffScheduleSection extends ConsumerWidget {
  const OneOffScheduleSection({
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
    if (!canEdit) {
      return OneOffRescheduleSection(event: event, canEdit: false);
    }
    // A one-off is called off through its single occurrence, which the
    // event itself does not report. Unknown reads as not called off: the
    // server refuses the move, and the editor says why.
    final occurrence = ref
        .watch(
          clSingleOccurrenceProvider((
            eventId: event.id,
            occurrenceTimeUtc: event.startTimeUtc,
          )),
        )
        .valueOrNull;
    final lockReason = oneOffRescheduleLockReason(
      event,
      calledOff: occurrence?.status == OccurrenceStatus.cancelled,
    );
    if (lockReason != null) {
      return EventTimetableSection(
        event: event,
        canEdit: true,
        note: lockReason,
      );
    }
    return OneOffRescheduleSection(event: event, canEdit: true);
  }
}
