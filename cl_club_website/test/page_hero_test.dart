import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_club_website/src/widgets/page_hero.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show SiteMediaAsset, clPublicSiteMediaProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show ContentPageHeroSection;

const defaultHero = 'https://example.test/media/hero/download';

/// Builds [hero] once against a live context and ref and returns what it
/// produces, without mounting the media it names.
Future<Widget> buildOnce(WidgetTester tester, PageHero hero) async {
  late Widget built;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clPublicSiteMediaProvider(
          SiteMediaSlot.pageHeroDefault,
        ).overrideWithValue(
          const SiteMediaAsset(
            uri: defaultHero,
            isVideo: false,
            previewUri: defaultHero,
          ),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          built = hero.build(context, ref);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return built;
}

void main() {
  group("Issue 53: the site's page hero is ui_lib's", () {
    testWidgets('Issue 53: maps the page copy into the shared hero', (
      tester,
    ) async {
      final built = await buildOnce(
        tester,
        const PageHero(
          data: PageHeroData(
            title: 'Rinks',
            badge: 'OUR ICE',
            description: 'Where we skate',
            imageUri: 'https://example.test/rink.webp',
          ),
          leftAlign: true,
          useStampBadge: true,
          icon: Icons.map,
        ),
      );

      final hero = built as ContentPageHeroSection;
      expect(hero.title, 'Rinks');
      expect(hero.badge, 'OUR ICE');
      expect(hero.description, 'Where we skate');
      expect(hero.imageUri, 'https://example.test/rink.webp');
      expect(hero.leftAlign, isTrue);
      expect(hero.useStampBadge, isTrue);
      expect(hero.icon, Icons.map);
      expect(hero.selectable, isFalse);
    });

    testWidgets('Issue 53: passes the default hero slot as the fallback', (
      tester,
    ) async {
      final built = await buildOnce(
        tester,
        const PageHero(data: PageHeroData(title: 'Coaches')),
      );

      final hero = built as ContentPageHeroSection;
      expect(hero.imageUri, isNull);
      expect(hero.fallbackImageUri, defaultHero);
    });
  });
}
