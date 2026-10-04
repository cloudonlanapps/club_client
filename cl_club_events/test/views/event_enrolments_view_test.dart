import 'package:cl_club_events/src/views/event_enrolments_view.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEnrollmentRecordsMasterNotifier,
        ClEnrollmentsMasterNotifier,
        ClUsersMasterNotifier,
        clEnrollmentRecordsMasterProvider,
        clEnrollmentsMasterProvider,
        clUsersMasterProvider,
        evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/credit_scope.dart';

class _Enrollments extends ClEnrollmentsMasterNotifier {
  @override
  Future<Map<String, EnrollmentStatus>> build(int arg) async => const {
    'asked': EnrollmentStatus.requested,
    'leaving': EnrollmentStatus.withdrawRequested,
    'active': EnrollmentStatus.assigned,
  };
}

class _Records extends ClEnrollmentRecordsMasterNotifier {
  @override
  Future<Map<String, Enrollment>> build(int arg) async => const {};
}

class _Users extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => const {};
}

Future<void> _pump(
  WidgetTester tester,
  UserPrivate user, {
  bool? evaluations,
}) async {
  await tester.pumpWidget(
    creditScope(
      user: user,
      creditSystem: false,
      events: {campId: staffed(campId, EventType.camp)},
      extra: [
        clEnrollmentsMasterProvider.overrideWith(_Enrollments.new),
        clEnrollmentRecordsMasterProvider.overrideWith(_Records.new),
        clUsersMasterProvider.overrideWith(_Users.new),
        if (evaluations != null)
          evaluationsProvider.overrideWithValue(evaluations),
      ],
      child: EventEnrolmentsView(
        currentUser: user,
        eventId: campId,
        onOpenReview: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 136: the enrollment list is read-only to assigned coaches', () {
    testWidgets(
      'Issue 136: an assigned coach reads the list, with no actions',
      (
        tester,
      ) async {
        await _pump(tester, person(staffCoach, coach: true));

        expect(find.text('asked'), findsWidgets);
        expect(find.text('active'), findsWidgets);
        expect(find.text('Assign More…'), findsNothing);
        expect(find.text('Invite More…'), findsNothing);
        expect(find.text('Approve'), findsNothing);
        expect(find.text('Reject'), findsNothing);
        expect(find.text('Remove'), findsNothing);
      },
    );

    testWidgets('Issue 136: the organizer gets every enrollment action', (
      tester,
    ) async {
      await _pump(tester, person(staffOrganizer, coach: true));

      expect(find.text('Assign More…'), findsOneWidget);
      expect(find.text('Invite More…'), findsOneWidget);
      expect(find.text('Approve'), findsNWidgets(2));
      expect(find.text('Reject'), findsNWidgets(2));
      expect(find.text('Remove'), findsOneWidget);
    });
  });

  group('Issue 174: Add Review on each enrolment row, for coaches', () {
    testWidgets('Issue 174: an assigned coach gets Add Review on every row', (
      tester,
    ) async {
      await _pump(tester, person(staffCoach, coach: true), evaluations: true);
      expect(find.text('Add Review'), findsNWidgets(3));
      expect(find.text('Remove'), findsNothing);
    });

    testWidgets('Issue 174: the coaching organizer keeps every action and '
        'adds Add Review last', (tester) async {
      await _pump(
        tester,
        person(staffOrganizer, coach: true),
        evaluations: true,
      );
      // The active row shows [Remove, Add Review] inline; the request rows
      // keep Approve inline and fold the rest under the overflow menu.
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Approve'), findsNWidgets(2));
      expect(find.text('Add Review'), findsOneWidget);
    });

    testWidgets('Issue 174: an admin who does not coach gets none', (
      tester,
    ) async {
      await _pump(tester, person('admin_a', admin: true), evaluations: true);
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Add Review'), findsNothing);
    });

    testWidgets('Issue 174: nobody gets it with evaluations off', (
      tester,
    ) async {
      await _pump(tester, person(staffCoach, coach: true), evaluations: false);
      expect(find.text('Add Review'), findsNothing);
    });
  });
}
