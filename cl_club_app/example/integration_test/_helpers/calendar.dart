// Month-grid navigation for integration tests (club_client#413).
//
// Owns:
//   * calendarDayCell        — the grid's cell for a local day.
//   * selectCalendarDayViaUi — move the grid to a day's month with the
//                              header's arrows, then tap the day.
//
// Works on any screen built on CalendarGrid: the Club Calendar and a
// member's My Calendar.

import 'package:cl_club_events/src/widgets/calendar_day_view.dart'
    show CalendarDayView;
import 'package:cl_club_events/src/widgets/calendar_grid.dart'
    show CalendarGrid;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'pump.dart';

/// The month grid's cell for the local [day].
Finder calendarDayCell(DateTime day) => find.descendant(
  of: find.byType(CalendarGrid),
  matching: find.byWidgetPredicate(
    (w) => w is CalendarDayView && DateUtils.isSameDay(w.date, day),
  ),
);

/// Moves the month grid to the local [day]'s month, a month per tap of the
/// header's arrows, and taps the day. A month grid shows only its own days,
/// so the cell is found once the grid is on that month.
Future<void> selectCalendarDayViaUi(WidgetTester tester, DateTime day) async {
  await waitFor(
    tester,
    () => find
        .descendant(
          of: find.byType(CalendarGrid),
          matching: find.byType(CalendarDayView),
        )
        .evaluate()
        .isNotEmpty,
    description: 'the calendar grid',
  );
  final target = day.year * 12 + day.month;
  for (var step = 0; step < 24; step++) {
    // A month range runs from the 1st to the month's last moment.
    final shownMonth = tester
        .widget<CalendarDayView>(find.byType(CalendarDayView).first)
        .range
        .start;
    final shown = shownMonth.year * 12 + shownMonth.month;
    if (shown == target) break;
    await tapVisible(
      tester,
      find.descendant(
        of: find.byType(CalendarGrid),
        matching: find.byIcon(
          shown > target ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
        ),
      ),
    );
    await settle(tester);
  }
  final cell = calendarDayCell(day);
  await waitFor(
    tester,
    () => cell.evaluate().isNotEmpty,
    description: 'the ${day.year}-${day.month}-${day.day} cell',
  );
  await tapVisible(tester, cell.first);
  await settle(tester);
}
