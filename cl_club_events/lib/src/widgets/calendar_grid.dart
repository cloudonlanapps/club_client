import 'package:cl_calendar/cl_calendar.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'calendar_day_view.dart';
import 'calendar_slot_view.dart';

/// A dedicated calendar view widget that displays events in a grid.
/// Supports month, week, and day views with navigation header.
/// Customizes the default SimpleCalendarView with event-aware date and slot
/// builders.
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({this.memberUsername, super.key});

  /// When non-null, day-cell highlighting reads from member endpoints
  /// (`/myevents/{username}/...`). When null, the admin endpoint is used.
  final String? memberUsername;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return GetCalendarViewRange(
      builder: (controller, range, selectedDateTime, onChangeSelectedDateTime) {
        return SimpleCalendarView(
          controller: controller,
          range: range,
          dateBuilder: (date, size) => CalendarDayView(
            date: date,
            size: size,
            range: range,
            selectedDateTime: selectedDateTime,
            onChangeSelectedDateTime: onChangeSelectedDateTime,
            memberUsername: memberUsername,
          ),
          slotBuilder: (slotTime, size) => CalendarSlotView(
            slotTime: slotTime,
            size: size,
            range: range,
            selectedDateTime: selectedDateTime,
            onChangeSelectedDateTime: onChangeSelectedDateTime,
          ),
          rowHeight: () => null,
          cellBorder: BorderSide(color: theme.colorScheme.border),
        );
      },
    );
  }
}
