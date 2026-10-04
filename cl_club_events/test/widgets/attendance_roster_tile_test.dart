import 'package:cl_club_events/src/models/attendance_roster_entry.dart';
import 'package:cl_club_events/src/widgets/attendance_roster_tile.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

AttendanceRosterEntry _entry({
  required bool eligible,
  AttendanceStatus? currentStatus,
}) => (
  username: 'alice',
  enrollmentStatus: EnrollmentStatus.assigned,
  currentStatus: currentStatus,
  eligible: eligible,
  creditBlocked: false,
  usableCredits: 0,
  trialEnded: false,
  leaveReason: null,
);

Widget _wrap({
  required AttendanceRosterEntry entry,
  required bool isSuperAdmin,
  void Function(String, AttendanceStatus)? onStatusChanged,
  void Function(String)? onClear,
  void Function(String)? onDisabledTap,
}) => ShadApp(
  home: Scaffold(
    body: AttendanceRosterTile(
      entry: entry,
      pending: const {},
      onStatusChanged: onStatusChanged ?? (_, _) {},
      onClear: onClear ?? (_) {},
      onDisabledTap: onDisabledTap ?? (_) {},
      displayNameResolver: (u) => u,
      isEditable: true,
      isSuperAdmin: isSuperAdmin,
    ),
  ),
);

void main() {
  group('Issue 726: AttendanceRosterTile canMark derivation', () {
    testWidgets(
      'Issue 726: ineligible + no record + non-sudo → disabled (onDisabledTap)',
      (tester) async {
        AttendanceStatus? marked;
        var disabled = 0;
        await tester.pumpWidget(
          _wrap(
            entry: _entry(eligible: false),
            isSuperAdmin: false,
            onStatusChanged: (_, s) => marked = s,
            onDisabledTap: (_) => disabled++,
          ),
        );

        await tester.tap(find.text('P'));
        await tester.pump();
        expect(marked, isNull);
        expect(disabled, 1);
      },
    );

    testWidgets(
      'Issue 726: ineligible + no record + super-admin → markable (override)',
      (tester) async {
        AttendanceStatus? marked;
        await tester.pumpWidget(
          _wrap(
            entry: _entry(eligible: false),
            isSuperAdmin: true,
            onStatusChanged: (_, s) => marked = s,
          ),
        );

        await tester.tap(find.text('P'));
        await tester.pump();
        expect(marked, AttendanceStatus.present);
      },
    );

    testWidgets('Issue 726: eligible + non-sudo → markable', (tester) async {
      AttendanceStatus? marked;
      await tester.pumpWidget(
        _wrap(
          entry: _entry(eligible: true),
          isSuperAdmin: false,
          onStatusChanged: (_, s) => marked = s,
        ),
      );

      // 'L' (Late) avoids colliding with the avatar's 'A' for "alice".
      await tester.tap(find.text('L'));
      await tester.pump();
      expect(marked, AttendanceStatus.late);
    });

    testWidgets(
      'Issue 726: ineligible but has a record → can still clear it',
      (tester) async {
        var cleared = 0;
        await tester.pumpWidget(
          _wrap(
            entry: _entry(
              eligible: false,
              currentStatus: AttendanceStatus.present,
            ),
            isSuperAdmin: false,
            onClear: (_) => cleared++,
          ),
        );

        // P is active (server record) and the row is markable via the record,
        // so re-tapping P clears.
        await tester.tap(find.text('P'));
        await tester.pump();
        expect(cleared, 1);
      },
    );
  });
}
