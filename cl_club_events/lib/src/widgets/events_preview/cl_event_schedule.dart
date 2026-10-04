import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show CampScheduleCalendar;

import '../../models/camp_schedule_form_helpers.dart'
    show buildCampScheduleInitialValues;
import '../../utils/time_formatter.dart';

/// Read-only schedule section for an event detail page — a titled [ShadCard]
/// wrapping [ClEventScheduleBody]. Used by the non-admin preview; the admin
/// detail page uses the card-less [ClEventScheduleBody] as the read mode of the
/// editable schedule section.
class ClEventSchedule extends StatelessWidget {
  const ClEventSchedule({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          ClEventScheduleBody(event: event),
        ],
      ),
    );
  }
}

/// The schedule content itself, without any card chrome or 'Schedule' heading.
///
/// Renders the time-of-day window, recurrence sentence, series end date
/// (when [Event.untilTimeUtc] is set), and the per-occurrence session
/// timetable (when [Event.sessions] is non-empty). Sits inside
/// [ClEventSchedule] (read-only preview) or an `EditableSectionCard` (the
/// admin schedule section's read mode).
class ClEventScheduleBody extends StatelessWidget {
  const ClEventScheduleBody({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    final mutedSmall = theme.textTheme.small.copyWith(color: muted);

    final timeText = formatTimeRange(event.startTimeUtc, event.endTimeUtc);
    final recurrenceText = eventScheduleSummary(event);
    final until = event.untilTimeUtc;
    final sessions = event.sessions;
    final hasSessions = sessions != null && sessions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ScheduleLine(
          icon: LucideIcons.clock,
          text: timeText,
          style: theme.textTheme.p,
          iconColor: muted,
        ),
        if (recurrenceText != null) ...[
          const SizedBox(height: 8),
          ScheduleLine(
            icon: LucideIcons.repeat,
            text: recurrenceText,
            style: theme.textTheme.p,
            iconColor: muted,
          ),
        ],
        if (event.type == EventType.camp && event.rrule != null)
          ..._campDatesSection(event, theme, muted),
        if (until != null) ...[
          const SizedBox(height: 8),
          ScheduleLine(
            icon: LucideIcons.calendarOff,
            text: 'Until ${formatDate(until.toLocal())}',
            style: theme.textTheme.p,
            iconColor: muted,
          ),
        ],
        if (hasSessions) ...[
          const SizedBox(height: 16),
          Text('Sessions', style: theme.textTheme.small),
          const SizedBox(height: 8),
          EventSessionsList(
            startTimeUtc: event.startTimeUtc,
            sessions: sessions,
            labelStyle: theme.textTheme.p,
            timeStyle: mutedSmall,
            dividerColor: theme.colorScheme.border,
          ),
        ],
      ],
    );
  }
}

/// The camp date-range line plus the read-only [CampScheduleCalendar], derived
/// from the event's rrule (`COUNT` + `EXDATE`). Empty when the window can't be
/// resolved. Camp events only.
List<Widget> _campDatesSection(Event event, ShadThemeData theme, Color muted) {
  final schedule = buildCampScheduleInitialValues(event);
  final start = schedule.startDate;
  if (start == null) return const [];
  final durationDays = schedule.trainingDays + schedule.excludedDates.length;
  final end = start.add(Duration(days: durationDays - 1));
  final rangeText = durationDays <= 1
      ? formatDate(start)
      : '${formatDate(start)} – ${formatDate(end)}';
  return [
    const SizedBox(height: 8),
    ScheduleLine(
      icon: LucideIcons.calendarDays,
      text: rangeText,
      style: theme.textTheme.p,
      iconColor: muted,
    ),
    const SizedBox(height: 12),
    CampScheduleCalendar(
      startDate: start,
      durationDays: durationDays,
      excludedDates: schedule.excludedDates,
    ),
  ];
}

/// One labelled row inside [ClEventSchedule]: an icon, a gap, then a
/// line of text. Kept as a top-level widget so the schedule card stays
/// declarative.
class ScheduleLine extends StatelessWidget {
  const ScheduleLine({
    required this.icon,
    required this.text,
    required this.style,
    required this.iconColor,
    super.key,
  });

  final IconData icon;
  final String text;
  final TextStyle? style;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

/// Per-occurrence timetable rendered as a stack of session rows. Each
/// session's slot is computed from the running offset against
/// [startTimeUtc] using [EventSession.periodMinutes].
class EventSessionsList extends StatelessWidget {
  const EventSessionsList({
    required this.startTimeUtc,
    required this.sessions,
    required this.labelStyle,
    required this.timeStyle,
    required this.dividerColor,
    super.key,
  });

  final DateTime startTimeUtc;
  final List<EventSession> sessions;
  final TextStyle? labelStyle;
  final TextStyle? timeStyle;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var cursor = startTimeUtc;
    for (var i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      final start = cursor;
      final end = cursor.add(Duration(minutes: session.periodMinutes));
      if (i > 0) {
        rows.add(Divider(height: 1, color: dividerColor));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text(session.name, style: labelStyle)),
              const SizedBox(width: 12),
              Text(formatTimeRange(start, end), style: timeStyle),
            ],
          ),
        ),
      );
      cursor = end;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}
