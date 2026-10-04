import 'package:cl_club_events/src/widgets/cards/actions/user_event_actions.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clMyEnrollmentProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show ActionGroup, ActionItem;

import '../../support/credit_scope.dart';

const _member = 'invited_member';

Future<List<ActionItem>> _resolve(
  WidgetTester tester, {
  required Event on,
  required Map<String, List<CreditAccount>> accounts,
  EnrollmentStatus? status = EnrollmentStatus.invited,
}) async {
  var actions = <ActionItem>[];
  await tester.pumpWidget(
    creditScope(
      user: person(_member),
      accounts: accounts,
      extra: [
        clMyEnrollmentProvider.overrideWith(
          (ref, key) async => status == null
              ? null
              : Enrollment(
                  id: 1,
                  membername: _member,
                  eventId: on.id,
                  status: status,
                  createdAtUtc: DateTime.utc(2026),
                ),
        ),
      ],
      child: UserEventActions(
        username: _member,
        event: on,
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

void main() {
  group('Issue 97: accepting a programme invitation needs credit', () {
    testWidgets('Issue 97: no credit greys out Accept with 🪙 0', (
      tester,
    ) async {
      final actions = await _resolve(
        tester,
        on: event(programmeId, EventType.programme),
        accounts: const {},
      );
      final accept = actions.firstWhere((a) => a.label == 'Accept');
      expect(accept.onPressed, isNull);
      expect(find.bySemanticsLabel('Credit 0'), findsOneWidget);
      // Declining is always possible.
      expect(
        actions.firstWhere((a) => a.label == 'Decline').onPressed,
        isNotNull,
      );
    });

    testWidgets('Issue 97: credit bound to this programme funds it', (
      tester,
    ) async {
      final actions = await _resolve(
        tester,
        on: event(programmeId, EventType.programme),
        accounts: {
          _member: [account(_member, 2, eventId: programmeId)],
        },
      );
      expect(
        actions.firstWhere((a) => a.label == 'Accept').onPressed,
        isNotNull,
      );
    });

    testWidgets('Issue 97: a camp needs no credit', (tester) async {
      final actions = await _resolve(
        tester,
        on: event(campId, EventType.camp),
        accounts: const {},
      );
      expect(
        actions.firstWhere((a) => a.label == 'Accept').onPressed,
        isNotNull,
      );
    });
  });
}
