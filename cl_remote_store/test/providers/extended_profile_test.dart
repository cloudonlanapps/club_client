import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

const _stored = ProfileOptions(
  positions: [
    ProfilePosition(
      value: 'Forward',
      label: {'en': 'Forward', 'mr': 'फॉरवर्ड'},
    ),
  ],
  languages: ['English', 'Marathi'],
);

class _FakeCapabilities extends Fake implements CapabilitiesSource {
  _FakeCapabilities({required this.extendedProfile});

  final bool extendedProfile;

  @override
  Future<Capabilities> getCapabilities() async =>
      Capabilities(extendedProfile: extendedProfile);
}

class _FakeUsers extends Fake implements UserSource {
  ProfileOptions options = _stored;
  int reads = 0;
  final List<ProfileOptions> writes = [];
  final List<Map<String, Object?>> updates = [];
  ServerException? failWith;

  @override
  Future<ProfileOptions> getProfileOptions() async {
    reads++;
    return options;
  }

  @override
  Future<ProfileOptions> setProfileOptions(ProfileOptions options) async {
    final failure = failWith;
    if (failure != null) throw failure;
    writes.add(options);
    return this.options = options;
  }

  @override
  Future<UserPrivate> updateUser(
    String username, {
    String? email,
    String? Function()? firstName,
    String? Function()? middleName,
    String? Function()? lastName,
    String? Function()? phone,
    DateTime? Function()? dateOfBirthUtc,
    String? Function()? bio,
    String? Function()? achievements,
    String? Function()? emergencyContact,
    String? Function()? medicalNotes,
    String? Function()? nickname,
    bool? useNamePublicly,
    Gender? Function()? gender,
    Address? Function()? address,
    bool? isPublicProfile,
    String? Function()? clubDistrict,
    String? Function()? preferredPosition,
    String? Function()? pastExperience,
    String? Function()? nationality,
    String? Function()? preferredLanguage,
    Guardian? Function()? guardian,
    DateTime? Function()? membershipDateUtc,
  }) async {
    updates.add({
      if (firstName != null) 'firstName': firstName(),
      if (phone != null) 'phone': phone(),
      if (clubDistrict != null) 'clubDistrict': clubDistrict(),
      if (preferredPosition != null) 'preferredPosition': preferredPosition(),
      if (pastExperience != null) 'pastExperience': pastExperience(),
      if (nationality != null) 'nationality': nationality(),
      if (preferredLanguage != null) 'preferredLanguage': preferredLanguage(),
      if (guardian != null) 'guardian': guardian(),
      if (membershipDateUtc != null) 'membershipDateUtc': membershipDateUtc(),
    });
    return UserPrivate(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: const UserRoles(),
      createdAtUtc: DateTime.utc(2026),
      clubDistrict: clubDistrict?.call(),
    );
  }
}

UserInfo _viewer() => const UserInfo(
  username: 'viewer',
  displayName: 'viewer',
  status: UserStatus.pending,
  isSuperAdmin: false,
  roles: UserRoles(),
);

ProviderContainer _container(
  _FakeUsers users, {
  bool extendedProfile = true,
  bool signedIn = true,
}) {
  final c = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(
          users: users,
          capabilities: _FakeCapabilities(extendedProfile: extendedProfile),
        ),
      ),
      currentUserProvider.overrideWith((ref) => signedIn ? _viewer() : null),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('Issue 320: extendedProfileProvider', () {
    test(
      'Issue 320: is null until the server answers, then its flag',
      () async {
        final c = _container(_FakeUsers());
        expect(c.read(extendedProfileProvider), isNull);
        await c.read(capabilitiesProvider.future);
        expect(c.read(extendedProfileProvider), isTrue);
      },
    );

    test('Issue 320: reports the extended profile off', () async {
      final c = _container(_FakeUsers(), extendedProfile: false);
      await c.read(capabilitiesProvider.future);
      expect(c.read(extendedProfileProvider), isFalse);
    });
  });

  group('Issue 320: profileOptionsProvider', () {
    test('Issue 320: reads the club options while the extended profile is '
        'on', () async {
      final users = _FakeUsers();
      final c = _container(users);
      await c.read(capabilitiesProvider.future);

      expect(await c.read(profileOptionsProvider.future), _stored);
      expect(users.reads, 1);
    });

    test('Issue 320: is empty, with no call, while the extended profile is '
        'off', () async {
      final users = _FakeUsers();
      final c = _container(users, extendedProfile: false);
      await c.read(capabilitiesProvider.future);

      expect(await c.read(profileOptionsProvider.future), isEmptyOptions);
      expect(users.reads, 0);
    });

    test(
      'Issue 320: is empty, with no call, when no one is signed in',
      () async {
        final users = _FakeUsers();
        final c = _container(users, signedIn: false);
        await c.read(capabilitiesProvider.future);

        expect(await c.read(profileOptionsProvider.future), isEmptyOptions);
        expect(users.reads, 0);
      },
    );

    test(
      'Issue 320: save writes the options and holds what was stored',
      () async {
        final users = _FakeUsers();
        final c = _container(users);
        await c.read(capabilitiesProvider.future);
        await c.read(profileOptionsProvider.future);

        const edited = ProfileOptions(languages: ['Tamil']);
        final stored = await c
            .read(profileOptionsProvider.notifier)
            .save(edited);

        expect(stored, edited);
        expect(users.writes, [edited]);
        expect(c.read(profileOptionsProvider).value, edited);
      },
    );

    test('Issue 320: a refused save is rethrown and the stored options '
        'kept', () async {
      final users = _FakeUsers()
        ..failWith = const ServerException(
          statusCode: 422,
          code: SdkErrorCode.validationError,
          message: 'bad',
        );
      final c = _container(users);
      await c.read(capabilitiesProvider.future);
      await c.read(profileOptionsProvider.future);

      await expectLater(
        c
            .read(profileOptionsProvider.notifier)
            .save(const ProfileOptions(languages: ['x'])),
        throwsA(isA<ServerException>()),
      );
      expect(c.read(profileOptionsProvider).value, _stored);
    });
  });

  group('Issue 320: ClUsersMasterNotifier.updateUser', () {
    test(
      'Issue 320: sends the extended fields it is given and no other',
      () async {
        final users = _FakeUsers();
        final c = _container(users);
        await c.read(clUsersMasterProvider.future);

        final updated = await c
            .read(clUsersMasterProvider.notifier)
            .updateUser(
              'viewer',
              clubDistrict: () => 'Pune',
              preferredPosition: () => 'Forward',
              pastExperience: () => null,
              guardian: () => const Guardian(name: 'Asha'),
              membershipDateUtc: () => DateTime.utc(2026, 4),
            );

        expect(users.updates.single, {
          'clubDistrict': 'Pune',
          'preferredPosition': 'Forward',
          'pastExperience': null,
          'guardian': const Guardian(name: 'Asha'),
          'membershipDateUtc': DateTime.utc(2026, 4),
        });
        expect(updated.clubDistrict, 'Pune');
      },
    );
  });
}

/// Matches profile options with no position and no language.
final Matcher isEmptyOptions = predicate<ProfileOptions>(
  (o) => o.isEmpty,
  'empty profile options',
);
