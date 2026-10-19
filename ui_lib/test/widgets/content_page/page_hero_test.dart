import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/src/widgets/content_page/page_hero.dart';
import 'package:ui_lib/ui_lib.dart' show ContentPageHeroSection, PageHeroData;

const defaultHero = 'https://example.test/media/hero/download';

void main() {
  group("Issue 157: a content page's hero is ui_lib's", () {
    testWidgets('Issue 157: maps the page copy into the shared hero', (
      tester,
    ) async {
      late Widget built;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            built = const PageHero(
              data: PageHeroData(
                title: 'Rinks',
                badge: 'OUR ICE',
                description: 'Where we skate',
                imageUri: 'https://example.test/rink.webp',
              ),
              leftAlign: true,
              useStampBadge: true,
              icon: Icons.map,
            ).build(context);
            return const SizedBox.shrink();
          },
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

    testWidgets('Issue 157: passes the fallback image through', (
      tester,
    ) async {
      late Widget built;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            built = const PageHero(
              data: PageHeroData(title: 'Coaches'),
              fallbackImageUri: defaultHero,
            ).build(context);
            return const SizedBox.shrink();
          },
        ),
      );

      final hero = built as ContentPageHeroSection;
      expect(hero.imageUri, isNull);
      expect(hero.fallbackImageUri, defaultHero);
    });
  });
}
