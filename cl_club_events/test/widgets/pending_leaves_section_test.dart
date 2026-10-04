import 'package:cl_club_events/src/models/attendance_roster_entry.dart';
import 'package:cl_club_events/src/widgets/leave_request_tile.dart';
import 'package:cl_club_events/src/widgets/pending_leaves_section.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/credit_scope.dart';

AttendanceRosterEntry _leave(String username, String? reason) => (
  username: username,
  enrollmentStatus: EnrollmentStatus.assigned,
  currentStatus: AttendanceStatus.onLeaveRequested,
  eligible: true,
  creditBlocked: false,
  usableCredits: 0,
  trialEnded: false,
  leaveReason: reason,
);

void main() {
  testWidgets('Issue 137: each pending request shows its own reason', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: PendingLeavesSection(
            event: event(campId, EventType.camp),
            pendingLeaves: [_leave('away', 'Exams'), _leave('ill', null)],
            actingUser: person('an_admin', admin: true),
            displayNameResolver: (u) => u,
            onApprove: (_) {},
            onReject: (_) {},
          ),
        ),
      ),
    );

    final tiles = tester.widgetList<LeaveRequestTile>(
      find.byType(LeaveRequestTile),
    );
    expect(
      {for (final t in tiles) t.username: t.leaveReason},
      {'away': 'Exams', 'ill': null},
    );
    expect(find.text('Exams'), findsOneWidget);
  });
}
