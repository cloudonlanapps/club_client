import 'package:cl_club_events/src/models/selected_occurrence.dart';
import 'package:cl_club_events/src/providers/selected_occurrence.dart';
import 'package:cl_club_events/src/utils/session_lanes.dart';
import 'package:cl_club_events/src/widgets/calendar_session_block.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/calendar_cells.dart';
import '../support/staff_calendar_fixtures.dart';

void main() {
  final day = DateTime(2026, 11, 14);
  final events = [
    for (var id = 1; id <= 4; id++) calendarEvent(id, EventType.camp),
  ];

  /// A session of event [id] from [from] to [to], as (hour, minute) local.
  Occurrence session(
    int id,
    (int, int) from,
    (int, int) to, {
    bool cancelled = false,
  }) {
    DateTime at((int, int) t) =>
        DateTime(day.year, day.month, day.day, t.$1, t.$2).toUtc();
    return Occurrence(
      eventId: id,
      originalStartTimeUtc: at(from),
      actualStartTimeUtc: at(from),
      actualEndTimeUtc: at(to),
      status: cancelled
          ? OccurrenceStatus.cancelled
          : OccurrenceStatus.scheduled,
      venueId: 1,
    );
  }

  SelectedOccurrence item(Occurrence o) => (o, events[o.eventId - 1]);

  /// The lanes [sessionLanes] gives, as event id → (lane, lanes).
  Map<int, (int, int)> lanesOf(List<Occurrence> sessions) => {
    for (final l in sessionLanes([for (final s in sessions) item(s)]))
      l.item.$1.eventId: (l.lane, l.lanes),
  };

  group('Issue 420: sessions are split into lanes per day', () {
    test('Issue 420: two overlapping sessions take two lanes', () {
      expect(
        lanesOf([session(1, (8, 30), (10, 0)), session(2, (8, 30), (10, 0))]),
        {1: (0, 2), 2: (1, 2)},
      );
    });

    test('Issue 420: partly overlapping sessions take two lanes', () {
      expect(
        lanesOf([session(2, (8, 30), (10, 0)), session(1, (8, 0), (9, 0))]),
        {1: (0, 2), 2: (1, 2)},
      );
    });

    test('Issue 420: sessions that do not overlap keep the full width', () {
      expect(
        lanesOf([session(1, (8, 0), (9, 0)), session(2, (9, 0), (10, 0))]),
        {1: (0, 1), 2: (0, 1)},
      );
    });

    test(
      'Issue 420: a chain of overlaps shares lanes; a later lone session is '
      'full width',
      () {
        expect(
          lanesOf([
            session(1, (8, 0), (9, 0)),
            session(2, (8, 30), (10, 0)),
            session(3, (9, 0), (10, 30)),
            session(4, (11, 0), (12, 0)),
          ]),
          {1: (0, 2), 2: (1, 2), 3: (0, 2), 4: (0, 1)},
        );
      },
    );
  });

  /// The session blocks in [cell], left to right, with their rects.
  List<(CalendarSessionBlock, Rect)> blocksIn(
    WidgetTester tester,
    Finder cell,
  ) {
    final found = find.descendant(
      of: cell,
      matching: find.byType(CalendarSessionBlock),
    );
    final blocks = [
      for (final e in found.evaluate())
        (
          e.widget as CalendarSessionBlock,
          tester.getRect(find.byWidget(e.widget)),
        ),
    ]..sort((a, b) => a.$2.left.compareTo(b.$2.left));
    return blocks;
  }

  testWidgets(
    'Issue 420: partly overlapping sessions keep their lane in every cell, '
    'and each lane selects its session',
    (tester) async {
      final early = session(1, (8, 0), (9, 0));
      final late = session(2, (8, 30), (10, 0), cancelled: true);
      final container = staffCalendarContainer(
        events: events,
        occurrences: [early, late],
      );
      await pumpDaySlots(tester, container, day: day);
      final half = slotCellSize.width / 2;

      // 8:00: the early session alone, in the left lane.
      final at8 = blocksIn(tester, slotCell(day, 8));
      expect(at8, hasLength(1));
      expect(at8.single.$1.cancelled, isFalse);
      expect(at8.single.$2.width, closeTo(half, 0.01));
      final left = at8.single.$2.left;
      final cellLeft = tester.getRect(slotCell(day, 8)).left;
      expect(left, closeTo(cellLeft, 0.01));

      // 8:30: both, side by side.
      final at830 = blocksIn(tester, slotCell(day, 8, 30));
      expect(at830.map((b) => b.$1.cancelled), [false, true]);
      expect(at830[0].$2.left, closeTo(left, 0.01));
      expect(at830[1].$2.left, closeTo(left + half, 0.01));

      // 9:00 and 9:30: the late session alone, still in the right lane.
      for (final minute in const [0, 30]) {
        final blocks = blocksIn(tester, slotCell(day, 9, minute));
        expect(blocks, hasLength(1));
        expect(blocks.single.$1.cancelled, isTrue);
        expect(blocks.single.$2.left, closeTo(left + half, 0.01));
        expect(blocks.single.$2.width, closeTo(half, 0.01));
      }

      // Each lane in the shared cell selects its own session.
      await tester.tapAt(at830[1].$2.center);
      await tester.pump();
      expect(container.read(selectedOccurrenceProvider)?.eventId, 2);
      await tester.tapAt(at830[0].$2.center);
      await tester.pump();
      expect(container.read(selectedOccurrenceProvider)?.eventId, 1);
    },
  );

  testWidgets('Issue 420: two sessions at the same time show in two lanes', (
    tester,
  ) async {
    final container = staffCalendarContainer(
      events: events,
      occurrences: [
        session(1, (8, 30), (10, 0)),
        session(2, (8, 30), (10, 0)),
      ],
    );
    await pumpDaySlots(tester, container, day: day);
    for (final (hour, minute) in const [(8, 30), (9, 0), (9, 30)]) {
      final blocks = blocksIn(tester, slotCell(day, hour, minute));
      expect(blocks, hasLength(2), reason: 'two lanes at $hour:$minute');
      expect(blocks[0].$2.width, closeTo(slotCellSize.width / 2, 0.01));
      expect(blocks[1].$2.left, closeTo(blocks[0].$2.right, 0.01));
    }
    final lanes = blocksIn(tester, slotCell(day, 9));
    for (final (lane, id) in [(lanes[0], 1), (lanes[1], 2)]) {
      await tester.tapAt(lane.$2.center);
      await tester.pump();
      expect(container.read(selectedOccurrenceProvider)?.eventId, id);
    }
  });

  testWidgets(
    'Issue 420: a session that overlaps nothing uses the full width',
    (tester) async {
      final container = staffCalendarContainer(
        events: events,
        occurrences: [session(1, (8, 0), (9, 0)), session(2, (9, 0), (10, 0))],
      );
      await pumpDaySlots(tester, container, day: day);
      for (final hour in const [8, 9]) {
        final blocks = blocksIn(tester, slotCell(day, hour));
        expect(blocks, hasLength(1));
        expect(blocks.single.$2.width, closeTo(slotCellSize.width, 0.01));
      }
      await tester.tap(slotCell(day, 9));
      await tester.pump();
      expect(container.read(selectedOccurrenceProvider)?.eventId, 2);
    },
  );
}
