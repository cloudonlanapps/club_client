import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [EventMediaSource]: `listByTag` returns the seeded links for that tag
/// only (mirroring the server's per-tag endpoint), and `attach` records the
/// tag it was asked to write.
class _FakeEventMedia extends Fake implements EventMediaSource {
  _FakeEventMedia(this.byTag);

  final Map<String, List<MediaLink>> byTag;

  String? attachedTag;
  String? attachedUuid;

  @override
  Future<List<MediaLink>> listByTag(int ownerId, String tag) async =>
      byTag[tag] ?? const [];

  @override
  Future<MediaLink> attach(
    int ownerId, {
    required String tag,
    required String mediaUuid,
    String? metadata,
  }) async {
    attachedTag = tag;
    attachedUuid = mediaUuid;
    return _link(mediaUuid, tag, 'image');
  }
}

MediaLink _link(String uuid, String tag, String mediaType, {int day = 1}) =>
    MediaLink(
      tag: tag,
      media: MediaRef(
        uuid: uuid,
        mimeType: switch (mediaType) {
          'image' => 'image/jpeg',
          'pdf' => 'application/pdf',
          _ => 'video/mp4',
        },
        filename: '$uuid-file',
      ),
      createdAtUtc: DateTime.utc(2026, 1, day),
      updatedAtUtc: DateTime.utc(2026, 1, day),
    );

SecureClient _buildClient(EventMediaSource eventMedia) => fakeSecureClient(
  eventMedia: eventMedia,
);

ProviderContainer _makeContainer(EventMediaSource eventMedia) {
  final container = ProviderContainer(
    overrides: [
      serverConfigProvider.overrideWithValue(
        const ServerConfig(baseUrl: 'https://api.example.com/v1'),
      ),
      secureClientProvider.overrideWith(
        (ref) async => _buildClient(eventMedia),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'Issue 679: eventGalleryProvider returns only event_gallery-tagged links, '
    'oldest first, each carrying its media kind and download URL',
    () async {
      final fake = _FakeEventMedia({
        kEventGalleryTag: [
          _link('vid', kEventGalleryTag, 'video', day: 3),
          _link('img', kEventGalleryTag, 'image', day: 1),
          _link('doc', kEventGalleryTag, 'pdf', day: 2),
        ],
        // A cover-tagged link must never leak into the gallery list.
        kEventCoverTag: [_link('cover', kEventCoverTag, 'image', day: 5)],
      });
      final container = _makeContainer(fake);

      final items = await container.read(eventGalleryProvider(42).future);

      expect(
        items.map((i) => i.mediaUuid).toList(),
        ['img', 'doc', 'vid'],
        reason: 'sorted oldest-first by createdAtUtc',
      );
      expect(items.map((i) => i.mediaType).toList(), ['image', 'pdf', 'video']);
      expect(
        items.first.url,
        'https://api.example.com/v1/media/by_id/img/download?variant=original',
      );
      expect(
        items.every((i) => i.mediaUuid != 'cover'),
        isTrue,
        reason: 'event_cover media is excluded from the gallery',
      );
    },
  );

  test(
    'Issue 679: attachGalleryMedia attaches under the event_gallery tag',
    () async {
      final fake = _FakeEventMedia({});
      final container = _makeContainer(fake);

      await container
          .read(eventMediaMutationProvider(7).notifier)
          .attachGalleryMedia('new-uuid');

      expect(fake.attachedTag, kEventGalleryTag);
      expect(fake.attachedUuid, 'new-uuid');
    },
  );
}
