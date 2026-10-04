import 'package:cl_club_events/src/widgets/attendance_member_tile.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/credit_scope.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  group('Issue 724: AttendanceMemberTile gating + clear', () {
    testWidgets(
      'Issue 724: ineligible member (canMark=false) shows a disabled toggle — '
      'tapping calls onDisabledTap, not onStatusChanged',
      (tester) async {
        AttendanceStatus? marked;
        var disabledTaps = 0;
        await tester.pumpWidget(
          _wrap(
            AttendanceMemberTile(
              username: 'alice',
              displayName: 'Alice A',
              currentStatus: null,
              onStatusChanged: (s) => marked = s,
              onClear: () {},
              onDisabledTap: () => disabledTaps++,
              canMark: false,
            ),
          ),
        );

        await tester.tap(find.text('P'));
        await tester.pump();

        expect(marked, isNull, reason: 'disabled toggle must not mark');
        expect(disabledTaps, 1, reason: 'tap routes to onDisabledTap');
        // No clear affordance when there is nothing recorded.
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );

    testWidgets(
      'Issue 724: eligible member (canMark=true) marks present on tap',
      (tester) async {
        AttendanceStatus? marked;
        await tester.pumpWidget(
          _wrap(
            AttendanceMemberTile(
              username: 'bob',
              displayName: 'Bob B',
              currentStatus: null,
              onStatusChanged: (s) => marked = s,
              onClear: () {},
              onDisabledTap: () {},
            ),
          ),
        );

        await tester.tap(find.text('P'));
        await tester.pump();

        expect(marked, AttendanceStatus.present);
        // Nothing recorded/selected yet → no clear affordance.
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );

    testWidgets(
      'Issue 724: re-tapping the already-selected segment clears (onClear)',
      (tester) async {
        var cleared = 0;
        AttendanceStatus? marked;
        await tester.pumpWidget(
          _wrap(
            AttendanceMemberTile(
              username: 'frank',
              displayName: 'Frank F',
              currentStatus: AttendanceStatus.present,
              onStatusChanged: (s) => marked = s,
              onClear: () => cleared++,
              onDisabledTap: () {},
            ),
          ),
        );

        // P is the active segment → re-tapping it clears, not re-marks.
        await tester.tap(find.text('P'));
        await tester.pump();
        expect(cleared, 1);
        expect(marked, isNull);
      },
    );

    testWidgets(
      'Issue 724: a recorded member shows a clear affordance calling onClear',
      (tester) async {
        var cleared = 0;
        await tester.pumpWidget(
          _wrap(
            AttendanceMemberTile(
              username: 'carol',
              displayName: 'Carol C',
              currentStatus: AttendanceStatus.present,
              onStatusChanged: (_) {},
              onClear: () => cleared++,
              onDisabledTap: () {},
            ),
          ),
        );

        final clearBtn = find.byIcon(Icons.close);
        expect(clearBtn, findsOneWidget);
        await tester.tap(clearBtn);
        await tester.pump();
        expect(cleared, 1);
      },
    );

    testWidgets(
      'Issue 724: ineligible member WITH an existing record can still be '
      'cleared (canMark=true via record)',
      (tester) async {
        // Roster computes canMark = isSuperAdmin || eligible || hasRecord.
        // Here we emulate the hasRecord path directly.
        var cleared = 0;
        await tester.pumpWidget(
          _wrap(
            AttendanceMemberTile(
              username: 'dave',
              displayName: 'Dave D',
              currentStatus: AttendanceStatus.late,
              onStatusChanged: (_) {},
              onClear: () => cleared++,
              onDisabledTap: () {},
            ),
          ),
        );

        expect(find.byIcon(Icons.close), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        expect(cleared, 1);
      },
    );

    testWidgets(
      'Issue 724: on-leave member shows a badge, no toggle or clear',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            AttendanceMemberTile(
              username: 'erin',
              displayName: 'Erin E',
              currentStatus: AttendanceStatus.onLeave,
              onStatusChanged: (_) {},
              onClear: () {},
              onDisabledTap: () {},
            ),
          ),
        );

        expect(find.text('P'), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );
  });

  group('Issue 726: optimistic pending override', () {
    testWidgets(
      'Issue 726: a pending clear shows the row as not-recorded even when a '
      'server record exists (no active segment, no clear button)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            AttendanceMemberTile(
              username: 'gina',
              displayName: 'Gina G',
              currentStatus: AttendanceStatus.present,
              // In-flight clear: hasPending + null selectedStatus.
              hasPending: true,
              onStatusChanged: (_) {},
              onClear: () {},
              onDisabledTap: () {},
            ),
          ),
        );

        // Optimistically nothing is selected, so there's no clear affordance.
        expect(find.byIcon(Icons.close), findsNothing);
        // The P/A/L toggle is still present (member is markable) but inactive.
        expect(find.text('P'), findsOneWidget);
      },
    );

    testWidgets(
      'Issue 726: a pending mark overrides the server status in the display',
      (tester) async {
        AttendanceStatus? cleared;
        await tester.pumpWidget(
          _wrap(
            AttendanceMemberTile(
              username: 'hank',
              displayName: 'Hank H',
              currentStatus: AttendanceStatus.present,
              // Optimistic switch present -> late, in flight.
              selectedStatus: AttendanceStatus.late,
              hasPending: true,
              onStatusChanged: (_) {},
              onClear: () => cleared = AttendanceStatus.late,
              onDisabledTap: () {},
            ),
          ),
        );

        // L is the active (optimistic) segment → re-tapping it clears.
        await tester.tap(find.text('L'));
        await tester.pump();
        expect(cleared, AttendanceStatus.late);
      },
    );
  });

  group('Issue 99: a member who cannot be charged', () {
    testWidgets('Issue 99: the toggle is greyed out with the credit chip', (
      tester,
    ) async {
      var marked = 0;
      await tester.pumpWidget(
        creditScope(
          child: AttendanceMemberTile(
            username: 'broke',
            displayName: 'Broke',
            currentStatus: null,
            onStatusChanged: (_) => marked++,
            onClear: () {},
            onDisabledTap: () {},
            blockedCredits: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Credit 0'), findsOneWidget);
      await tester.tap(find.text('P'));
      expect(marked, 0);
    });
  });

  testWidgets('Issue 98: an ended trial shows a flag and no toggle', (
    tester,
  ) async {
    await tester.pumpWidget(
      creditScope(
        child: AttendanceMemberTile(
          username: 'trial',
          displayName: 'Trial',
          currentStatus: AttendanceStatus.present,
          onStatusChanged: (_) {},
          onClear: () {},
          onDisabledTap: () {},
          isEditable: false,
          trialEnded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.flag), findsOneWidget);
    expect(find.text('P'), findsNothing);
  });
}
