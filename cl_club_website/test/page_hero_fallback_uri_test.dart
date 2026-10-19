import 'package:cl_club_website/cl_club_website.dart'
    show SiteMediaSlotBundledAsset;
import 'package:cl_club_website/src/providers/page_hero_fallback_uri.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show SiteMediaAsset, SiteMediaSlot, clPublicSiteMediaProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const defaultHero = 'https://example.test/media/hero/download';

void main() {
  group("Issue 157: a page without an image takes the site's default hero", () {
    test("Issue 157: the server's default page hero", () {
      final container = ProviderContainer(
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
      );
      addTearDown(container.dispose);

      expect(container.read(pageHeroFallbackUriProvider), defaultHero);
    });

    test('Issue 157: the bundled one when the server has none', () {
      final container = ProviderContainer(
        overrides: [
          clPublicSiteMediaProvider(
            SiteMediaSlot.pageHeroDefault,
          ).overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(pageHeroFallbackUriProvider),
        SiteMediaSlot.pageHeroDefault.bundledAsset,
      );
    });
  });
}
