import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [MediaSource] that does none of the provider's work: `getByUuid`
/// resolves a uuid among [readable], `listMyFiles` shows only [mine], and
/// `softDelete` records the id it was given.
class _FakeMedia extends Fake implements MediaSource {
  _FakeMedia({
    required this.readable,
    this.mine = const [],
    this.refusedDeletes = const {},
  });

  /// Every file the caller may read by its uuid.
  final List<Media> readable;

  /// The first page of the caller's own files.
  final List<Media> mine;

  /// Ids of files the caller may read and may not delete.
  final Set<int> refusedDeletes;

  final List<int> softDeleted = [];
  int listingCalls = 0;

  @override
  Future<Media> getByUuid(String uuid) async {
    for (final media in readable) {
      if (media.uuid == uuid) return media;
    }
    throw const ServerException(
      statusCode: 404,
      code: 'MEDIA_NOT_FOUND',
      message: 'Media not found',
    );
  }

  @override
  Future<PaginatedList<Media>> listMyFiles({
    int offset = 0,
    int limit = 50,
    String? mediaType,
    String? conversionStatus,
  }) async {
    listingCalls++;
    return PaginatedList<Media>(
      items: mine.take(limit).toList(),
      total: mine.length,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<PaginatedList<Media>> list({
    int offset = 0,
    int limit = 50,
    String? mediaType,
    String? conversionStatus,
    bool includeDeleted = false,
  }) async {
    listingCalls++;
    return PaginatedList<Media>(
      items: const [],
      total: 0,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<void> softDelete(int id) async {
    if (refusedDeletes.contains(id)) {
      throw const ServerException(
        statusCode: 403,
        code: 'FORBIDDEN',
        message: 'Not allowed',
      );
    }
    softDeleted.add(id);
  }
}

/// The links of one owner and the uuids detached from it.
class _Links {
  _Links(this.links);

  final List<MediaLink> links;
  final List<String> detached = [];

  List<MediaLink> byTag(String tag) =>
      links.where((l) => l.tag == tag).toList();

  void detach(String tag, String mediaUuid) {
    detached.add(mediaUuid);
    links.removeWhere((l) => l.tag == tag && l.mediaUuid == mediaUuid);
  }
}

class _FakeUserMedia extends Fake implements UserMediaSource {
  _FakeUserMedia(this.store);
  final _Links store;

  @override
  Future<List<MediaLink>> listByTag(String ownerId, String tag) async =>
      store.byTag(tag);

  @override
  Future<void> detach(String ownerId, String tag, String mediaUuid) async =>
      store.detach(tag, mediaUuid);
}

class _FakeEventMedia extends Fake implements EventMediaSource {
  _FakeEventMedia(this.store);
  final _Links store;

  @override
  Future<List<MediaLink>> listByTag(int ownerId, String tag) async =>
      store.byTag(tag);

  @override
  Future<void> detach(int ownerId, String tag, String mediaUuid) async =>
      store.detach(tag, mediaUuid);
}

class _FakeGroupMedia extends Fake implements GroupMediaSource {
  _FakeGroupMedia(this.store);
  final _Links store;

  @override
  Future<List<MediaLink>> listByTag(int ownerId, String tag) async =>
      store.byTag(tag);

  @override
  Future<void> detach(int ownerId, String tag, String mediaUuid) async =>
      store.detach(tag, mediaUuid);
}

class _FakeVenueMedia extends Fake implements VenueMediaSource {
  _FakeVenueMedia(this.store);
  final _Links store;

  @override
  Future<List<MediaLink>> listByTag(int ownerId, String tag) async =>
      store.byTag(tag);

  @override
  Future<void> detach(int ownerId, String tag, String mediaUuid) async =>
      store.detach(tag, mediaUuid);
}

MediaLink _link(String uuid, String tag) => MediaLink(
  tag: tag,
  media: MediaRef(
    uuid: uuid,
    mimeType: 'image/jpeg',
    filename: '$uuid-file',
  ),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

Media _media(int id, String uuid) => Media(
  id: id,
  uuid: uuid,
  originalFilename: '$uuid.png',
  mediaType: 'image',
  mimeType: 'image/webp',
  originalMimeType: 'image/png',
  filename: '$uuid-image.webp',
  fileSize: 1,
  preserveOriginal: false,
  conversionStatus: 'completed',
  accessRoles: const ['public'],
  isEncrypted: false,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

/// The caller's newest hundred files: the page the old code searched.
List<Media> _aFullPageOfOtherFiles() => [
  for (var i = 0; i < 100; i++) _media(1000 + i, 'newer-$i'),
];

/// A container whose client holds [media] and one links fake over [store].
ProviderContainer _container(_FakeMedia media, _Links store) {
  final container = ProviderContainer(
    overrides: [
      serverConfigProvider.overrideWithValue(
        const ServerConfig(baseUrl: 'https://api.example.com/v1'),
      ),
      currentUserProvider.overrideWithValue(null),
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(
          media: media,
          userMedia: _FakeUserMedia(store),
          eventMedia: _FakeEventMedia(store),
          groupMedia: _FakeGroupMedia(store),
          venueMedia: _FakeVenueMedia(store),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// One of the four removals of the issue, run against a container for the
/// file `uuid` linked under `tag`.
typedef _Removal = ({
  String name,
  String tag,
  Future<void> Function(ProviderContainer container, String uuid) run,
});

final List<_Removal> _removals = [
  (
    name: 'discarding an identity document',
    tag: kIdentityDocumentTag,
    run: (c, uuid) =>
        c.read(clIdentityDocsMasterProvider('member').notifier).discard(uuid),
  ),
  (
    name: 'removing an event gallery image',
    tag: kEventGalleryTag,
    run: (c, uuid) =>
        c.read(eventMediaMutationProvider(7).notifier).removeGalleryImage(uuid),
  ),
  (
    name: 'clearing an event cover',
    tag: kEventCoverTag,
    run: (c, _) => c.read(eventMediaMutationProvider(7).notifier).clearCover(),
  ),
  (
    name: 'clearing a group image',
    tag: kGroupImageTag,
    run: (c, _) => c.read(groupMediaMutationProvider(7).notifier).clearImage(),
  ),
  (
    name: 'clearing a venue image',
    tag: kVenueImageTag,
    run: (c, _) => c.read(venueMediaMutationProvider(7).notifier).clearImage(),
  ),
];

void main() {
  for (final removal in _removals) {
    test('Issue 105: ${removal.name} soft-deletes a file that is not among '
        "the caller's newest hundred, and reads no listing", () async {
      final store = _Links([_link('gone', removal.tag)]);
      final media = _FakeMedia(
        readable: [_media(42, 'gone')],
        mine: _aFullPageOfOtherFiles(),
      );
      final container = _container(media, store);

      await removal.run(container, 'gone');

      expect(store.detached, ['gone']);
      expect(media.softDeleted, [42]);
      expect(media.listingCalls, 0);
    });

    test('Issue 105: ${removal.name} soft-deletes a file someone else '
        'uploaded', () async {
      final store = _Links([_link('theirs', removal.tag)]);
      // Readable by its uuid, and in none of the caller's own files.
      final media = _FakeMedia(readable: [_media(77, 'theirs')]);
      final container = _container(media, store);

      await removal.run(container, 'theirs');

      expect(store.detached, ['theirs']);
      expect(media.softDeleted, [77]);
    });

    test('Issue 105: ${removal.name} leaves a file the caller may not read, '
        'and the link is still removed', () async {
      final store = _Links([_link('hidden', removal.tag)]);
      final media = _FakeMedia(readable: const []);
      final container = _container(media, store);

      await removal.run(container, 'hidden');

      expect(store.detached, ['hidden']);
      expect(store.links, isEmpty);
      expect(media.softDeleted, isEmpty);
    });

    test('Issue 105: ${removal.name} leaves a file the caller may not '
        'delete, and the link is still removed', () async {
      final store = _Links([_link('kept', removal.tag)]);
      final media = _FakeMedia(
        readable: [_media(55, 'kept')],
        refusedDeletes: const {55},
      );
      final container = _container(media, store);

      await removal.run(container, 'kept');

      expect(store.detached, ['kept']);
      expect(store.links, isEmpty);
      expect(media.softDeleted, isEmpty);
    });
  }
}
