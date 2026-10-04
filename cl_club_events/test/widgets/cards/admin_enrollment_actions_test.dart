import 'package:cl_club_events/src/widgets/cards/actions/admin_enrollment_actions.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show ActionGroup, ActionItem;

import '../../support/credit_scope.dart';

const _member = 'row_member';

Future<List<ActionItem>> _resolve(
  WidgetTester tester, {
  required EnrollmentStatus status,
  int eventId = programmeId,
  bool? creditSystem = true,
  Map<String, MemberCreditStatus> roster = const {},
  Map<String, List<CreditAccount>> accounts = const {},
}) async {
  var actions = <ActionItem>[];
  await tester.pumpWidget(
    creditScope(
      creditSystem: creditSystem,
      roster: roster,
      accounts: accounts,
      child: AdminEnrollmentActions(
        eventId: eventId,
        username: _member,
        status: status,
        displayName: 'Row Member',
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

ActionItem _named(List<ActionItem> actions, String label) =>
    actions.firstWhere((a) => a.label == label);

void main() {
  group('Issue 96: departures wait for programme credit to be settled', () {
    testWidgets('Issue 96: Remove is greyed out while credit is bound', (
      tester,
    ) async {
      final actions = await _resolve(
        tester,
        status: EnrollmentStatus.assigned,
        roster: {_member: rosterRow(_member, usable: 8, bound: 8)},
      );
      final remove = _named(actions, 'Remove');
      expect(remove.onPressed, isNull);
      expect(remove.reason, isNotNull);
      expect(find.bySemanticsLabel('Credit 8'), findsOneWidget);
    });

    testWidgets('Issue 96: Approve withdrawal is greyed out while credit is '
        'bound', (tester) async {
      final actions = await _resolve(
        tester,
        status: EnrollmentStatus.withdrawRequested,
        roster: {_member: rosterRow(_member, usable: 3, bound: 3)},
      );
      expect(_named(actions, 'Approve').onPressed, isNull);
      expect(_named(actions, 'Reject').onPressed, isNotNull);
    });

    testWidgets('Issue 96: nothing bound means a plain Remove', (tester) async {
      final actions = await _resolve(
        tester,
        status: EnrollmentStatus.assigned,
        roster: {_member: rosterRow(_member, usable: 2)},
      );
      expect(_named(actions, 'Remove').onPressed, isNotNull);
      expect(_named(actions, 'Remove').reason, isNull);
    });

    testWidgets('Issue 96: a camp is never gated', (tester) async {
      final actions = await _resolve(
        tester,
        status: EnrollmentStatus.assigned,
        eventId: campId,
        roster: {_member: rosterRow(_member, bound: 5)},
      );
      expect(_named(actions, 'Remove').onPressed, isNotNull);
    });

    testWidgets('Issue 96: credit off is never gated', (tester) async {
      final actions = await _resolve(
        tester,
        status: EnrollmentStatus.assigned,
        creditSystem: false,
        roster: {_member: rosterRow(_member, bound: 5)},
      );
      expect(_named(actions, 'Remove').onPressed, isNotNull);
    });
  });

  group('Issue 105: approving a request needs credit', () {
    testWidgets('Issue 105: no usable credit greys out Approve with 🪙 0', (
      tester,
    ) async {
      final actions = await _resolve(
        tester,
        status: EnrollmentStatus.requested,
        accounts: {
          _member: [account(_member, 4, eventId: 77)],
        },
      );
      expect(_named(actions, 'Approve').onPressed, isNull);
      expect(find.bySemanticsLabel('Credit 0'), findsOneWidget);
    });

    testWidgets('Issue 105: general credit funds the request', (tester) async {
      final actions = await _resolve(
        tester,
        status: EnrollmentStatus.requested,
        accounts: {
          _member: [account(_member, 1)],
        },
      );
      expect(_named(actions, 'Approve').onPressed, isNotNull);
    });

    testWidgets('Issue 105: trial credit does not fund an ordinary request', (
      tester,
    ) async {
      final actions = await _resolve(
        tester,
        status: EnrollmentStatus.requested,
        accounts: {
          _member: [account(_member, 3, eventId: programmeId, isTrial: true)],
        },
      );
      expect(_named(actions, 'Approve').onPressed, isNull);
    });
  });
}
