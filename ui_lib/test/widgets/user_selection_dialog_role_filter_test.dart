import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// Issue #593 — the shared user-selection dialog must allow callers to
/// suppress the client-side role filter. Event pickers source their list
/// from a server endpoint (`listEligible`) that is already authoritative,
/// so overlaying a Members-only default would hide eligible
/// coaches/admins behind a popover.
void main() {
  Widget wrap(Widget child) => ShadApp(home: Scaffold(body: child));

  const admin = PickerUser(
    username: 'admin_a',
    displayName: 'Alice Admin',
    isAdmin: true,
  );
  const coach = PickerUser(
    username: 'coach_b',
    displayName: 'Bob Coach',
    isCoach: true,
  );
  const member = PickerUser(
    username: 'member_c',
    displayName: 'Carol Member',
  );

  group('Issue 593: showRoleFilter = false', () {
    testWidgets('Issue 593: every supplied user is rendered when role filter '
        'is disabled (admin + coach + member all visible)', (tester) async {
      await tester.pumpWidget(
        wrap(
          const UserSelectionDialogContent(
            title: 'Assign',
            users: [admin, coach, member],
            showRoleFilter: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice Admin'), findsOneWidget);
      expect(find.text('Bob Coach'), findsOneWidget);
      expect(find.text('Carol Member'), findsOneWidget);
    });

    testWidgets('Issue 593: role-filter popover trigger is not rendered when '
        'showRoleFilter is false', (tester) async {
      await tester.pumpWidget(
        wrap(
          const UserSelectionDialogContent(
            title: 'Assign',
            users: [admin, coach, member],
            showRoleFilter: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The popover trigger renders the "Filter" label on wide layouts and
      // an icon on narrow ones; both should be absent when disabled.
      expect(find.text('Filter'), findsNothing);
      expect(find.byIcon(Icons.filter_list), findsNothing);
    });
  });

  group('Issue 593: showRoleFilter = true (default, regression guard)', () {
    testWidgets('Issue 593: with the role filter on, default Members-only mode '
        'still hides admin and coach users — confirms the opt-out flag '
        'is the only behavioural change', (tester) async {
      await tester.pumpWidget(
        wrap(
          const UserSelectionDialogContent(
            title: 'Add Members',
            users: [admin, coach, member],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Carol Member'), findsOneWidget);
      expect(find.text('Alice Admin'), findsNothing);
      expect(find.text('Bob Coach'), findsNothing);
    });
  });
}
