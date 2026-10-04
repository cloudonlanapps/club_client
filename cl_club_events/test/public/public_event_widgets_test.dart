import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show StampBadge;

import 'support/public_events.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serverConfigProvider.overrideWithValue(
          const ServerConfig(baseUrl: testApiBase),
        ),
      ],
      child: ShadApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

final PublicEventView _camp = testEventView(
  testPublicEvent(
    description: 'Five days on the ice.',
    rrule: 'FREQ=DAILY;COUNT=5',
    marketing: const EventMarketingBasic(
      shortDescription: 'Learn to skate',
      stamp: 'New',
      highlights: ['Skating basics'],
    ),
  ),
  marketing: const EventMarketing(fee: 15000),
);

final PublicEventView _pastCamp = testEventView(
  testPublicEvent(
    publicId: 'pe-past',
    title: 'Winter Camp',
    isPast: true,
    gallery: [testPhoto('g1'), testPhoto('g2'), testPhoto('g3')],
  ),
);

final PublicEventView _programme = testEventView(
  testPublicEvent(
    publicId: 'pe-prog',
    title: 'Weekend Hockey',
    type: EventType.programme,
    rrule: 'FREQ=WEEKLY;BYDAY=SA',
    start: DateTime(2026, 5, 2, 7, 30),
    length: const Duration(minutes: 90),
    sessions: const [
      EventSession(name: 'Off-Ice Workout', periodMinutes: 30),
      EventSession(name: 'On-Ice', periodMinutes: 60),
    ],
    marketing: const EventMarketingBasic(highlights: ['Two coaches']),
  ),
  marketing: const EventMarketing(
    feeStructure: [
      FeeItem(name: 'Registration', amount: 1000),
      FeeItem(name: 'Monthly', amount: 2000, period: 'month'),
    ],
    facilities: [Facility(name: 'Changing rooms')],
  ),
);

