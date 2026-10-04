import 'package:cl_club_events/src/widgets/events_preview/cl_event_preview.dart';
import 'package:cl_club_events/src/widgets/events_preview/cl_event_schedule.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Event _event() {
  final start = DateTime(2026, 5, 20, 10).toUtc();
  return Event(
    id: 1,
    title: 'Test Event',
    description: 'A short description.',
    type: EventType.programme,
    visibility: Visibility.public,
    venueId: 1,
    startTimeUtc: start,
    endTimeUtc: start.add(const Duration(hours: 2)),
    createdAtUtc: DateTime.utc(2026, 5),
    updatedAtUtc: DateTime.utc(2026, 5, 5),
    rrule: 'FREQ=WEEKLY;BYDAY=SA',
  );
}

void main() {
  testWidgets(
    'Issue 257: ClEventPreview renders the schedule block',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: ShadApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ClEventPreview(event: _event()),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClEventSchedule), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
    },
  );
}
