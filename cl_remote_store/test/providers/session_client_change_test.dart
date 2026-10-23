import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

const int _eventId = 7;
const String _member = 'm3';

/// One session's view of the event's enrollments.
class _Enrollments extends Fake implements EnrollmentSource {
  _Enrollments(this.enrollment);

  final Enrollment enrollment;
  int calls = 0;

  @override
  Future<Map<String, EnrollmentStatus>> listEnrollments(
    int eventId, {
    EnrollmentStatus? status,
  }) async {
    calls++;
    return {_member: enrollment.status};
  }

  @override
  Future<Map<String, Enrollment>> listEnrollmentsDetailed(
    int eventId, {
    EnrollmentStatus? status,
  }) async {
    calls++;
    return {_member: enrollment};
  }
}

Enrollment _enrollment(EnrollmentStatus status, {String? reason}) =>
    Enrollment(
      id: 1,
      membername: _member,
      eventId: _eventId,
      status: status,
      isTrial: true,
      withdrawalReason: reason,
      createdAtUtc: DateTime.utc(2026),
    );

/// Which session is signed in; a sign-in or sign-out replaces the client.
final _sessionProvider = StateProvider<int>((ref) => 0);

void main() {
  group('Issue 294: a new session rebuilds the enrollment masters', () {
    late _Enrollments before;
    late _Enrollments after;
    late ProviderContainer container;

    setUp(() {
      before = _Enrollments(_enrollment(EnrollmentStatus.assignedTrial));
      after = _Enrollments(
        _enrollment(EnrollmentStatus.removed, reason: 'trialCreditExhausted'),
      );
      container = ProviderContainer(
        overrides: [
          secureClientProvider.overrideWith(
            (ref) async => fakeSecureClient(
              enrollments: ref.watch(_sessionProvider) == 0 ? before : after,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('Issue 294: the enrollment records master fetches again on the '
        'new client', () async {
      container.listen(
        clEnrollmentRecordsMasterProvider(_eventId),
        (_, _) {},
      );
      final first = await container.read(
        clEnrollmentRecordsMasterProvider(_eventId).future,
      );
      expect(first[_member]!.withdrawalReason, isNull);

      container.read(_sessionProvider.notifier).state = 1;
      final next = await container.read(
        clEnrollmentRecordsMasterProvider(_eventId).future,
      );

      expect(next[_member]!.withdrawalReason, 'trialCreditExhausted');
      expect(after.calls, 1);
    });

    test('Issue 294: the enrollments master fetches again on the new '
        'client', () async {
      container.listen(clEnrollmentsMasterProvider(_eventId), (_, _) {});
      expect(
        (await container.read(
          clEnrollmentsMasterProvider(_eventId).future,
        ))[_member],
        EnrollmentStatus.assignedTrial,
      );

      container.read(_sessionProvider.notifier).state = 1;

      expect(
        (await container.read(
          clEnrollmentsMasterProvider(_eventId).future,
        ))[_member],
        EnrollmentStatus.removed,
      );
      expect(after.calls, 1);
    });
  });
}
