import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_remote_store/cl_remote_store.dart' as store;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 19: the website media slots', () {
    test('Issue 19: the site renders the slots cl_remote_store names', () {
      expect(SiteMediaSlot.values, store.SiteMediaSlot.values);
    });

    test('Issue 19: each slot keeps its bundled default', () {
      expect(
        SiteMediaSlot.landingBackground.bundledAsset,
        'assets/media/landing_background.webp',
      );
      expect(
        SiteMediaSlot.pageHeroDefault.bundledAsset,
        'assets/media/page_hero_default.webp',
      );
      expect(SiteMediaSlot.logo.bundledAsset, 'assets/images/club_logo.png');
    });
  });
}
