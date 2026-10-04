import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 53: the site reads its public data from cl_remote_store', () {
    test('Issue 53: a slot the server has not filled shows the bundled '
        'asset', () {
      const slot = SiteMediaSlot.landingBackground;
      expect(
        slot.bundledMedia,
        const SiteMediaAsset(
          uri: 'assets/media/landing_background.webp',
          isVideo: false,
          previewUri: 'assets/media/landing_background.webp',
        ),
      );
    });
  });
}
