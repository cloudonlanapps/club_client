import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/content_page_hero_background.dart';
import 'package:ui_lib/ui_lib.dart';

const headers = {'Authorization': 'Bearer abc'};

/// Builds [background] against a live context and returns what it produces,
/// without mounting it: [HighlightMediaOrchestrator] needs a ProviderScope,
/// which ui_lib (Riverpod-free) does not provide.
Future<Widget> buildOnce(
  WidgetTester tester,
  ContentPageHeroBackground background,
) async {
  late Widget built;
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        built = background.build(context);
        return const SizedBox.shrink();
      },
    ),
  );
  return built;
}

Future<void> pumpHero(WidgetTester tester, ContentPageHeroSection hero) {
  return tester.pumpWidget(
    ShadApp(
      home: Scaffold(body: SingleChildScrollView(child: hero)),
    ),
  );
}

void main() {
  group('Issue 53: ContentPageHeroSection background', () {
    testWidgets('Issue 53: without a page image the fallback shows', (
      tester,
    ) async {
      final built = await buildOnce(
        tester,
        const ContentPageHeroBackground(fallbackImageUri: 'assets/hero.webp'),
      );

      expect((built as HighlightMediaOrchestrator).uri, 'assets/hero.webp');
    });

    testWidgets('Issue 53: the page image wins over the fallback', (
      tester,
    ) async {
      final built = await buildOnce(
        tester,
        const ContentPageHeroBackground(
          imageUri: 'https://example.test/venue.webp',
          fallbackImageUri: 'assets/hero.webp',
        ),
      );

      expect(
        (built as HighlightMediaOrchestrator).uri,
        'https://example.test/venue.webp',
      );
    });

    testWidgets('Issue 53: the fallback is public, so it takes no headers', (
      tester,
    ) async {
      final built = await buildOnce(
        tester,
        const ContentPageHeroBackground(
          fallbackImageUri: 'assets/hero.webp',
          httpHeaders: headers,
        ),
      );

      expect(built, isA<HighlightMediaOrchestrator>());
    });

    testWidgets('Issue 53: a page image with headers loads with them', (
      tester,
    ) async {
      final built = await buildOnce(
        tester,
        const ContentPageHeroBackground(
          imageUri: 'https://example.test/venue.webp',
          httpHeaders: headers,
        ),
      );

      expect((built as CredentialedNetworkImage).httpHeaders, headers);
    });
  });

  group('Issue 53: ContentPageHeroSection', () {
    testWidgets(
      'Issue 53: with neither image nor fallback it renders nothing',
      (
        tester,
      ) async {
        await pumpHero(tester, const ContentPageHeroSection(title: 'Rinks'));

        expect(find.text('Rinks'), findsNothing);
      },
    );

    testWidgets('Issue 53: the description is selectable by default', (
      tester,
    ) async {
      await pumpHero(
        tester,
        const ContentPageHeroSection(
          title: 'Rinks',
          description: 'Where we skate',
          imageUri: 'https://example.test/venue.webp',
          httpHeaders: headers,
        ),
      );

      final markdown = tester.widget<ThemedMarkdown>(
        find.byType(ThemedMarkdown),
      );
      expect(markdown.selectable, isTrue);
    });

    testWidgets('Issue 53: selectable false renders plain text', (
      tester,
    ) async {
      await pumpHero(
        tester,
        const ContentPageHeroSection(
          title: 'Rinks',
          description: 'Where we skate',
          imageUri: 'https://example.test/venue.webp',
          httpHeaders: headers,
          selectable: false,
        ),
      );

      final markdown = tester.widget<ThemedMarkdown>(
        find.byType(ThemedMarkdown),
      );
      expect(markdown.selectable, isFalse);
    });
  });
}
