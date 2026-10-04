import 'package:cl_club_events/src/widgets/buttons/enrollment_admin_action_bar.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventDetailProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/credit_scope.dart';

Future<void> _pump(
  WidgetTester tester,
  Event on, {
  UserPrivate? actingUser,
}) async {
  await tester.pumpWidget(
    creditScope(
      extra: [clEventDetailProvider.overrideWith((ref, id) async => on)],
      child: EnrollmentAdminActionBar(
        eventId: on.id,
        actingUser: actingUser ?? person('an_admin', admin: true),
        onAssign: () {},
        onInvite: () {},
        onAssignTrial: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 114: Assign Trial is reachable', () {
    testWidgets('Issue 114: offered on a programme', (tester) async {
      await _pump(tester, event(programmeId, EventType.programme));
      expect(find.text('Assign Trial…'), findsOneWidget);
    });

    testWidgets('Issue 114: not offered on a camp', (tester) async {
      await _pump(tester, event(campId, EventType.camp));
      expect(find.text('Assign Trial…'), findsNothing);
      expect(find.text('Assign More…'), findsOneWidget);
    });
  });

  group('Issue 136: enrollment actions are organizer-or-admin', () {
    testWidgets('Issue 136: a coach assigned to the event is offered none', (
      tester,
    ) async {
      await _pump(
        tester,
        staffed(programmeId, EventType.programme),
        actingUser: person(staffCoach, coach: true),
      );
      expect(find.text('Assign More…'), findsNothing);
      expect(find.text('Invite More…'), findsNothing);
      expect(find.text('Assign Trial…'), findsNothing);
    });

    testWidgets('Issue 136: the organizer is offered all three', (
      tester,
    ) async {
      await _pump(
        tester,
        staffed(programmeId, EventType.programme),
        actingUser: person(staffOrganizer, coach: true),
      );
      expect(find.text('Assign More…'), findsOneWidget);
      expect(find.text('Invite More…'), findsOneWidget);
      expect(find.text('Assign Trial…'), findsOneWidget);
    });
  });
}
