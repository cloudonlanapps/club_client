import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Stateful fake [UserMediaSource]: holds a flat list of links for the one
/// user under test, mirroring the server's per-tag list/attach/detach
/// endpoints. `attach` stamps a later `createdAtUtc` than any seeded link so
/// the freshly attached avatar sorts as most-recent.
class _FakeUserMedia extends Fake implements UserMediaSource {
  _FakeUserMedia(this.links);

  final List<MediaLink> links;

  String? attachedTag;
  String? attachedUuid;
  final List<String> detached = [];

  @override
  Future<List<MediaLink>> listByTag(String ownerId, String tag) async =>
      links.where((l) => l.tag == tag).toList();

  @override
  Future<MediaLink> attach(
    String ownerId, {
    required String tag,
    required String mediaUuid,
    String? metadata,
  }) async {
    attachedTag = tag;
    attachedUuid = mediaUuid;
    final link = _link(mediaUuid, tag, 'image', day: 9);
    links.add(link);
    return link;
  }

  @override
  Future<void> detach(String ownerId, String tag, String mediaUuid) async {
    detached.add(mediaUuid);
    links.removeWhere((l) => l.tag == tag && l.mediaUuid == mediaUuid);
  }

  @override
  Future<void> detachTag(String ownerId, String tag) async {
    links.removeWhere((l) => l.tag == tag);
  }
}

/// Stateful fake [MediaSource]: `upload` mints a new [Media], `listMyFiles`
/// returns the current files (uuid → id resolution for soft-delete), and
/// `softDelete` records and removes by id.
class _FakeMedia extends Fake implements MediaSource {
  _FakeMedia(this.files);

  final List<Media> files;

  /// Files owned by someone other than the caller: absent from
  /// `listMyFiles`, present in the staff `list`.
  final List<Media> othersFiles = [];

  List<String>? uploadedAccessRoles;
  String? uploadedOwnerUsername;
  final List<int> softDeleted = [];
  final Map<int, List<String>> patched = {};

  @override
  Future<Media> upload({
    required List<int> fileBytes,
    required String filename,
    String? contentType,
    bool preserveOriginal = false,
    double? duration,
    double? start,
    List<String>? accessRoles,
    bool encrypt = false,
    String? ownerUsername,
  }) async {
    uploadedAccessRoles = accessRoles;
    uploadedOwnerUsername = ownerUsername;
    final media = _media(id: 200, uuid: 'new', accessRoles: accessRoles!);
    files.add(media);
    return media;
  }

  @override
  Future<PaginatedList<Media>> listMyFiles({
    int offset = 0,
    int limit = 50,
    String? mediaType,
    String? conversionStatus,
  }) async => PaginatedList<Media>(
    items: List.of(files),
    total: files.length,
    limit: limit,
    offset: offset,
  );

