import 'dart:async';
import 'dart:io' show SocketException;

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Writes that fail on the first 5xx, timeout or dropped connection may
/// still have landed (club_sdk 0.6.0 retries only GETs). After such a
/// failure the affected master refetches, and the error still reaches the
/// caller. A 4xx refusal is final: nothing is refetched.

const _unavailable = ServerException(
  statusCode: 503,
  code: 'SERVICE_UNAVAILABLE',
  message: 'down',
);

const _refused = ServerException(
  statusCode: 422,
  code: 'VALIDATION_ERROR',
  message: 'no',
);

final _timeout = TimeoutException('write timed out');
const _dropped = SocketException('Broken pipe');

UserInfo _admin() => const UserInfo(
  username: 'uw_admin',
  displayName: 'uw_admin',
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

PaginatedList<T> _page<T>(List<T> items) =>
    PaginatedList<T>(items: items, total: items.length, offset: 0, limit: 100);

class _Venues extends Fake implements VenueSource {
  int listCalls = 0;
  Exception? createError;

  @override
  Future<PaginatedList<Venue>> getVenues({
    int offset = 0,
    int limit = 20,
  }) async {
    listCalls++;
    return _page(const <Venue>[]);
  }

  @override
  Future<Venue> createVenue({
    required String name,
    bool isDefault = false,
    String? address,
    String? description,
    String? mapUri,
    bool isFeatured = false,
  }) async => throw createError!;
}

class _Users extends Fake implements UserSource {
  int listCalls = 0;
  UserInfo pending = const UserInfo(
    username: 'uw_pending',
    displayName: 'uw_pending',
    status: UserStatus.pending,
    isSuperAdmin: false,
    roles: UserRoles(),
  );

  @override
  Future<PaginatedList<UserInfo>> getUsers({
    int offset = 0,
    int limit = 20,
    UserStatus? status,
    String? role,
    int? minAge,
    int? maxAge,
    String? searchTerm,
    String? sortBy,
    bool descending = false,
  }) async {
    listCalls++;
    return _page([pending]);
  }

  @override
  Future<UserInfo> approveUser(
    String username, {
    String? resolutionReason,
  }) async => throw _dropped;
}

class _Enrollments extends Fake implements EnrollmentSource {
  int listCalls = 0;
  Exception? inviteError;

  @override
  Future<Map<String, EnrollmentStatus>> listEnrollments(
    int eventId, {
    EnrollmentStatus? status,
  }) async {
    listCalls++;
    return const {};
  }

  @override
  Future<void> invite(int eventId, String username) async => throw inviteError!;
}

class _Attendance extends Fake implements AttendanceSource {
  int listCalls = 0;

  @override
  Future<List<AttendanceRecord>> getAttendanceForOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc,
  ) async {
    listCalls++;
    return const [];
  }

  @override
  Future<void> clearAttendance(
    int eventId,
    String username,
    DateTime occurrenceTimeUtc,
  ) async => throw _timeout;
}

class _Notifications extends Fake implements NotificationSource {
  int listCalls = 0;

  @override
  Future<PaginatedList<AppNotification>> getNotifications({
    int offset = 0,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    listCalls++;
    return _page([
      AppNotification(
        id: 1,
        username: 'uw_admin',
        type: 'broadcast.text',
        channel: NotificationChannel.inApp,
        payload: const <String, dynamic>{},
        isRead: false,
        createdAtUtc: DateTime.utc(2026, 9),
      ),
    ]);
  }

  @override
  Future<void> markRead(int id) async => throw _timeout;
}

void main() {
  group('Issue 138: a write that may have landed refetches its master', () {
    test('Issue 138: createVenue timing out refetches the venues', () async {
      final venues = _Venues()..createError = _timeout;
      final c = _container(fakeSecureClient(venues: venues));
      await c.read(clVenuesMasterProvider.future);
      expect(venues.listCalls, 1);

      await expectLater(
        c.read(clVenuesMasterProvider.notifier).createVenue(name: 'uw_venue'),
        throwsA(same(_timeout)),
      );
      await c.read(clVenuesMasterProvider.future);
      expect(venues.listCalls, 2, reason: 'the venue list reloaded');
    });

    test('Issue 138: a 422 refusal does not refetch', () async {
      final venues = _Venues()..createError = _refused;
      final c = _container(fakeSecureClient(venues: venues));
      await c.read(clVenuesMasterProvider.future);

      await expectLater(
        c.read(clVenuesMasterProvider.notifier).createVenue(name: 'uw_venue'),
        throwsA(same(_refused)),
      );
      await c.read(clVenuesMasterProvider.future);
      expect(venues.listCalls, 1);
    });

    test('Issue 138: an approval on a dropped connection reverts the '
        'optimistic status and refetches the users', () async {
      final users = _Users();
      final c = _container(fakeSecureClient(users: users));
      await c.read(clUsersMasterProvider.future);
      expect(users.listCalls, 1);

      await expectLater(
        c.read(clUsersMasterProvider.notifier).approveUser('uw_pending'),
        throwsA(same(_dropped)),
      );
      final after = await c.read(clUsersMasterProvider.future);
      expect(users.listCalls, 2);
      expect(after['uw_pending']?.status, UserStatus.pending);
    });

    test(
      'Issue 138: an invite failing with 503 refetches the enrollments',
      () async {
        final enrollments = _Enrollments()..inviteError = _unavailable;
        final c = _container(fakeSecureClient(enrollments: enrollments));
        await c.read(clEnrollmentsMasterProvider(7).future);

        await expectLater(
          c.read(clEnrollmentsMasterProvider(7).notifier).invite('uw_member'),
          throwsA(same(_unavailable)),
        );
        await c.read(clEnrollmentsMasterProvider(7).future);
        expect(enrollments.listCalls, 2);
      },
    );

    test('Issue 138: an invite refused with 422 does not refetch', () async {
      final enrollments = _Enrollments()..inviteError = _refused;
      final c = _container(fakeSecureClient(enrollments: enrollments));
      await c.read(clEnrollmentsMasterProvider(7).future);

      await expectLater(
        c.read(clEnrollmentsMasterProvider(7).notifier).invite('uw_member'),
        throwsA(same(_refused)),
      );
      await c.read(clEnrollmentsMasterProvider(7).future);
      expect(enrollments.listCalls, 1);
    });

    test('Issue 138: clearing a mark that times out refetches the roster '
        'and the credit views', () async {
      final attendance = _Attendance();
      final c = _container(fakeSecureClient(attendance: attendance));
      final key = (eventId: 7, occurrenceTimeUtc: DateTime.utc(2026, 10));
      await c.read(clAttendancesMasterProvider(key).future);
      final credits = c.read(clResourceVersionProvider).creditsVersion;

      await expectLater(
        c
            .read(clAttendancesMasterProvider(key).notifier)
            .clearAttendance('uw_member'),
        throwsA(same(_timeout)),
      );
      await c.read(clAttendancesMasterProvider(key).future);
      expect(attendance.listCalls, 2);
      expect(
        c.read(clResourceVersionProvider).creditsVersion,
        greaterThan(credits),
      );
    });

    test('Issue 138: markRead timing out reverts and refetches', () async {
      final notifications = _Notifications();
      final c = _container(fakeSecureClient(notifications: notifications));
      await c.read(clNotificationsMasterProvider.future);

      await expectLater(
        c.read(clNotificationsMasterProvider.notifier).markRead(1),
        throwsA(same(_timeout)),
      );
      final after = await c.read(clNotificationsMasterProvider.future);
      expect(notifications.listCalls, 2);
      expect(after[1]?.isRead, isFalse);
    });
  });
}
