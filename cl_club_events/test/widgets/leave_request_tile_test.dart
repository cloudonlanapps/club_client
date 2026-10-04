import 'package:cl_club_events/src/widgets/leave_request_tile.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/credit_scope.dart';

Future<void> _pump(WidgetTester tester, {String? leaveReason}) =>
    tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: LeaveRequestTile(
            username: 'away',
            displayName: 'Away Member',
            event: event(campId, EventType.camp),
            actingUser: person('an_admin', admin: true),
            leaveReason: leaveReason,
            onApprove: () {},
            onReject: () {},
          ),
        ),
      ),
    );

/// The texts the tile renders, in order.
List<String?> _texts(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(LeaveRequestTile),
        matching: find.byType(Text),
      ),
    )
    .map((t) => t.data)
    .toList();

void main() {
  group('Issue 137: the leave reason on a pending leave request', () {
    testWidgets("Issue 137: staff see the member's reason", (tester) async {
      await _pump(tester, leaveReason: 'Family wedding out of town');
      expect(find.text('Family wedding out of town'), findsOneWidget);
    });

    testWidgets('Issue 137: no reason shows no placeholder', (tester) async {
      await _pump(tester);
      expect(_texts(tester), ['A', 'Away Member', 'Leave requested']);
    });

    testWidgets('Issue 137: a blank reason shows no placeholder', (
      tester,
    ) async {
      await _pump(tester, leaveReason: '   ');
      expect(_texts(tester), ['A', 'Away Member', 'Leave requested']);
    });
  });
}
