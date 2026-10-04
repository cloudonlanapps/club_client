import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_public_source.dart';

const _fallback = ClubInfo(
  history: ClubHistoryData(paragraphs: ['Bundled history.']),
  values: [
    ClubValueCardData(iconName: 'target', title: 'Bundled', description: ''),
  ],
);

const _image = MediaRef(
  uuid: 'img',
  mimeType: 'image/webp',
  filename: 'hero.webp',
);
const _video = MediaRef(
  uuid: 'vid',
  mimeType: 'video/mp4',
  filename: 'hero.mp4',
);
const _pdf = MediaRef(
  uuid: 'doc',
  mimeType: 'application/pdf',
  filename: 'hero.pdf',
);

/// Resolves the club info, then keeps it watched while [read] runs.
Future<T> _withClubInfo<T>(
  PublicClubInfo info,
  T Function(ProviderContainer container) read,
) async {
  final source = FakePublicSource()..clubInfo = info;
  final container = publicContainer(source);
  final sub = container.listen(clPublicClubInfoProvider, (_, _) {});
  addTearDown(sub.close);
  await container.read(clPublicClubInfoProvider.future);
  return read(container);
}

void main() {
  group('Issue 53: the public club info', () {
    test(
      'Issue 53: clPublicClubInfoProvider reads the public document',
      () async {
        final info = await _withClubInfo(
          const PublicClubInfo(clubInfo: {'name': 'A Club'}),
          (c) => c.read(clPublicClubInfoProvider).requireValue,
        );
        expect(info.identity.name, 'A Club');
      },
    );
  });

  group('Issue 53: the club content (history and values)', () {
    test('Issue 53: falls back whole until the server answers', () {
      final source = FakePublicSource();
      final container = publicContainer(source);
      expect(
        container.read(clPublicClubContentProvider(_fallback)),
        _fallback,
      );
    });

    test("Issue 53: takes the server's history and values", () async {
      final content = await _withClubInfo(
        const PublicClubInfo(
          clubInfo: {
            'history': {
              'paragraphs': ['One.', '', 'Two.'],
            },
            'values': [
              {'title': 'Grit', 'description': 'Always'},
              {'title': 'Joy', 'iconName': 'star'},
              {'no': 'title'},
            ],
          },
        ),
        (c) => c.read(clPublicClubContentProvider(_fallback)),
      );

      expect(content.history.paragraphs, ['One.', 'Two.']);
      expect(content.values.map((v) => v.title), ['Grit', 'Joy']);
      expect(content.values.first.iconName, defaultClubValueIconName);
      expect(content.values.last.iconName, 'star');
      expect(content.values.last.description, '');
    });

    test('Issue 53: an unusable part falls back on its own', () async {
      final content = await _withClubInfo(
        const PublicClubInfo(
          clubInfo: {
            'history': 'not a map',
            'values': [
              {'title': 'Grit'},
            ],
          },
        ),
        (c) => c.read(clPublicClubContentProvider(_fallback)),
      );

      expect(content.history, _fallback.history);
      expect(content.values.single.title, 'Grit');
    });
  });

  group('Issue 53: the public site media slots', () {
    test(
      'Issue 53: null until the server answers, and for an unset slot',
      () async {
        final source = FakePublicSource();
        final container = publicContainer(source);
        expect(
          container.read(clPublicSiteMediaProvider(SiteMediaSlot.logo)),
          isNull,
        );

        final unset = await _withClubInfo(
          const PublicClubInfo(),
          (c) => c.read(clPublicSiteMediaProvider(SiteMediaSlot.logo)),
        );
        expect(unset, isNull);
      },
    );

    test("Issue 53: an image slot is the admin's upload", () async {
      final asset = await _withClubInfo(
        const PublicClubInfo(siteMedia: {'page_hero_default': _image}),
        (c) => c.read(clPublicSiteMediaProvider(SiteMediaSlot.pageHeroDefault)),
      );

      expect(asset, isNotNull);
      expect(
        asset!.uri,
        '$testApiBase/media/by_id/img/download/hero.webp',
      );
      expect(asset.isVideo, isFalse);
      expect(asset.previewUri, isNull);
    });

    test('Issue 53: a video slot carries its animated preview', () async {
      final asset = await _withClubInfo(
        const PublicClubInfo(siteMedia: {'landing_background': _video}),
        (c) =>
            c.read(clPublicSiteMediaProvider(SiteMediaSlot.landingBackground)),
      );

      expect(asset!.isVideo, isTrue);
      expect(
        asset.previewUri,
        '$testApiBase/media/by_id/vid/download?variant=animated',
      );
    });

    test('Issue 53: a slot holding neither image nor video is unset', () async {
      final asset = await _withClubInfo(
        const PublicClubInfo(siteMedia: {'logo': _pdf}),
        (c) => c.read(clPublicSiteMediaProvider(SiteMediaSlot.logo)),
      );
      expect(asset, isNull);
    });
  });

  group('Issue 53: public media URLs', () {
    test('Issue 53: clPublicMediaUrlProvider binds the API base', () {
      final container = publicContainer(FakePublicSource());
      final urls = container.read(clPublicMediaUrlProvider);

      expect(urls(null), isNull);
      expect(urls(_image), '$testApiBase/media/by_id/img/download/hero.webp');
      expect(urls.preview(_image), isNull);
      expect(
        urls.preview(_video),
        '$testApiBase/media/by_id/vid/download?variant=poster',
      );
      expect(
        urls.animated(_video),
        '$testApiBase/media/by_id/vid/download?variant=animated',
      );
      expect(urls.animated(_image), isNull);
    });
  });
}
