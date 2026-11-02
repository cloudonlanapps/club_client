import 'package:cl_calendar/cl_calendar.dart';
import 'package:cl_club_events/src/models/range_occurrences_key.dart';
import 'package:cl_club_events/src/providers/cached_occurrences.dart';
import 'package:cl_club_events/src/providers/day_event_counts.dart';
import 'package:cl_club_events/src/providers/selected_occurrence.dart';
import 'package:cl_club_events/src/widgets/calendar_session_block.dart';
import 'package:cl_club_events/src/widgets/cancelled_stripes_painter.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show FilmRollColorsExtension;

import '../support/calendar_cells.dart';
import '../support/staff_calendar_fixtures.dart';

void main() {
  // A day well away from any clock change; sessions in local time.
  final day = DateTime(2026, 11, 14);
  final camp = calendarEvent(1, EventType.camp);
  final otherCamp = calendarEvent(2, EventType.camp);
  Occurrence session(Event event, int hour, {bool cancelled = false}) =>
      calendarOccurrence(
        event.id,
        DateTime(day.year, day.month, day.day, hour).toUtc(),
      ).copyWith(
        status: cancelled
            ? OccurrenceStatus.cancelled
            : OccurrenceStatus.scheduled,
      );

  /// The session block drawn in [cell], or null when the cell is empty.
  CalendarSessionBlock? blockIn(WidgetTester tester, Finder cell) {
    final found = find.descendant(
      of: cell,
      matching: find.byType(CalendarSessionBlock),
    );
    if (found.evaluate().isEmpty) return null;
    return tester.widget<CalendarSessionBlock>(found);
  }

  /// The stripes painted for the cancelled session in [cell], or null.
  CancelledStripesPainter? stripesIn(WidgetTester tester, Finder cell) {
    for (final paint in tester.widgetList<CustomPaint>(
      find.descendant(of: cell, matching: find.byType(CustomPaint)),
    )) {
      final painter = paint.painter;
      if (painter is CancelledStripesPainter) return painter;
    }
    return null;
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'Issue 419: a cancelled session is drawn striped and faint, apart from '
      'a live one (${brightness.name})',
      (tester) async {
        final container = staffCalendarContainer(
          events: [camp, otherCamp],
          occurrences: [
            session(camp, 8),
            session(otherCamp, 10, cancelled: true),
          ],
        );
        await pumpDaySlots(
          tester,
          container,
          day: day,
          brightness: brightness,
        );
        final colors = calendarTheme(brightness).colorScheme;

        final live = blockIn(tester, slotCell(day, 8));
        expect(live?.cancelled, isFalse);
        expect(stripesIn(tester, slotCell(day, 8)), isNull);
        final fill = tester.widget<ColoredBox>(
          find.descendant(
            of: slotCell(day, 8),
            matching: find.byType(ColoredBox),
          ),
        );
        expect(fill.color.r, colors.primary.r, reason: 'live is primary');

        for (final minute in const [0, 30]) {
          final cell = slotCell(day, 10, minute);
          expect(blockIn(tester, cell)?.cancelled, isTrue);
          final stripes = stripesIn(tester, cell);
          expect(stripes, isNotNull, reason: 'striped at 10:$minute');
          expect(
            stripes!.color.withValues(alpha: 1),
            colors.mutedForeground,
            reason: 'stripes in the muted colour, not primary',
          );
          expect(stripes.background.withValues(alpha: 1), colors.muted);
          expect(stripes.color.a, lessThan(1), reason: 'faint');
          // The stripes stand out from their fill and from the page.
          expect(
            _contrast(stripes.color, stripes.background, colors.background),
            greaterThan(1.3),
          );
        }
        expect(blockIn(tester, slotCell(day, 11)), isNull);
      },
    );
  }

  testWidgets('Issue 419: tapping a cancelled session selects it', (
    tester,
  ) async {
    final cancelled = session(otherCamp, 10, cancelled: true);
    final container = staffCalendarContainer(
      events: [otherCamp],
      occurrences: [cancelled],
    );
    DateTime? picked;
    await pumpDaySlots(
      tester,
      container,
      day: day,
      onSelect: (slot) => picked = slot,
    );

    await tester.tap(slotCell(day, 10, 30));
    await tester.pump();

    expect(container.read(selectedOccurrenceProvider), (
      eventId: otherCamp.id,
      originalStartTime: cancelled.originalStartTimeUtc,
    ));
    expect(picked, DateTime(day.year, day.month, day.day, 10, 30));
    expect(blockIn(tester, slotCell(day, 10))?.selected, isTrue);
    expect(
      stripesIn(tester, slotCell(day, 10))!.color.a,
      CalendarSessionBlock.cancelledStripesSelected,
      reason: 'a selected cancelled session strengthens its stripes',
    );
  });

  test(
    'Issue 419: a cancelled session does not count towards the day',
    () async {
      final container = staffCalendarContainer(
        events: [camp, otherCamp],
        occurrences: [
          session(camp, 8, cancelled: true),
          session(otherCamp, 10, cancelled: true),
        ],
      );
      final RangeOccurrencesKey key = (
        range: MonthViewRange(year: day.year, month: day.month),
      );
      container.listen(cachedOccurrencesProvider(key), (_, _) {});
      await settle(
        () => !container.read(cachedOccurrencesProvider(key)).isLoading,
      );

      final counts = await container.read(dayEventCountsProvider(key).future);

      expect(counts[day], isNull);
    },
  );

  testWidgets(
    'Issue 419: a day whose only camp sessions are cancelled has no highlight',
    (tester) async {
      final selected = day.add(const Duration(days: 2));
      final cancelledOnly = staffCalendarContainer(
        events: [camp],
        occurrences: [session(camp, 8, cancelled: true)],
      );
      await pumpDayCell(tester, cancelledOnly, day: day, selected: selected);
      final highlight = calendarTheme(
        Brightness.light,
      ).colorScheme.specialEventHighlight;
      expect(_cellColour(tester), isNot(highlight));

      final live = staffCalendarContainer(
        events: [camp],
        occurrences: [session(camp, 8)],
      );
      await pumpDayCell(tester, live, day: day, selected: selected);
      expect(_cellColour(tester), highlight, reason: 'a live camp day still');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}

/// The month day cell's background.
Color? _cellColour(WidgetTester tester) {
  final box = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(Scaffold),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.decoration is BoxDecoration,
          ),
        )
        .last,
  );
  return (box.decoration! as BoxDecoration).color;
}

/// Contrast ratio between [stripe] and [fill], each laid over [page].
double _contrast(Color stripe, Color fill, Color page) {
  final f = Color.alphaBlend(fill, page);
  final s = Color.alphaBlend(stripe, f);
  final a = s.computeLuminance();
  final b = f.computeLuminance();
  return (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
}
