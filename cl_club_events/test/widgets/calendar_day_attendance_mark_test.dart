import 'package:cl_club_events/src/models/attendance_progress.dart';
import 'package:cl_club_events/src/widgets/attendance_progress_icon.dart';
import 'package:cl_club_events/src/widgets/calendar_day_view.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show FilmRollColorsExtension;

import '../support/calendar_cells.dart';
import '../support/staff_calendar_fixtures.dart';

void main() {
  final day = DateTime(2026, 11, 14);
  final otherDay = DateTime(2026, 11, 20);
  final camp = calendarEvent(1, EventType.camp);
  final programme = calendarEvent(2, EventType.programme);
  final types = {EventType.camp, EventType.programme};

  Occurrence session(Event event, int hour, int expected, int marked) =>
      calendarOccurrence(
        event.id,
        DateTime(day.year, day.month, day.day, hour).toUtc(),
      ).copyWith(
        attendanceExpected: () => expected,
        attendanceMarked: () => marked,
      );

  /// The day cell's mark, or null when it shows none.
  AttendanceProgressIcon? markOf(WidgetTester tester) {
    final found = find.byType(AttendanceProgressIcon);
    if (found.evaluate().isEmpty) return null;
    return tester.widget<AttendanceProgressIcon>(found);
  }

  Future<void> pumpDay(
    WidgetTester tester,
    List<Occurrence> sessions, {
    DateTime? selected,
    Brightness brightness = Brightness.light,
  }) async {
    final container = staffCalendarContainer(
      events: [camp, programme],
      occurrences: sessions,
      clubTypes: types,
    );
    await pumpDayCell(
      tester,
      container,
      day: day,
      selected: selected ?? otherDay,
      brightness: brightness,
    );
  }

  testWidgets(
    'Issue 414: a day with one session complete and one partly marked '
    'shows ◐ in the bottom-right, scaled with the cell',
    (tester) async {
      await pumpDay(tester, [
        session(camp, 8, 4, 4),
        session(programme, 10, 5, 2),
      ]);
      expect(markOf(tester)?.progress, AttendanceProgress.partial);
      expect(find.byIcon(LucideIcons.contrast), findsOneWidget);

      final cell = tester.getRect(find.byType(CalendarDayView));
      final icon = tester.getRect(find.byType(Icon));
      expect(icon.height, closeTo(cell.height * CalendarDayView.markShare, 1));
      expect(icon.right, lessThan(cell.right));
      expect(icon.bottom, lessThan(cell.bottom));
      expect(icon.left, greaterThan(cell.center.dx), reason: 'on the right');
      expect(icon.top, greaterThan(cell.center.dy), reason: 'at the bottom');
      final date = tester.getRect(find.text('${day.day}'));
      expect(date.center.dx, closeTo(cell.center.dx, 0.5), reason: 'centred');
      await disposeCalendar(tester);
    },
  );

  testWidgets('Issue 414: a day whose sessions are all marked shows ✓', (
    tester,
  ) async {
    await pumpDay(tester, [
      session(camp, 8, 4, 4),
      session(programme, 10, 5, 5),
    ]);
    expect(markOf(tester)?.progress, AttendanceProgress.complete);
    expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
    await disposeCalendar(tester);
  });

  testWidgets('Issue 414: a day with nothing marked shows no mark', (
    tester,
  ) async {
    await pumpDay(tester, [
      session(camp, 8, 4, 0),
      session(programme, 10, 5, 0),
    ]);
    expect(markOf(tester), isNull);
    await disposeCalendar(tester);
  });

  testWidgets('Issue 414: the member calendar shows no mark', (tester) async {
    final container = staffCalendarContainer(
      events: [camp],
      occurrences: [session(camp, 8, 4, 4)],
    );
    await pumpDayCell(
      tester,
      container,
      day: day,
      selected: otherDay,
      memberUsername: 'member414',
    );
    expect(markOf(tester), isNull);
    await disposeCalendar(tester);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'Issue 414: the mark reads on the selected day, today and a '
      'highlighted day (${brightness.name})',
      (tester) async {
        final colors = calendarTheme(brightness).colorScheme;

        // Selected: the selected text colour.
        await pumpDay(
          tester,
          [session(camp, 8, 4, 2)],
          selected: day,
          brightness: brightness,
        );
        expect(markOf(tester)?.color, colors.primaryForeground);
        await disposeCalendar(tester);

        // On the camp highlight, on today's muted cell and on the page,
        // both marks keep a 3:1 contrast.
        for (final progress in const [
          AttendanceProgress.partial,
          AttendanceProgress.complete,
        ]) {
          final ink = AttendanceProgressIcon.colorOf(progress, brightness);
          for (final (name, background) in [
            ('highlight', colors.specialEventHighlight),
            ('today', colors.muted),
            ('page', colors.background),
          ]) {
            expect(
              _contrast(ink, background),
              greaterThanOrEqualTo(3),
              reason: '${progress.name} on $name',
            );
          }
        }

        // And the cell draws it in that colour on the highlight.
        await pumpDay(tester, [
          session(camp, 8, 4, 4),
        ], brightness: brightness);
        expect(
          markOf(tester)?.color,
          isNull,
          reason: 'not selected: the state colour',
        );
        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(
          icon.color,
          AttendanceProgressIcon.colorOf(
            AttendanceProgress.complete,
            brightness,
          ),
        );
        await disposeCalendar(tester);
      },
    );
  }
}

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
