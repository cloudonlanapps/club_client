import 'package:cl_club_events/cl_club_events.dart' show PublicEventCard;
import 'package:cl_club_website/src/l10n/site_strings.dart';
import 'package:cl_club_website/src/widgets/landing_events_section.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clPublicEventsProvider;
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'support/public_events.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required EventType type,
  required List<PublicEvent> events,
}) async {
  tester.view.physicalSize = const Size(1280, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serverConfigProvider.overrideWithValue(
          const ServerConfig(baseUrl: testApiBase),
        ),
        clPublicEventsProvider(type).overrideWith((ref) async => events),
      ],
      child: ShadApp(
        home: SiteStringsScope(
          strings: SiteStrings(const {}),
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _cardTitles(WidgetTester tester) => tester
    .widgetList<PublicEventCard>(find.byType(PublicEventCard))
    .map((card) => card.event.title)
    .toList();

void main() {
  group('Issue 53: the landing page event sections', () {
    testWidgets('Issue 53: camps show the two soonest active camps', (
      tester,
    ) async {
      await _pump(
        tester,
        const LandingEventsSection(type: EventType.camp),
        type: EventType.camp,
        events: [
          testPublicEvent(
            publicId: 'c3',
            title: 'Third',
            start: DateTime(2026, 7),
          ),
          testPublicEvent(
            publicId: 'c1',
            title: 'First',
            start: DateTime(2026, 5),
          ),
          testPublicEvent(publicId: 'cp', title: 'Past', isPast: true),
          testPublicEvent(
            publicId: 'c2',
            title: 'Second',
            start: DateTime(2026, 6),
          ),
        ],
      );

      expect(_cardTitles(tester), ['First', 'Second']);
      expect(find.text('campsLandingTitle'), findsOneWidget);
      expect(find.text('campsLandingButton'), findsOneWidget);
      expect(find.text('View Details'), findsNothing);
    });

    testWidgets('Issue 53: programmes are picked on different days', (
      tester,
    ) async {
      await _pump(
        tester,
        const LandingEventsSection(type: EventType.programme),
        type: EventType.programme,
        events: [
          testPublicEvent(
            publicId: 'p1',
            title: 'Saturday A',
            type: EventType.programme,
            rrule: 'FREQ=WEEKLY;BYDAY=SA',
          ),
          testPublicEvent(
            publicId: 'p2',
            title: 'Saturday B',
            type: EventType.programme,
            rrule: 'FREQ=WEEKLY;BYDAY=SA',
          ),
          testPublicEvent(
            publicId: 'p3',
            title: 'Sunday',
            type: EventType.programme,
            rrule: 'FREQ=WEEKLY;BYDAY=SU',
          ),
        ],
      );

      expect(_cardTitles(tester), ['Saturday A', 'Sunday']);
      expect(find.text('programsLandingTitle'), findsOneWidget);
    });

    testWidgets('Issue 53: no active one-off events, no section', (
      tester,
    ) async {
      await _pump(
        tester,
        const LandingEventsSection(type: EventType.oneOff),
        type: EventType.oneOff,
        events: [
          testPublicEvent(type: EventType.oneOff, isPast: true),
        ],
      );

      expect(find.byType(PublicEventCard), findsNothing);
      expect(find.text('oneOffLandingTitle'), findsNothing);
    });
  });
}
