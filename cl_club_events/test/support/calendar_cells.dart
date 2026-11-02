/// Pumps the staff calendar's own cells — a day's half-hour slots
/// ([CalendarSlotView]) or a month day ([CalendarDayView]) — over a
/// [staffCalendarContainer], in a light or dark theme.
library;

import 'package:cl_calendar/cl_calendar.dart';
import 'package:cl_club_events/src/providers/cached_date_items.dart';
import 'package:cl_club_events/src/widgets/calendar_day_view.dart';
import 'package:cl_club_events/src/widgets/calendar_slot_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show darkCustomColors, lightCustomColors;

import 'staff_calendar_fixtures.dart';

/// Size of a half-hour cell: a phone's day column.
const Size slotCellSize = Size(70, 24);

/// Size of a month day cell.
const Size dayCellSize = Size(48, 48);

/// The app's slate theme for [brightness], with the calendar's custom
/// colours.
ShadThemeData calendarTheme(Brightness brightness) => ShadThemeData(
  brightness: brightness,
  colorScheme: brightness == Brightness.dark
      ? const ShadSlateColorScheme.dark(custom: darkCustomColors)
      : const ShadSlateColorScheme.light(custom: lightCustomColors),
);

Widget _app(ProviderContainer container, Brightness brightness, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: ShadApp(
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        theme: calendarTheme(Brightness.light),
        darkTheme: calendarTheme(Brightness.dark),
        home: Scaffold(body: Center(child: child)),
      ),
    );

/// Pumps [day]'s half-hour cells from [fromHour] to [toHour] (local), as
/// the week view lays them out, and waits for the day's sessions to load.
/// The cells report the slot tapped through [onSelect].
Future<void> pumpDaySlots(
  WidgetTester tester,
  ProviderContainer container, {
  required DateTime day,
  int fromHour = 7,
  int toHour = 12,
  Brightness brightness = Brightness.light,
  void Function(DateTime slot)? onSelect,
}) async {
  final range = WeekViewRange.fromDate(day);
  await tester.pumpWidget(
    _app(
      container,
      brightness,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var m = fromHour * 60; m < toHour * 60; m += 30)
            SizedBox.fromSize(
              size: slotCellSize,
              child: CalendarSlotView(
                slotTime: DateTime(day.year, day.month, day.day, 0, m),
                size: slotCellSize,
                range: range,
                selectedDateTime: DateTime(day.year, day.month, day.day),
                onChangeSelectedDateTime: onSelect ?? (_) {},
              ),
            ),
        ],
      ),
    ),
  );
  final key = (date: DateUtils.dateOnly(day), range: range);
  await tester.runAsync(
    () =>
        settle(() => container.read(cachedDateItemsProvider(key)).data != null),
  );
  await tester.pump();
}

/// The half-hour cell of [day] at [hour]:[minute].
Finder slotCell(DateTime day, int hour, [int minute = 0]) =>
    find.byWidgetPredicate(
      (w) =>
          w is CalendarSlotView &&
          w.slotTime == DateTime(day.year, day.month, day.day, hour, minute),
    );

/// Pumps the month view's cell for [day], with [selected] the day picked
/// on the calendar, and waits for the month's sessions to load.
Future<void> pumpDayCell(
  WidgetTester tester,
  ProviderContainer container, {
  required DateTime day,
  required DateTime selected,
  Brightness brightness = Brightness.light,
  String? memberUsername,
  Size size = dayCellSize,
}) async {
  await tester.pumpWidget(
    _app(
      container,
      brightness,
      SizedBox.fromSize(
        size: size,
        child: CalendarDayView(
          date: day,
          size: size,
          range: MonthViewRange(year: day.year, month: day.month),
          selectedDateTime: selected,
          onChangeSelectedDateTime: (_) {},
          memberUsername: memberUsername,
        ),
      ),
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
}

/// Unmounts the cells and lets their providers' timers run out, so a test
/// ends with nothing pending.
Future<void> disposeCalendar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}
