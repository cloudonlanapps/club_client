import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        PageCtaData,
        PageData,
        PageDataContent,
        PageEmptyStateData,
        PageHeroData;

import 'support/public_events.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 4000);
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

/// The copy the website would give [event]: its stamp, title and short
/// description in the hero, and a CTA.
EventDetailPageData _copy(PublicEventView event) => EventDetailPageData(
  pageData: PageData(
    hero: PageHeroData(
      title: event.title,
      badge: event.stamp,
      description: event.tagline,
    ),
    emptyState: const PageEmptyStateData(
      iconName: 'calendar',
      title: 'empty',
      description: 'empty',
      buttonText: 'empty',
    ),
    cta: const PageCtaData(
      title: 'Join this camp',
      description: 'Places are open.',
      primaryButtonText: 'Register',
      primaryRoute: '/signup',
    ),
  ),
  labels: testDetailLabels,
);

void main() {
  group("Issue 157: PublicEventPage is the website's event page", () {
    final camp = testEventView(
      testPublicEvent(
        title: 'Summer camp',
        description: 'Five days on the ice.',
        marketing: const EventMarketingBasic(
          shortDescription: 'Learn to skate',
          stamp: 'NEW',
          highlights: ['Skating basics'],
        ),
      ),
    );

    testWidgets('Issue 157: the banner carries the stamp, title and short '
        'description, and the body the event', (tester) async {
      await _pump(
        tester,
        PublicEventPage(
          event: camp,
          copy: _copy(camp),
          heroFallbackImageUri: 'https://example.test/hero.webp',
        ),
      );

      final page = tester.widget<PageDataContent>(find.byType(PageDataContent));
      expect(page.pageData.hero.title, 'Summer camp');
      expect(page.pageData.hero.badge, 'NEW');
      expect(page.pageData.hero.description, 'Learn to skate');
      expect(page.heroFallbackImageUri, 'https://example.test/hero.webp');
      expect(page.heroUseStampBadge, isTrue);
      expect(page.heroLeftAlign, isFalse);
      expect(page.useActiveSectionWrapper, isFalse);
      final body = tester.widget<PublicEventDetailContent>(
        find.byType(PublicEventDetailContent),
      );
      expect(body.event, same(camp));
      expect(body.labels, testDetailLabels);
      expect(find.text('Skating basics'), findsOneWidget);
    });

    testWidgets('Issue 157: a programme banner is left-aligned', (
      tester,
    ) async {
      final programme = testEventView(
        testPublicEvent(
          type: EventType.programme,
          rrule: 'FREQ=WEEKLY;BYDAY=SA',
        ),
      );
      await _pump(
        tester,
        PublicEventPage(event: programme, copy: _copy(programme)),
      );

      final page = tester.widget<PageDataContent>(find.byType(PageDataContent));
      expect(page.heroLeftAlign, isTrue);
    });

    testWidgets('Issue 157: the CTA hands its route to onNavigate', (
      tester,
    ) async {
      final routes = <String>[];
      await _pump(
        tester,
        PublicEventPage(
          event: camp,
          copy: _copy(camp),
          onNavigate: routes.add,
        ),
      );

      await tester.tap(find.text('Register'));

      expect(routes, ['/signup']);
    });
  });
}
