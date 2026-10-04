import 'package:cl_club_events/src/widgets/events_preview/cl_event_stamps.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Event eventFixture({
  Visibility visibility = Visibility.public,
  bool isFeatured = false,
}) {
  final now = DateTime.utc(2026, 5, 14);
  return Event(
    id: 1,
    title: 'Test Event',
    description: '',
    type: EventType.camp,
    visibility: visibility,
    venueId: 1,
    startTimeUtc: now,
    endTimeUtc: now.add(const Duration(hours: 2)),
    createdAtUtc: now,
    updatedAtUtc: now,
    isFeatured: isFeatured,
  );
}

Widget wrap(Widget child) => ShadApp(
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'Issue 262: public + non-featured renders no stamps',
    (tester) async {
      await tester.pumpWidget(wrap(ClEventStamps(event: eventFixture())));
      expect(find.byType(PrivateStamp), findsNothing);
      expect(find.byType(FeaturedStamp), findsNothing);
    },
  );

  testWidgets(
    'Issue 262: private + non-featured renders only the private stamp',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          ClEventStamps(
            event: eventFixture(visibility: Visibility.private),
          ),
        ),
      );
      expect(find.byType(PrivateStamp), findsOneWidget);
      expect(find.byType(FeaturedStamp), findsNothing);
      expect(find.text('PRIVATE'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 262: public + featured renders only the featured stamp',
    (tester) async {
      await tester.pumpWidget(
        wrap(ClEventStamps(event: eventFixture(isFeatured: true))),
      );
      expect(find.byType(FeaturedStamp), findsOneWidget);
      expect(find.byType(PrivateStamp), findsNothing);
    },
  );

  testWidgets(
    'Issue 262: private + featured renders both stamps',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          ClEventStamps(
            event: eventFixture(
              visibility: Visibility.private,
              isFeatured: true,
            ),
          ),
        ),
      );
      expect(find.byType(PrivateStamp), findsOneWidget);
      expect(find.byType(FeaturedStamp), findsOneWidget);
    },
  );
}
