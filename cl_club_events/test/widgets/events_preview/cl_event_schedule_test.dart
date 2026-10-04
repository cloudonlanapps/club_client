import 'package:cl_club_events/src/widgets/events_preview/cl_event_schedule.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

DateTime _localToUtc(int year, int month, int day, int hour, int minute) {
  return DateTime(year, month, day, hour, minute).toUtc();
}

Event eventFixture({
  EventType type = EventType.programme,
  String? rrule,
  DateTime? startTimeUtc,
  DateTime? endTimeUtc,
  DateTime? untilTimeUtc,
  List<EventSession>? sessions,
}) {
  final start = startTimeUtc ?? _localToUtc(2026, 5, 20, 10, 0);
  return Event(
    id: 1,
    title: 'Test Event',
    description: '',
    type: type,
    visibility: Visibility.public,
    venueId: 1,
    startTimeUtc: start,
    endTimeUtc: endTimeUtc ?? start.add(const Duration(hours: 2)),
    createdAtUtc: DateTime.utc(2026, 5),
    updatedAtUtc: DateTime.utc(2026, 5, 5),
    rrule: rrule,
    untilTimeUtc: untilTimeUtc,
    sessions: sessions,
  );
}

Widget wrap(Widget child) {
  return ShadApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  testWidgets(
    'Issue 257: renders Schedule header and time-of-day window',
    (tester) async {
      final event = eventFixture(
        startTimeUtc: _localToUtc(2026, 5, 20, 10, 0),
        endTimeUtc: _localToUtc(2026, 5, 20, 12, 0),
      );
      await tester.pumpWidget(wrap(ClEventSchedule(event: event)));
      await tester.pump();

      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('10:00 AM - 12:00 PM'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 257: event with rrule + until renders recurrence and series end',
    (tester) async {
      final event = eventFixture(
        rrule: 'FREQ=WEEKLY;BYDAY=SA',
        untilTimeUtc: DateTime.utc(2026, 6, 15),
      );
      await tester.pumpWidget(wrap(ClEventSchedule(event: event)));
      await tester.pump();

      expect(find.textContaining('Weekly'), findsOneWidget);
      expect(find.textContaining('Until'), findsOneWidget);
      expect(find.textContaining('June'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 257: event without sessions does not render Sessions header',
    (tester) async {
      final event = eventFixture(
        rrule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      await tester.pumpWidget(wrap(ClEventSchedule(event: event)));
      await tester.pump();

      expect(find.text('Sessions'), findsNothing);
    },
  );

  testWidgets(
    'Issue 257: event with multiple sessions renders each session row',
    (tester) async {
      final event = eventFixture(
        type: EventType.camp,
        startTimeUtc: _localToUtc(2026, 5, 20, 9, 0),
        endTimeUtc: _localToUtc(2026, 5, 20, 11, 0),
        sessions: const [
          EventSession(name: 'Warm-up', periodMinutes: 30),
          EventSession(name: 'Drills', periodMinutes: 60),
          EventSession(name: 'Cool-down', periodMinutes: 30),
        ],
      );
      await tester.pumpWidget(wrap(ClEventSchedule(event: event)));
      await tester.pump();

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Warm-up'), findsOneWidget);
      expect(find.text('Drills'), findsOneWidget);
      expect(find.text('Cool-down'), findsOneWidget);
      expect(find.text('9:00 AM - 9:30 AM'), findsOneWidget);
      expect(find.text('9:30 AM - 10:30 AM'), findsOneWidget);
      expect(find.text('10:30 AM - 11:00 AM'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 257: one-off event with only start/end has no recurrence sentence',
    (tester) async {
      final event = eventFixture(
        type: EventType.oneOff,
        startTimeUtc: _localToUtc(2026, 5, 20, 15, 0),
        endTimeUtc: _localToUtc(2026, 5, 20, 17, 0),
      );
      await tester.pumpWidget(wrap(ClEventSchedule(event: event)));
      await tester.pump();

      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('3:00 PM - 5:00 PM'), findsOneWidget);
      // One-off summary is the date itself, so a date string is rendered
      // but no "Weekly" / "Daily" recurrence sentence and no Until line.
      expect(find.textContaining('Weekly'), findsNothing);
      expect(find.textContaining('Daily'), findsNothing);
      expect(find.textContaining('Until'), findsNothing);
      expect(find.text('Sessions'), findsNothing);
    },
  );

  testWidgets(
    'Issue 257: camp with COUNT rrule renders "{N} day session"',
    (tester) async {
      final event = eventFixture(
        type: EventType.camp,
        rrule: 'FREQ=DAILY;COUNT=5',
      );
      await tester.pumpWidget(wrap(ClEventSchedule(event: event)));
      await tester.pump();

      expect(find.text('5 day session'), findsOneWidget);
    },
  );
}