  @override
  Future<PaginatedList<Media>> list({
    int offset = 0,
    int limit = 50,
    String? mediaType,
    String? conversionStatus,
    bool includeDeleted = false,
  }) async {
    final all = [...files, ...othersFiles];
    return PaginatedList<Media>(
      items: all.skip(offset).take(limit).toList(),
      total: all.length,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<Media> patch(int id, {required List<String> accessRoles}) async {
    patched[id] = accessRoles;
    final index = files.indexWhere((m) => m.id == id);
    final updated = _media(
      id: id,
      uuid: files[index].uuid,
      accessRoles: accessRoles,
    );
    files[index] = updated;
    return updated;
  }

  @override
  Future<void> softDelete(int id) async {
    softDeleted.add(id);
    files.removeWhere((m) => m.id == id);
    othersFiles.removeWhere((m) => m.id == id);
  }
}

MediaLink _link(String uuid, String tag, String mediaType, {int day = 1}) =>
    MediaLink(
      tag: tag,
      media: MediaRef(
        uuid: uuid,
        mimeType: mediaType == 'image' ? 'image/jpeg' : 'video/mp4',
        filename: '$uuid-file',
      ),
      createdAtUtc: DateTime.utc(2026, 1, day),
      updatedAtUtc: DateTime.utc(2026, 1, day),
    );

Media _media({
  required int id,
  required String uuid,
  required List<String> accessRoles,
}) => Media(
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
  accessRoles: accessRoles,
  isEncrypted: false,
  createdAtUtc: DateTime.utc(2026, 1, 1),
  updatedAtUtc: DateTime.utc(2026, 1, 1),
);

SecureClient _buildClient({
  required MediaSource media,
  required UserMediaSource userMedia,
}) => fakeSecureClient(
  media: media,
  userMedia: userMedia,
);

ProviderContainer _makeContainer({
  required MediaSource media,
  required UserMediaSource userMedia,
}) {
  final container = ProviderContainer(
    overrides: [
      serverConfigProvider.overrideWithValue(
        const ServerConfig(baseUrl: 'https://api.example.com/v1'),
      ),
      secureClientProvider.overrideWith(
        (ref) async => _buildClient(media: media, userMedia: userMedia),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'Issue 710: avatarMutationProvider.upload uploads under user_avatar, '
    'soft-deletes the prior avatar, and avatarImageProvider then resolves '
    'to the new media download URL',
    () async {
      final prior = _link('old', kUserAvatarTag, 'image', day: 1);
      final userMedia = _FakeUserMedia([prior]);
      final media = _FakeMedia([
        _media(id: 100, uuid: 'old', accessRoles: const ['self']),
      ]);
      final container = _makeContainer(media: media, userMedia: userMedia);

      // Sanity: before the upload the avatar resolves to the prior media.
      expect(
        await container.read(avatarImageProvider('alice').future),
        'https://api.example.com/v1/media/by_id/old/download?variant=original',
      );

      await container
          .read(avatarMutationProvider('alice').notifier)
          .upload(
            bytes: const [1, 2, 3],
            filename: 'me.png',
            contentType: 'image/png',
            allowOthersToSee: true,
          );

      // New media attached under the avatar tag with the public role.
      expect(userMedia.attachedTag, kUserAvatarTag);
      expect(userMedia.attachedUuid, 'new');
      expect(media.uploadedAccessRoles, const ['public']);

      // Prior avatar detached then soft-deleted (link removed before delete
      // so the server's MEDIA_IN_USE guard isn't tripped).
      expect(userMedia.detached, const ['old']);
      expect(media.softDeleted, const [100]);

      // The provider was invalidated, so a fresh read reflects the new avatar.
      expect(
        await container.read(avatarImageProvider('alice').future),
        'https://api.example.com/v1/media/by_id/new/download?variant=original',
      );
    },
  );

  test(
    'Issue 710: upload with allowOthersToSee=false stores the restricted '
    'access roles',
    () async {
      final userMedia = _FakeUserMedia([]);
      final media = _FakeMedia([]);
      final container = _makeContainer(media: media, userMedia: userMedia);

      await container
          .read(avatarMutationProvider('alice').notifier)
          .upload(
            bytes: const [1],
            filename: 'me.png',
            contentType: 'image/png',
            allowOthersToSee: false,
          );

      expect(media.uploadedAccessRoles, const ['self', 'admin', 'coach']);
      // No prior avatar, so nothing was detached or soft-deleted.
      expect(userMedia.detached, isEmpty);
      expect(media.softDeleted, isEmpty);
    },
  );

  test(
    'Issue 710: avatarImageProvider returns null when the user has no '
    'avatar link',
    () async {
      final container = _makeContainer(
        media: _FakeMedia([]),
        userMedia: _FakeUserMedia([]),
      );

      expect(await container.read(avatarImageProvider('alice').future), isNull);
    },
  );

  test(
    "Issue 35: uploadOnBehalf uploads in the member's name, private, and "
    'soft-deletes the prior avatar the member owns',
    () async {
      final userMedia = _FakeUserMedia([
        _link('old', kUserAvatarTag, 'image'),
      ]);
      // The admin's own files do not include the member's prior avatar.
      final media = _FakeMedia([])
        ..othersFiles.add(
          _media(id: 100, uuid: 'old', accessRoles: const ['public']),
        );
      final container = _makeContainer(media: media, userMedia: userMedia);

      await container
          .read(avatarMutationProvider('alice').notifier)
          .uploadOnBehalf(
            bytes: const [1, 2, 3],
            filename: 'alice.png',
            contentType: 'image/png',
          );

      expect(media.uploadedOwnerUsername, 'alice');
      expect(media.uploadedAccessRoles, const ['self', 'admin', 'coach']);
      expect(userMedia.attachedTag, kUserAvatarTag);
      expect(userMedia.attachedUuid, 'new');
      expect(userMedia.detached, const ['old']);
      expect(media.softDeleted, const [100]);
    },
  );

  test(
    'Issue 35: uploadOnBehalf finds a prior avatar beyond the first page of '
    'the staff media listing',
    () async {
      final userMedia = _FakeUserMedia([
        _link('old', kUserAvatarTag, 'image'),
      ]);
      final media = _FakeMedia([]);
      for (var i = 0; i < 150; i++) {
        media.othersFiles.add(
          _media(id: 1000 + i, uuid: 'other-$i', accessRoles: const ['self']),
        );
      }
      media.othersFiles.add(
        _media(id: 100, uuid: 'old', accessRoles: const ['public']),
      );
      final container = _makeContainer(media: media, userMedia: userMedia);

      await container
          .read(avatarMutationProvider('alice').notifier)
          .uploadOnBehalf(
            bytes: const [1],
            filename: 'alice.png',
            contentType: 'image/png',
          );

      expect(media.softDeleted, const [100]);
    },
  );

  test(
    "Issue 35: the member's own upload names no owner",
    () async {
      final media = _FakeMedia([]);
      final container = _makeContainer(
        media: media,
        userMedia: _FakeUserMedia([]),
      );

      await container
          .read(avatarMutationProvider('alice').notifier)
          .upload(
            bytes: const [1],
            filename: 'me.png',
            contentType: 'image/png',
            allowOthersToSee: false,
          );

      expect(media.uploadedOwnerUsername, isNull);
    },
  );

  test(
    'Issue 35: setVisibility makes the current avatar public without a new '
    'upload, and private again',
    () async {
      final userMedia = _FakeUserMedia([
        _link('older', kUserAvatarTag, 'image'),
        _link('current', kUserAvatarTag, 'image', day: 5),
      ]);
      final media = _FakeMedia([
        _media(id: 100, uuid: 'older', accessRoles: const ['self']),
        _media(
          id: 101,
          uuid: 'current',
          accessRoles: const ['self', 'admin', 'coach'],
        ),
      ]);
      final container = _makeContainer(media: media, userMedia: userMedia);
      final notifier = container.read(avatarMutationProvider('alice').notifier);

      expect(
        await container.read(avatarVisibilityProvider('alice').future),
        isFalse,
      );

      await notifier.setVisibility(allowOthersToSee: true);

      expect(media.patched, {
        101: const ['public'],
      });
      expect(media.uploadedAccessRoles, isNull, reason: 'no upload');
      expect(userMedia.attachedUuid, isNull);
      expect(
        await container.read(avatarVisibilityProvider('alice').future),
        isTrue,
      );

      await notifier.setVisibility(allowOthersToSee: false);

      expect(media.patched[101], const ['self', 'admin', 'coach']);
      expect(
        await container.read(avatarVisibilityProvider('alice').future),
        isFalse,
      );
    },
  );

  test(
    'Issue 35: setVisibility fails when the user has no avatar',
    () async {
      final media = _FakeMedia([]);
      final container = _makeContainer(
        media: media,
        userMedia: _FakeUserMedia([]),
      );

      await expectLater(
        container
            .read(avatarMutationProvider('alice').notifier)
            .setVisibility(allowOthersToSee: true),
        throwsStateError,
      );
      expect(media.patched, isEmpty);
    },
  );
}
