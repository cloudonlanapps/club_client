import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Records whether `upload` was asked to encrypt, and returns a stub [Media].
class _FakeMedia extends Fake implements MediaSource {
  bool? encryptArg;
  List<String>? accessRolesArg;

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
    encryptArg = encrypt;
    accessRolesArg = accessRoles;
    return Media(
      id: 1,
      uuid: 'uploaded-uuid',
      originalFilename: 'id.jpg',
      mediaType: 'image',
      mimeType: 'image/jpeg',
      originalMimeType: 'image/jpeg',
      filename: 'uploaded-id.jpg',
      fileSize: 1024,
      preserveOriginal: false,
      conversionStatus: 'completed',
      accessRoles: const ['self', 'admin'],
      isEncrypted: true,
      createdAtUtc: DateTime.utc(2026),
      updatedAtUtc: DateTime.utc(2026),
    );
  }
}

class _FakeUserMedia extends Fake implements UserMediaSource {
  @override
  Future<List<MediaLink>> listByTag(String username, String tag) async =>
      const [];

  @override
  Future<MediaLink> attach(
    String username, {
    required String tag,
    required String mediaUuid,
    String? metadata,
  }) async => MediaLink(
    tag: tag,
    media: MediaRef(
      uuid: mediaUuid,
      mimeType: 'image/jpeg',
      filename: '$mediaUuid-doc.jpg',
    ),
    createdAtUtc: DateTime.utc(2026, 1, 1),
    updatedAtUtc: DateTime.utc(2026, 1, 1),
  );
}

SecureClient _buildClient(MediaSource media, UserMediaSource userMedia) =>
    fakeSecureClient(
      media: media,
      userMedia: userMedia,
    );

ProviderContainer _makeContainer(MediaSource media, UserMediaSource userMedia) {
  final container = ProviderContainer(
    overrides: [
      serverConfigProvider.overrideWithValue(
        const ServerConfig(baseUrl: 'https://api.example.com/v1'),
      ),
      // Null current user → the master's build() short-circuits to const [];
      // we only exercise the upload() mutation here.
      currentUserProvider.overrideWithValue(null),
      secureClientProvider.overrideWith(
        (ref) async => _buildClient(media, userMedia),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'Issue 754: identity-document upload requests server-side encryption '
    '(encrypt: true) and keeps the self/admin access roles',
    () async {
      final media = _FakeMedia();
      final container = _makeContainer(media, _FakeUserMedia());

      final link = await container
          .read(clIdentityDocsMasterProvider('skater').notifier)
          .upload(
            bytes: [1, 2, 3],
            filename: 'id.jpg',
            contentType: 'image/jpeg',
          );

      expect(
        media.encryptArg,
        isTrue,
        reason: 'identity docs must encrypt at rest',
      );
      expect(media.accessRolesArg, kIdentityDocumentAccessRoles);
      expect(link.tag, kIdentityDocumentTag);
      expect(link.mediaUuid, 'uploaded-uuid');
    },
  );
}
