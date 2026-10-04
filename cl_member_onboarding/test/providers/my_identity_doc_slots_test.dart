import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_onboarding/src/providers/my_identity_doc_slots.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubAuth extends AuthNotifier {
  _StubAuth(this._user);
  final UserPrivate _user;

  @override
  Future<UserPrivate?> build() async => _user;
}

class _FakeIdentityDocsNotifier extends ClIdentityDocsMasterNotifier {
  _FakeIdentityDocsNotifier(this._initial);
  final List<MediaLink> _initial;

  @override
  Future<List<MediaLink>> build(String arg) async => _initial;
}

UserPrivate _user() => UserPrivate(
  username: 'u1',
  displayName: 'U One',
  status: UserStatus.registered,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
  email: 'u1@example.com',
);

MediaLink _link(String uuid) {
  final now = DateTime.utc(2024);
  return MediaLink(
    tag: kIdentityDocumentTag,
    media: MediaRef(
      uuid: uuid,
      mimeType: 'image/png',
      filename: '$uuid-doc.png',
    ),
    createdAtUtc: now,
    updatedAtUtc: now,
  );
}

const _baseUrl = 'https://api.test.example.com/v1';

ProviderContainer _container({List<MediaLink> links = const []}) {
  return ProviderContainer(
    overrides: [
      serverConfigProvider.overrideWithValue(
        const ServerConfig(baseUrl: _baseUrl),
      ),
      authStateProvider.overrideWith(() => _StubAuth(_user())),
      clIdentityDocsMasterProvider.overrideWith(
        () => _FakeIdentityDocsNotifier(links),
      ),
    ],
  );
}

void main() {
  group('Issue 573: clMyIdentityDocSlotsProvider URL + id mapping', () {
    test(
      'Issue 573: each MediaLink becomes a slot whose id is the mediaUuid '
      'and uri points at the v2 /media/by_id download endpoint',
      () async {
        final container = _container(
          links: [_link('uuid-1'), _link('uuid-2')],
        );
        addTearDown(container.dispose);

        await container.read(authStateProvider.future);
        await container.read(
          clIdentityDocsMasterProvider(_user().username).future,
        );

        final slots = container.read(clMyIdentityDocSlotsProvider).requireValue;
        expect(slots, hasLength(2));
        expect(slots[0].id, 'uuid-1');
        expect(
          slots[0].uri,
          '$_baseUrl/media/by_id/uuid-1/download?variant=original',
        );
        expect(slots[1].id, 'uuid-2');
        expect(
          slots[1].uri,
          '$_baseUrl/media/by_id/uuid-2/download?variant=original',
        );
        // Issue 90: the stored file name travels with the slot, so a
        // document that fails to load is still identifiable.
        expect(slots[0].fileName, 'uuid-1-doc.png');
        expect(slots[1].fileName, 'uuid-2-doc.png');
      },
    );

    test(
      'Issue 573: no logged-in user yields an empty slot list without '
      'touching the master',
      () async {
        final container = ProviderContainer(
          overrides: [
            serverConfigProvider.overrideWithValue(
              const ServerConfig(baseUrl: _baseUrl),
            ),
            authStateProvider.overrideWith(
              () => _StubAuthNullable(null),
            ),
          ],
        );
        addTearDown(container.dispose);

        final slots = container.read(clMyIdentityDocSlotsProvider);
        expect(slots.requireValue, isEmpty);
      },
    );
  });
}

class _StubAuthNullable extends AuthNotifier {
  _StubAuthNullable(this._user);
  final UserPrivate? _user;

  @override
  Future<UserPrivate?> build() async => _user;
}
