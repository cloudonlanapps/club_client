import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

const _stored = ClubIdentity(
  name: 'Example Club',
  shortName: 'EXC',
  contact: ClubContactDetails(phoneNumber: '+10000000000'),
  extra: {
    'history': {'paragraphs': <String>[]},
  },
);

class _FakeAdmin extends Fake implements AdminSource {
  _FakeAdmin(this.identity);

  ClubIdentity identity;
  int reads = 0;
  final List<ClubIdentity> writes = [];
  ServerException? failWith;
  Exception? throwOnWrite;

  @override
  Future<ClubIdentity> getClubIdentity() async {
    reads++;
    return identity;
  }

  @override
  Future<ClubIdentity> setClubIdentity(ClubIdentity identity) async {
    final failure = failWith;
    if (failure != null) throw failure;
    final thrown = throwOnWrite;
    if (thrown != null) throw thrown;
    writes.add(identity);
    return this.identity = identity;
  }
}

UserInfo _user({bool superAdmin = true}) => UserInfo(
  username: 'viewer',
  displayName: 'viewer',
  status: UserStatus.active,
  isSuperAdmin: superAdmin,
  roles: const UserRoles(isAdmin: true),
);

ProviderContainer _container(_FakeAdmin admin, {bool superAdmin = true}) {
  final c = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(admin: admin),
      ),
      currentUserProvider.overrideWith((ref) => _user(superAdmin: superAdmin)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('Issue 20: ClClubIdentityMasterNotifier', () {
    test('Issue 20: a super-admin reads the club identity', () async {
      final admin = _FakeAdmin(_stored);
      final c = _container(admin);

      expect(await c.read(clClubIdentityMasterProvider.future), _stored);
      expect(admin.reads, 1);
    });

    test(
      'Issue 20: an admin who is not super-admin gets an empty identity, '
      'no call',
      () async {
        final admin = _FakeAdmin(_stored);
        final c = _container(admin, superAdmin: false);

        expect(
          await c.read(clClubIdentityMasterProvider.future),
          const ClubIdentity(),
        );
        expect(admin.reads, 0);
      },
    );

    test('Issue 20: save writes the whole identity and keeps what the '
        'server stored', () async {
      final admin = _FakeAdmin(_stored);
      final c = _container(admin);
      await c.read(clClubIdentityMasterProvider.future);
      final next = _stored.copyWith(inquiryEmail: () => 'desk@example.test');

      final saved = await c
          .read(clClubIdentityMasterProvider.notifier)
          .save(next);

      expect(admin.writes.single, next);
      expect(saved, next);
      expect(c.read(clClubIdentityMasterProvider).requireValue, next);
    });

    test(
      'Issue 20: a refused save rethrows and keeps the saved state',
      () async {
        final admin = _FakeAdmin(_stored)
          ..failWith = const ServerException(
            statusCode: 422,
            code: 'VALIDATION_ERROR',
            message: 'bad',
          );
        final c = _container(admin);
        await c.read(clClubIdentityMasterProvider.future);

        await expectLater(
          c
              .read(clClubIdentityMasterProvider.notifier)
              .save(const ClubIdentity(name: 'Other')),
          throwsA(isA<ServerException>()),
        );
        expect(c.read(clClubIdentityMasterProvider).requireValue, _stored);
      },
    );
  });

  group('Issue 138: a club identity save that may have landed', () {
    test(
      'Issue 138: a timed-out save rethrows and re-reads the identity',
      () async {
        final admin = _FakeAdmin(_stored);
        final c = _container(admin);
        await c.read(clClubIdentityMasterProvider.future);
        admin.throwOnWrite = TimeoutException('no answer');

        await expectLater(
          c.read(clClubIdentityMasterProvider.notifier).save(_stored),
          throwsA(isA<TimeoutException>()),
        );
        await c.read(clClubIdentityMasterProvider.future);

        expect(admin.reads, 2);
      },
    );

    test('Issue 138: a refused save does not re-read', () async {
      final admin = _FakeAdmin(_stored);
      final c = _container(admin);
      await c.read(clClubIdentityMasterProvider.future);
      admin.failWith = const ServerException(
        statusCode: 422,
        message: 'refused',
        code: 'INVALID_PREFERENCE_VALUE',
      );

      await expectLater(
        c.read(clClubIdentityMasterProvider.notifier).save(_stored),
        throwsA(isA<ServerException>()),
      );
      await c.read(clClubIdentityMasterProvider.future);

      expect(admin.reads, 1);
    });
  });
}
