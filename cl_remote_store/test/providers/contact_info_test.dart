import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_public_source.dart';
import '../support/fake_secure_client.dart';

const _bundled = ContactInfo(
  clubName: 'Bundled Club',
  phoneNumber: '+10000000000',
  email: 'bundled@example.test',
  city: LocalizedText('Bundled City'),
);

const _serverInfo = PublicClubInfo(
  clubInfo: {
    'name': 'Server Club',
    'contact': {'phoneNumber': '+10000000009'},
  },
);

class _FakeAdmin extends Fake implements AdminSource {
  _FakeAdmin(this.onWrite);

  final void Function(ClubIdentity identity) onWrite;

  @override
  Future<ClubIdentity> setClubIdentity(ClubIdentity identity) async {
    onWrite(identity);
    return identity;
  }
}

ProviderContainer _container(
  FakePublicSource source, {
  List<Override> overrides = const [],
}) => publicContainer(
  source,
  overrides: [
    bundledContactInfoProvider.overrideWithValue(_bundled),
    ...overrides,
  ],
);

/// Holds [contactInfoProvider] and lets the public read settle.
Future<void> _settle(ProviderContainer container) async {
  container.listen(contactInfoProvider, (_, _) {});
  try {
    await container.read(clPublicClubInfoProvider.future);
  } on Object {
    // A failed read is a case under test.
  }
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('Issue 53: contactInfoProvider', () {
    test('Issue 53: the bundled block before the server answers', () {
      final source = FakePublicSource()..clubInfo = _serverInfo;
      final container = _container(source);

      expect(container.read(contactInfoProvider), _bundled);
    });

    test('Issue 53: prefers the server, field by field', () async {
      final source = FakePublicSource()..clubInfo = _serverInfo;
      final container = _container(source);
      await _settle(container);

      final contact = container.read(contactInfoProvider);
      expect(contact.clubName, 'Server Club');
      expect(contact.phoneNumber, '+10000000009');
      expect(contact.email, _bundled.email);
      expect(contact.city, _bundled.city);
    });

    test('Issue 53: the bundled block when the server fails', () async {
      final source = FakePublicSource()..failWith = Exception('server down');
      final container = _container(source);
      await _settle(container);

      expect(container.read(contactInfoProvider), _bundled);
    });

    test('Issue 53: the bundled block when the server has none', () async {
      final container = _container(FakePublicSource());
      await _settle(container);

      expect(container.read(contactInfoProvider), _bundled);
    });

    test(
      'Issue 53: a saved club identity reaches contactInfoProvider',
      () async {
        final source = FakePublicSource()..clubInfo = _serverInfo;
        final admin = _FakeAdmin((identity) {
          source.clubInfo = PublicClubInfo(clubInfo: identity.toMap());
        });
        final container = _container(
          source,
          overrides: [
            secureClientProvider.overrideWith(
              (ref) async => fakeSecureClient(admin: admin),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
        );
        await _settle(container);
        expect(container.read(contactInfoProvider).phoneNumber, '+10000000009');

        await container
            .read(clClubIdentityMasterProvider.notifier)
            .save(
              const ClubIdentity(
                name: 'Server Club',
                contact: ClubContactDetails(phoneNumber: '+10000000077'),
              ),
            );
        await container.read(clPublicClubInfoProvider.future);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(contactInfoProvider).phoneNumber, '+10000000077');
      },
    );
  });
}
