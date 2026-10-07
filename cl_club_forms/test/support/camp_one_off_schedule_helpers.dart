import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:cl_club_forms/src/widgets/event_schedule/camp_date_exclusion_calendar.dart';
import 'package:cl_club_forms/src/widgets/form/labeled_form_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The row of a schedule form labelled [label] (without the required mark).
Finder scheduleRow(String label) => find.byWidgetPredicate(
  (widget) => widget is LabeledFormRow && widget.label == label,
  description: 'row "$label"',
);

/// Types [text] into the text input of the row labelled [label].
Future<void> typeInRow(WidgetTester tester, String label, String text) async {
  await tester.enterText(
    find
        .descendant(of: scheduleRow(label), matching: find.byType(EditableText))
        .first,
    text,
  );
  await tester.pumpAndSettle();
}

/// Whether [text] shows inside the row labelled [label].
Finder textInRow(String label, String text) =>
    find.descendant(of: scheduleRow(label), matching: find.text(text));

/// Picks [date] in the schedule's date picker, as choosing a day in its
/// popover does (the popover itself is cl_calendar's).
Future<void> pickScheduleDate(WidgetTester tester, DateTime? date) async {
  tester
      .state<FormFieldState<DateTime?>>(find.byType(CLDatePickerFormField))
      .didChange(date);
  await tester.pumpAndSettle();
}

/// Sets the schedule's start time picker to [time], as filling its hour and
/// minute boxes does.
Future<void> pickScheduleStartTime(
  WidgetTester tester,
  ShadTimeOfDay? time,
) async {
  tester
      .state<FormFieldState<ShadTimeOfDay>>(
        find.byType(ShadTimePickerFormField),
      )
      .didChange(time);
  await tester.pumpAndSettle();
}

/// A time of day at [hour]:[minute].
ShadTimeOfDay timeAt(int hour, [int minute = 0]) =>
    ShadTimeOfDay(hour: hour, minute: minute, second: 0);

/// The cell of day [day] of the month the rest-day calendar shows. The grid
/// also shows the tail of the month before and the head of the month after,
/// so a low number is the first of its matches and a high one the last.
Finder restDayCell(int day) {
  final cells = find.descendant(
    of: find.byType(CampDateExclusionCalendar),
    matching: find.text('$day'),
  );
  return day < 15 ? cells.first : cells.last;
}

/// Taps day [day] of the month the rest-day calendar shows.
Future<void> tapRestDay(WidgetTester tester, int day) async {
  await tester.tap(restDayCell(day));
  await tester.pumpAndSettle();
}

/// Whether the popover of the schedule's date picker is open. A disabled
/// picker has no popover to open.
bool scheduleDatePickerIsOpen(WidgetTester tester) => tester
    .widgetList<ShadPopover>(
      find.descendant(
        of: find.byType(CLDatePickerFormField),
        matching: find.byType(ShadPopover),
      ),
    )
    .any((popover) => popover.controller?.isOpen ?? false);
