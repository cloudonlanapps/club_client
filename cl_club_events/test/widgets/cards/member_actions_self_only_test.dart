import 'package:cl_club_events/src/widgets/buttons/enrollment_action_buttons.dart';
import 'package:cl_club_events/src/widgets/cards/actions/user_event_actions.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clMyEnrollmentProvider, clMyEventDetailProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, ActionGroup, ActionItem;

import '../../support/credit_scope.dart';

const _member = 'self_member';
final Event _event = event(campId, EventType.camp);

Enrollment _invited() => Enrollment(
  id: 1,
  membername: _member,
  eventId: campId,
  status: EnrollmentStatus.invited,
  createdAtUtc: DateTime.utc(2026),
);

Future<List<ActionItem>> _eventActions(
  WidgetTester tester,
  UserPrivate viewer,
) async {
  var actions = <ActionItem>[];
  await tester.pumpWidget(
    creditScope(
      user: viewer,
      creditSystem: false,
      extra: [
        clMyEnrollmentProvider.overrideWith((ref, key) async => _invited()),
      ],
      child: UserEventActions(
        username: _member,
        event: _event,
        builder: (context, resolved) {
          actions = resolved;
          return ActionGroup(actions: resolved);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return actions;
}

Future<void> _pumpButtons(WidgetTester tester, UserPrivate viewer) async {
  await tester.pumpWidget(
    creditScope(
      user: viewer,
      creditSystem: false,
      extra: [
        clMyEnrollmentProvider.overrideWith((ref, key) async => _invited()),
        clMyEventDetailProvider.overrideWith((ref, key) async => _event),
      ],
      child: const EnrollmentActionButtons(username: _member, eventId: campId),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 127: member self-service stays with the member', () {
    testWidgets('Issue 127: the member gets their event actions', (
      tester,
    ) async {
      final actions = await _eventActions(tester, person(_member));
      expect(actions.map((a) => a.label), containsAll(['Accept', 'Decline']));
    });

    testWidgets('Issue 127: an admin viewing the member gets none', (
      tester,
    ) async {
      final actions = await _eventActions(
        tester,
        person('an_admin', admin: true),
      );
      expect(actions, isEmpty);
    });

    testWidgets('Issue 127: the event page shows the member their buttons', (
      tester,
    ) async {
      await _pumpButtons(tester, person(_member));
      expect(find.widgetWithText(ActionButton, 'Accept'), findsOneWidget);
    });

    testWidgets('Issue 127: the event page shows staff no member buttons', (
      tester,
    ) async {
      await _pumpButtons(tester, person('an_admin', admin: true));
      expect(find.byType(ActionButton), findsNothing);
    });
  });
}
