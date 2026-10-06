import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_credit_sources.dart';
import '../support/fake_secure_client.dart';

/// More master writes that reload what they touch after a failure that may
/// have landed (club_core#138): credit, broadcasts, group membership, a
/// member's own enrollment, media and occurrences.

const _serverError = ServerException(
  statusCode: 500,
  code: 'INTERNAL_ERROR',
  message: 'boom',
);

final _timeout = TimeoutException('write timed out');

UserInfo _admin() => const UserInfo(
  username: 'uwm_admin',
  displayName: 'uwm_admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: true),
);

ProviderContainer _container(SecureClient client) {
  final c = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith((ref) async => client),
      currentUserProvider.overrideWith((ref) => _admin()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Keeps [provider] alive for the test, as a watching screen would.
void _hold(ProviderContainer c, ProviderListenable<Object?> provider) {
  final sub = c.listen(provider, (_, _) {});
  addTearDown(sub.close);
}

class _FailingCredits extends FakeCredits {
  _FailingCredits(super.store);

  @override
  Future<CreditTransferResult> transfer(
    String accountId, {
    required int penalty,
    required DateTime validFromUtc,
    required DateTime validUntilUtc,
    required String reason,
  }) async => throw _serverError;
}

class _Broadcasts extends Fake implements BroadcastSource {
  int listCalls = 0;

  @override
  Future<PaginatedList<Broadcast>> listBroadcasts({
    int offset = 0,
    int limit = 20,
  }) async {
    listCalls++;
    return const PaginatedList(items: [], total: 0, offset: 0, limit: 20);
  }

  @override
  Future<Broadcast> revokeBroadcast(int id) async => throw _timeout;
}

class _Groups extends Fake implements GroupSource {
  int membersCalls = 0;

  @override
  Future<List<GroupMember>> getMembers(
    int groupId, {
    String? sortBy,
    bool descending = false,
  }) async {
    membersCalls++;
    return const [];
  }

  @override
  Future<void> addMember(int groupId, String username) async => throw _timeout;
}

class _MyEvents extends Fake implements MyEventsSource {
  int getCalls = 0;

  @override
  Future<Enrollment> getMyEnrollment(String username, int eventId) async {
    getCalls++;
    return Enrollment(
      id: 1,
      membername: username,
      eventId: eventId,
      status: EnrollmentStatus.assigned,
      createdAtUtc: DateTime.utc(2026),
    );
  }

  @override
  Future<void> withdraw(
    String username,
    int eventId, {
    String? reason,
  }) async => throw _timeout;
}

class _VenueMedia extends Fake implements VenueMediaSource {
  int listCalls = 0;

  @override
  Future<List<MediaLink>> listByTag(int ownerId, String tag) async {
    listCalls++;
    return const [];
  }
}

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
  }) async => throw _timeout;
}

class _Occurrences extends Fake implements OccurrenceSource {
  @override
  Future<void> cancelOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
    required String reason,
  }) async => throw _serverError;
}

void main() {
  group('Issue 138: more writes reload after an uncertain failure', () {
    test('Issue 138: a credit transfer failing with 500 reloads the '
        'credit views', () async {
      final myCredits = FakeMyCredits();
      final c = _container(
        fakeSecureClient(
          capabilities: FakeCapabilities(),
          myCredits: myCredits,
          credits: _FailingCredits(myCredits),
        ),
      );
      final provider = clCreditAccountsMasterProvider('uwm_member');
      _hold(c, provider);
      await c.read(provider.future);
      final before = c.read(clResourceVersionProvider).creditsVersion;

      await expectLater(
        c
            .read(provider.notifier)
            .transfer(
              'ACC1',
              penalty: 0,
              validFromUtc: DateTime.utc(2026),
              validUntilUtc: DateTime.utc(2027),
              reason: 'uwm',
            ),
        throwsA(same(_serverError)),
      );
      expect(
        c.read(clResourceVersionProvider).creditsVersion,
        greaterThan(before),
      );
    });

    test('Issue 138: a revoke timing out reloads the broadcasts', () async {
      final broadcasts = _Broadcasts();
      final c = _container(fakeSecureClient(broadcasts: broadcasts));
      await c.read(clBroadcastsMasterProvider.future);

      await expectLater(
        c.read(clBroadcastsMasterProvider.notifier).revoke(3),
        throwsA(same(_timeout)),
      );
      await c.read(clBroadcastsMasterProvider.future);
      expect(broadcasts.listCalls, 2);
    });

    test(
      'Issue 138: adding a member that times out reloads the members',
      () async {
        final groups = _Groups();
        final c = _container(fakeSecureClient(groups: groups));
        _hold(c, clGroupMembersProvider(5));
        await c.read(clGroupMembersProvider(5).future);

        await expectLater(
          c.read(clGroupsMasterProvider.notifier).addMember(5, 'uwm_member'),
          throwsA(same(_timeout)),
        );
        await c.read(clGroupMembersProvider(5).future);
        expect(groups.membersCalls, 2);
      },
    );

    test(
      "Issue 138: a member's withdraw timing out reloads the enrollment",
      () async {
        final myEvents = _MyEvents();
        final c = _container(fakeSecureClient(myEvents: myEvents));
        final provider = clMyEnrollmentsMasterProvider((
          username: 'uwm_member',
          eventId: 9,
        ));
        _hold(c, provider);
        await c.read(provider.future);

        await expectLater(
          c.read(provider.notifier).withdraw(),
          throwsA(same(_timeout)),
        );
        await c.read(provider.future);
        expect(myEvents.getCalls, 2);
      },
    );

    test(
      'Issue 138: a venue image upload timing out reloads the image',
      () async {
        final venueMedia = _VenueMedia();
        final c = _container(
          fakeSecureClient(venueMedia: venueMedia, media: _Media()),
        );
        _hold(c, venueImageProvider(4));
        await c.read(venueImageProvider(4).future);
        expect(venueMedia.listCalls, 1);

        await expectLater(
          c
              .read(venueMediaMutationProvider(4).notifier)
              .uploadImage(
                bytes: const [1],
                filename: 'uwm.png',
                contentType: 'image/png',
              ),
          throwsA(same(_timeout)),
        );
        await c.read(venueImageProvider(4).future);
        expect(
          venueMedia.listCalls,
          3,
          reason: 'one listing inside the upload, one reload after it',
        );
      },
    );

    test('Issue 138: cancelling an occurrence that fails with 500 reloads '
        'the occurrence feeds', () async {
      final c = _container(fakeSecureClient(occurrences: _Occurrences()));
      final before = c.read(clResourceVersionProvider).occurrencesVersion;

      await expectLater(
        c
            .read(clEventsMasterProvider.notifier)
            .cancelOccurrence(
              2,
              DateTime.utc(2026, 11),
              version: 1,
              reason: 'uwm',
            ),
        throwsA(same(_serverError)),
      );
      expect(
        c.read(clResourceVersionProvider).occurrencesVersion,
        greaterThan(before),
      );
    });
  });
}
