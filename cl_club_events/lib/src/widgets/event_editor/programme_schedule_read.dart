import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventSchedulesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../utils/programme_schedule_sessions.dart';
import '../events_preview/cl_event_schedule.dart'
    show ClEventScheduleBody, ScheduleLine;

/// The line under a programme's present terms while a change is pending:
/// the day the schedule starting at [fromUtc] takes over.
String programmeNextScheduleLine(DateTime fromUtc) =>
    'New schedule from ${formatDate(fromUtc.toLocal())}';

/// A programme's schedule as its Schedule block reads: the terms its
/// sessions follow now and, when an adjustment is pending, the day the next
/// terms start.
///
/// The event itself describes its latest schedule, which a pending
/// adjustment has not reached yet; the present terms are then read from the
/// programme's schedules.
class ProgrammeScheduleRead extends ConsumerWidget {
  const ProgrammeScheduleRead({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final schedules = ref.watch(clEventSchedulesProvider(event.id)).valueOrNull;
    final pending = pendingProgrammeSchedule(schedules);
    final present = pending == null
        ? null
        : presentProgrammeSchedule(schedules);
    final shown = present == null
        ? event
        : event.copyWith(
            startTimeUtc: present.startTimeUtc,
            endTimeUtc: present.endTimeUtc,
            rrule: () => present.rrule,
            sessions: () => present.sessions,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClEventScheduleBody(event: shown),
        if (pending != null) ...[
          const SizedBox(height: 8),
          ScheduleLine(
            icon: LucideIcons.calendarPlus,
            text: programmeNextScheduleLine(pending.effectiveFromUtc),
            style: theme.textTheme.p,
            iconColor: theme.colorScheme.mutedForeground,
          ),
        ],
      ],
    );
  }
}
