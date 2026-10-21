import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

const _down = ServerException(
  statusCode: 401,
  code: 'unauthorized',
  message: 'token expired',
);

/// Writes always succeed; roster reads fail once [failReads] is set.
class _FakeEnrollments extends Fake implements EnrollmentSource {
  bool failReads = false;
  int assignCalls = 0;

  @override
  Future<Map<String, EnrollmentStatus>> listEnrollments(
    int eventId, {
    EnrollmentStatus? status,
  }) async {
    if (failReads) throw _down;
    return const {};
  }

  @override
  Future<void> assign(int eventId, String username) async {
    assignCalls++;
  }
}

/// Counts the member-side reads; the enrollment read fails once
/// [failEnrollmentReads] is set.
class _FakeMyEvents extends Fake implements MyEventsSource {
  bool failEnrollmentReads = false;
  int myEventsReads = 0;
  int acceptCalls = 0;

  @override
  Future<PaginatedList<Event>> listMyEvents(
    String username, {
    DateTime? fromTimeUtc,
    DateTime? toTimeUtc,
    int? offset,
    int? limit,
  }) async {
    myEventsReads++;
    return const PaginatedList(items: [], total: 0, offset: 0, limit: 20);
  }

  @override
  Future<Enrollment> getMyEnrollment(String username, int eventId) async {
    if (failEnrollmentReads) throw _down;
    return Enrollment(
      id: 1,
      membername: username,
      eventId: eventId,
      status: EnrollmentStatus.invited,
      createdAtUtc: DateTime.utc(2026),
    );
  }

  @override
  Future<void> acceptInvite(String username, int eventId) async {
    acceptCalls++;
  }
}

void main() {
  const eventId = 42;
  const username = 'alice';
  const memberKey = (username: username, eventId: eventId);

  late _FakeEnrollments enrollments;
  late _FakeMyEvents myEvents;
  late ProviderContainer container;

  setUp(() {
    enrollments = _FakeEnrollments();
    myEvents = _FakeMyEvents();
    container = ProviderContainer(
      overrides: [
        secureClientProvider.overrideWith(
          (ref) async => fakeSecureClient(
            enrollments: enrollments,
            myEvents: myEvents,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  int creditsVersion() =>
      container.read(clResourceVersionProvider).creditsVersion;

  test(
    'Issue 227: an assign whose roster re-read fails completes, leaves the '
    'error in state and still refreshes the member side',
    () async {
      final roster = container.listen(
        clEnrollmentsMasterProvider(eventId),
        (_, _) {},
      );
      addTearDown(roster.close);
      final mine = container.listen(
        clMyEventsMasterProvider(username),
        (_, _) {},
      );
      addTearDown(mine.close);
      await container.read(clEnrollmentsMasterProvider(eventId).future);
      await container.read(clMyEventsMasterProvider(username).future);
      expect(myEvents.myEventsReads, 1);
      final before = creditsVersion();

      enrollments.failReads = true;
      await container
          .read(clEnrollmentsMasterProvider(eventId).notifier)
          .assign(username);

      expect(enrollments.assignCalls, 1);
      expect(roster.read().hasError, isTrue);
      expect(roster.read().error, isA<ServerException>());
      expect(creditsVersion(), before + 1);
      await container.read(clMyEventsMasterProvider(username).future);
      expect(
        myEvents.myEventsReads,
        2,
        reason: "the member's My Events must be invalidated",
      );
    },
  );

  test(
    'Issue 227: accepting an invite whose re-read fails completes, leaves '
    'the error in state and still refreshes the other views',
    () async {
      final sub = container.listen(
        clMyEnrollmentsMasterProvider(memberKey),
        (_, _) {},
      );
      addTearDown(sub.close);
      final mine = container.listen(
        clMyEventsMasterProvider(username),
        (_, _) {},
      );
      addTearDown(mine.close);
      await container.read(clMyEnrollmentsMasterProvider(memberKey).future);
      await container.read(clMyEventsMasterProvider(username).future);
      final before = creditsVersion();

      myEvents.failEnrollmentReads = true;
      await container
          .read(clMyEnrollmentsMasterProvider(memberKey).notifier)
          .acceptInvite();

      expect(myEvents.acceptCalls, 1);
      expect(sub.read().hasError, isTrue);
      expect(sub.read().error, isA<ServerException>());
      expect(creditsVersion(), before + 1);
      await container.read(clMyEventsMasterProvider(username).future);
      expect(myEvents.myEventsReads, 2);
    },
  );
}