void main() {
  group('Issue 53: the public event card', () {
    testWidgets('Issue 53: an open camp shows its status, facts and call to '
        'action', (tester) async {
      await _pump(tester, PublicEventCard(event: _camp));

      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('Registrations Open'), findsOneWidget);
      expect(find.text('Spring Camp'), findsOneWidget);
      expect(find.text('Learn to skate'), findsOneWidget);
      expect(find.text('4 - 8 May 2026'), findsOneWidget);
      expect(find.text('Riverside Rink'), findsOneWidget);
      expect(find.textContaining('Five days on the ice'), findsOneWidget);
      expect(find.text('15,000/-'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
    });

    testWidgets('Issue 53: a past event offers its gallery', (tester) async {
      await _pump(tester, PublicEventCard(event: _pastCamp));

      expect(find.text('Past'), findsOneWidget);
      expect(find.text('3 photos from the event'), findsOneWidget);
      expect(find.text('View Gallery'), findsOneWidget);
    });

    testWidgets('Issue 53: a programme lists what is included', (
      tester,
    ) async {
      await _pump(tester, PublicEventCard(event: _programme));

      expect(find.text("What's Included:"), findsOneWidget);
      expect(find.text('Two coaches'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
    });

    testWidgets('Issue 53: the teaser card hides its button and fees', (
      tester,
    ) async {
      await _pump(
        tester,
        PublicEventCard(
          event: _camp,
          showFees: false,
          showPrimaryButton: false,
        ),
      );

      expect(find.text('View Details'), findsNothing);
      expect(find.text('15,000/-'), findsNothing);
    });

    testWidgets('Issue 53: the compact card shows the date and photo count', (
      tester,
    ) async {
      await _pump(tester, PublicEventCompactCard(event: _pastCamp));

      expect(find.text('Past'), findsOneWidget);
      expect(find.text('Winter Camp'), findsOneWidget);
      expect(find.text('4 May 2026'), findsOneWidget);
      expect(find.text('3 photos'), findsOneWidget);
    });

    testWidgets('Issue 53: the list and grid hold one card per event', (
      tester,
    ) async {
      final tapped = <String>[];
      await _pump(
        tester,
        PublicEventCardList(
          events: [_camp, _programme],
          onEventTap: tapped.add,
        ),
      );
      expect(find.byType(PublicEventCard), findsNWidgets(2));
      await tester.tap(find.text('Weekend Hockey'));
      expect(tapped, ['pe-prog']);

      await _pump(
        tester,
        PublicEventCardGrid(events: [_pastCamp], onEventTap: tapped.add),
      );
      expect(find.byType(PublicEventCompactCard), findsOneWidget);
      await tester.tap(find.text('Winter Camp'));
      expect(tapped, ['pe-prog', 'pe-past']);
    });

    testWidgets('Issue 53: the card and its button call onTap', (
      tester,
    ) async {
      var taps = 0;
      await _pump(tester, PublicEventCard(event: _camp, onTap: () => taps++));

      await tester.tap(find.text('Spring Camp'));
      await tester.tap(find.text('View Details'));
      expect(taps, 2);
    });
  });

  group('Issue 53: the hero event card and info cards', () {
    testWidgets('Issue 53: the hero card shows the stamp, facts and button', (
      tester,
    ) async {
      var pressed = 0;
      await _pump(
        tester,
        PublicEventHeroCard(
          event: _camp,
          buttonText: 'Learn More',
          onButtonPressed: () => pressed++,
        ),
      );

      expect(find.byType(StampBadge), findsOneWidget);
      expect(find.text('Spring Camp'), findsOneWidget);
      expect(find.text('4 - 8 May 2026'), findsOneWidget);
      expect(find.text('Riverside Rink'), findsOneWidget);
      await tester.tap(find.text('Learn More'));
      expect(pressed, 1);
    });

    testWidgets('Issue 53: the info cards show dates, timings and venue', (
      tester,
    ) async {
      await _pump(
        tester,
        PublicEventInfoCards(event: _camp, labels: testDetailLabels.hero),
      );

      expect(find.text('DATES'), findsOneWidget);
      expect(find.text('4 - 8 May 2026'), findsOneWidget);
      expect(find.text('TIMINGS'), findsOneWidget);
      expect(find.text('10:00 AM - 12:00 PM'), findsOneWidget);
      expect(find.text('VENUE'), findsOneWidget);
      expect(find.text('Riverside Rink'), findsOneWidget);
    });

    testWidgets('Issue 53: the venue badge reports the venue public id', (
      tester,
    ) async {
      final tapped = <String>[];
      await _pump(
        tester,
        PublicEventDetailContent(
          event: _camp,
          labels: testDetailLabels,
          onVenueTap: tapped.add,
        ),
      );

      await tester.tap(find.text('Riverside Rink'));
      expect(tapped, [testVenue.publicId]);
    });
  });

  group('Issue 53: the public event detail content', () {
    testWidgets('Issue 53: a camp shows its highlights, coaches and fee', (
      tester,
    ) async {
      await _pump(
        tester,
        PublicEventDetailContent(event: _camp, labels: testDetailLabels),
      );

      expect(find.textContaining('Five days on the ice'), findsOneWidget);
      expect(find.text('DATES'), findsOneWidget);
      expect(find.text('What you will learn'), findsOneWidget);
      expect(find.text('Skating basics'), findsOneWidget);
      expect(find.text('~ Training By ~'), findsOneWidget);
      expect(find.text('Camp fee'), findsOneWidget);
      expect(find.text('15,000/-'), findsOneWidget);
    });

    testWidgets('Issue 53: a camp names its coaches', (tester) async {
      final coached = testEventView(
        testPublicEvent(
          coaches: const [
            PublicProfile(publicId: 'pc-1', displayName: 'Robin Frost'),
            PublicProfile(
              publicId: 'pc-2',
              displayName: 'Sam Vale',
              isGuest: true,
            ),
          ],
        ),
      );
      await _pump(
        tester,
        PublicEventDetailContent(event: coached, labels: testDetailLabels),
      );

      expect(find.text('Your coaches'), findsOneWidget);
      expect(find.text('Robin Frost'), findsOneWidget);
      expect(find.text('Sam Vale'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
    });

    testWidgets('Issue 53: a programme shows its timetable, facilities and '
        'fee table', (tester) async {
      await _pump(
        tester,
        PublicEventDetailContent(event: _programme, labels: testDetailLabels),
      );

      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Off-Ice Workout'), findsOneWidget);
      expect(find.text('7:30 AM - 8:00 AM'), findsOneWidget);
      expect(find.text('Facilities'), findsOneWidget);
      expect(find.text('Changing rooms'), findsOneWidget);
      expect(find.text('Fee structure'), findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget);
      expect(find.text('₹3,000'), findsOneWidget);
      expect(find.text('DATES'), findsNothing);
    });
  });
}
