import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

const _hero = MediaRef(
  uuid: 'uuid-hero',
  mimeType: 'image/webp',
  filename: 'hero.webp',
);
const _extra = MediaRef(
  uuid: 'uuid-extra',
  mimeType: 'image/webp',
  filename: 'extra.webp',
);

class _FakePublic extends Fake implements PublicSource {
  _FakePublic(this.siteMedia);
  final Map<String, MediaRef> siteMedia;
  int calls = 0;

  @override
  Future<PublicClubInfo> getPublicClubInfo() async {
    calls++;
    return PublicClubInfo(siteMedia: siteMedia);
  }
}

class _FakeAdmin extends Fake implements AdminSource {
  final List<(String, Object?)> writes = [];
  ServerException? failWith;

  @override
  Future<SystemPreference> setPreference(String key, Object? value) async {
    final failure = failWith;
    if (failure != null) throw failure;
    writes.add((key, value));
    return SystemPreference(
      key: key,
      value: value,
      updatedAtUtc: DateTime.utc(2026, 9, 28),
    );
  }
}

Media _media(
  int id, {
  String type = 'image',
  List<String> roles = const ['public'],
  bool deleted = false,
}) => Media(
  id: id,
  uuid: 'uuid-$id',
  originalFilename: 'file$id',
  mediaType: type,
  mimeType: type == 'image'
      ? 'image/webp'
      : type == 'video'
      ? 'video/mp4'
      : 'application/pdf',
  originalMimeType: 'image/png',
  filename: 'file$id',
  fileSize: 10,
  preserveOriginal: false,
  conversionStatus: 'completed',
  accessRoles: roles,
  isEncrypted: false,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  deletedAtUtc: deleted ? DateTime.utc(2026, 2) : null,
);

class _FakeMedia extends Fake implements MediaSource {
  _FakeMedia([this.library = const []]);
  final List<Media> library;
  final List<List<String>?> uploadRoles = [];

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
  }) async {
    uploadRoles.add(accessRoles);
    return _media(99);
  }

  @override
  Future<PaginatedList<Media>> list({
    int offset = 0,
    int limit = 20,
    String? mediaType,
    String? conversionStatus,
    bool includeDeleted = false,
  }) async => PaginatedList<Media>(
    items: library,
    total: library.length,
    limit: limit,
    offset: offset,
  );
}

UserInfo _user({bool superAdmin = true}) => UserInfo(
  username: 'viewer',
  displayName: 'viewer',
  status: UserStatus.active,
  isSuperAdmin: superAdmin,
  roles: const UserRoles(isAdmin: true),
);

ProviderContainer _container({
  PublicSource? public,
  AdminSource? admin,
  MediaSource? media,
  bool superAdmin = true,
}) {
  final c = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async =>
            fakeSecureClient(public: public, admin: admin, media: media),
      ),
      currentUserProvider.overrideWith((ref) => _user(superAdmin: superAdmin)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('Issue 19: SiteMediaSlot', () {
    test('Issue 19: the website slots and their server keys', () {
      expect(SiteMediaSlot.values.map((s) => s.serverKey), [
        'landing_background',
        'page_hero_default',
        'logo',
      ]);
      expect(SiteMediaSlot.fromServerKey('logo'), SiteMediaSlot.logo);
      expect(SiteMediaSlot.fromServerKey('page_hero.about'), isNull);
    });
  });

  group('Issue 19: ClSiteMediaMasterNotifier', () {
    test(
      'Issue 19: a super-admin reads the slots from the club info',
      () async {
        final public = _FakePublic({'page_hero_default': _hero});
        final c = _container(public: public);

        final slots = await c.read(clSiteMediaMasterProvider.future);

        expect(slots, {'page_hero_default': _hero});
      },
    );

    test(
      'Issue 19: an admin who is not super-admin gets nothing, no call',
      () async {
        final public = _FakePublic({'logo': _hero});
        final c = _container(public: public, superAdmin: false);

        expect(await c.read(clSiteMediaMasterProvider.future), isEmpty);
        expect(public.calls, 0);
      },
    );

    test('Issue 19: save writes the whole map of uuids, keys it does not '
        'know included', () async {
      final admin = _FakeAdmin();
      final c = _container(
        public: _FakePublic({'page_hero.about': _extra}),
        admin: admin,
      );
      await c.read(clSiteMediaMasterProvider.future);

      await c.read(clSiteMediaMasterProvider.notifier).save({
        'page_hero.about': _extra,
        'logo': _hero,
      });

      expect(admin.writes.single.$1, 'site_media');
      expect(admin.writes.single.$2, {
        'page_hero.about': 'uuid-extra',
        'logo': 'uuid-hero',
      });
      expect(c.read(clSiteMediaMasterProvider).requireValue, {
        'page_hero.about': _extra,
        'logo': _hero,
      });
    });

    test(
      'Issue 19: a refused save rethrows and keeps the saved state',
      () async {
        final admin = _FakeAdmin()
          ..failWith = const ServerException(
            statusCode: 422,
            code: 'SITE_MEDIA_NOT_PUBLIC',
            message: 'not public',
          );
        final c = _container(
          public: _FakePublic({'logo': _hero}),
          admin: admin,
        );
        await c.read(clSiteMediaMasterProvider.future);

        await expectLater(
          c.read(clSiteMediaMasterProvider.notifier).save({'logo': _extra}),
          throwsA(isA<ServerException>()),
        );
        expect(c.read(clSiteMediaMasterProvider).requireValue, {'logo': _hero});
      },
    );

    test('Issue 19: uploadPublic uploads for anonymous viewing', () async {
      final media = _FakeMedia();
      final c = _container(public: _FakePublic(const {}), media: media);

      final ref = await c
          .read(clSiteMediaMasterProvider.notifier)
          .uploadPublic(
            bytes: const [1, 2, 3],
            filename: 'hero.png',
            contentType: 'image/png',
          );

      expect(media.uploadRoles.single, ['public']);
      expect(ref.uuid, 'uuid-99');
      expect(ref.mimeType, 'image/webp');
    });
  });

  group('Issue 19: clMediaLibraryProvider', () {
    test('Issue 19: lists live images and videos for a super-admin', () async {
      final c = _container(
        media: _FakeMedia([
          _media(1),
          _media(2, type: 'video', roles: const ['admin']),
          _media(3, type: 'pdf'),
          _media(4, deleted: true),
        ]),
      );
      final sub = c.listen(clMediaLibraryProvider, (_, _) {});
      addTearDown(sub.close);

      final items = await c.read(clMediaLibraryProvider.future);

      expect(items.map((m) => m.id), [1, 2]);
    });

    test('Issue 19: empty for anyone but a super-admin', () async {
      final c = _container(media: _FakeMedia([_media(1)]), superAdmin: false);
      final sub = c.listen(clMediaLibraryProvider, (_, _) {});
      addTearDown(sub.close);

      expect(await c.read(clMediaLibraryProvider.future), isEmpty);
    });
  });
}
