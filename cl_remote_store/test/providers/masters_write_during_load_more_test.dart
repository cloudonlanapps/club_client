// A write made while its master is loading is in the master once the load
// ends (club_client#234). Each test holds the master's first listing back,
// writes, then lets the listing from before the write through.
import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

MediaLink _link(String uuid) => MediaLink(
  tag: kIdentityDocumentTag,
  media: MediaRef(uuid: uuid, mimeType: 'image/jpeg', filename: '$uuid.jpg'),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

Media _media(String uuid) => Media(
  id: 1,
  uuid: uuid,
  originalFilename: '$uuid.jpg',
  mediaType: 'image',
  mimeType: 'image/jpeg',
  originalMimeType: 'image/jpeg',
  filename: '$uuid.jpg',
  fileSize: 10,
  preserveOriginal: false,
  conversionStatus: 'completed',
  accessRoles: const ['self', 'admin'],
  isEncrypted: true,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

class _Media extends Fake implements MediaSource {
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
  }) async => _media('new-doc');
}

class _UserMedia extends Fake implements UserMediaSource {
  final gate = Completer<void>();

  @override
  Future<List<MediaLink>> listByTag(String username, String tag) async {
    await gate.future;
    return [_link('old-doc')];
  }

  @override
  Future<MediaLink> attach(
    String username, {
    required String tag,
    required String mediaUuid,
    String? metadata,
  }) async => _link(mediaUuid);
}

class _Broadcasts extends Fake implements BroadcastSource {
  final gate = Completer<void>();

  @override
  Future<PaginatedList<Broadcast>> listBroadcasts({
    int offset = 0,
    int limit = 20,
  }) async {
    await gate.future;
    return PaginatedList<Broadcast>(
      items: const [],
      total: 0,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<Broadcast> createBroadcast({
    required AudienceSelector audienceSelector,
    required Map<String, dynamic> payload,
    DateTime? expiresAtUtc,
    bool email = false,
    String? emailSubject,
    String? emailBody,
  }) async => Broadcast(
    id: 5,
    audienceSelector: audienceSelector,
    payload: payload,
    sentAtUtc: DateTime.utc(2026),
    status: BroadcastStatus.sent,
    recipientCount: 1,
  );
}

const _oldHero = MediaRef(
  uuid: 'uuid-old',
  mimeType: 'image/webp',
  filename: 'old.webp',
);
const _newHero = MediaRef(
  uuid: 'uuid-new',
  mimeType: 'image/webp',
  filename: 'new.webp',
);

class _Public extends Fake implements PublicSource {
  final gate = Completer<void>();

  @override
  Future<PublicClubInfo> getPublicClubInfo() async {
    await gate.future;
    return const PublicClubInfo(siteMedia: {'hero': _oldHero});
  }
}

class _Admin extends Fake implements AdminSource {
  @override
  Future<SystemPreference> setPreference(String key, Object? value) async =>
      SystemPreference(
        key: key,
        value: value,
        updatedAtUtc: DateTime.utc(2026),
      );
}

const _viewer = UserInfo(
  username: 'alice',
  displayName: 'alice',
  status: UserStatus.active,
  isSuperAdmin: true,
  roles: UserRoles(isAdmin: true),
);

ProviderContainer _container(SecureClient client) {
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWith((ref) => _viewer),
      secureClientProvider.overrideWith((ref) async => client),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Keeps [provider] alive and starts its first load.
ProviderSubscription<AsyncValue<T>> _startLoad<T>(
  ProviderContainer c,
  ProviderListenable<AsyncValue<T>> provider,
) {
  final sub = c.listen(provider, (_, _) {});
  addTearDown(sub.close);
  return sub;
}

/// Lets the held-back listing through and returns the master's value once
/// the load has landed.
Future<T> _landed<T>(
  ProviderSubscription<AsyncValue<T>> sub,
  Completer<void> gate,
) async {
  gate.complete();
  await pumpEventQueue();
  final value = sub.read();
  expect(value.isLoading, isFalse);
  return value.requireValue;
}

void main() {
  test('Issue 234: an identity document uploaded during the first load of '
      'the identity-documents master is in it once it loads', () async {
    final userMedia = _UserMedia();
    final c = _container(
      fakeSecureClient(media: _Media(), userMedia: userMedia),
    );
    final provider = clIdentityDocsMasterProvider('alice');
    final sub = _startLoad(c, provider);
    await pumpEventQueue();

    await c
        .read(provider.notifier)
        .upload(
          bytes: const [1],
          filename: 'id.jpg',
          contentType: 'image/jpeg',
        );
    final docs = await _landed(sub, userMedia.gate);

    expect(docs.map((l) => l.mediaUuid), ['old-doc', 'new-doc']);
  });

  test('Issue 234: a broadcast sent during the first load of the broadcasts '
      'master is in it once it loads', () async {
    final broadcasts = _Broadcasts();
    final c = _container(fakeSecureClient(broadcasts: broadcasts));
    final sub = _startLoad(c, clBroadcastsMasterProvider);
    await pumpEventQueue();

    await c.read(clBroadcastsMasterProvider.notifier).sendText('hello');

    expect((await _landed(sub, broadcasts.gate)).keys, [5]);
  });

  test('Issue 234: site media saved during the first load of the site-media '
      'master is in it once it loads', () async {
    final public = _Public();
    final c = _container(fakeSecureClient(public: public, admin: _Admin()));
    final sub = _startLoad(c, clSiteMediaMasterProvider);
    await pumpEventQueue();

    await c.read(clSiteMediaMasterProvider.notifier).save({
      'landing': _newHero,
    });

    expect(await _landed(sub, public.gate), {'landing': _newHero});
  });
}
