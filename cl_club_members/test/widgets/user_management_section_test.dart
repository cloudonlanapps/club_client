import 'package:cl_club_members/src/utils/admin_user_actions.dart';
import 'package:cl_club_members/src/widgets/user_management_section.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _user(String username, {bool isSuperAdmin = false}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: isSuperAdmin,
  roles: UserRoles(isAdmin: isSuperAdmin),
  createdAtUtc: DateTime.utc(2024),
);

ShadButton _button(WidgetTester tester, String label) =>
    tester.widget<ShadButton>(find.widgetWithText(ShadButton, label));

const _protected = ['Block', 'Mark as Left', 'Delete'];

void main() {
  group('Issue 224: the super admin cannot be blocked, marked as left or '
      'deleted', () {
    test('Issue 224: the three actions carry the reason', () {
      final actions = adminActionsFor(
        _user('root', isSuperAdmin: true),
        isSuperAdmin: false,
      );
      expect(
        {
          for (final a in actions)
            if (a.reason != null) a.key,
        },
        {'block', 'markLeft', 'delete'},
      );
      expect(
        actions.map((a) => a.reason).whereType<String>().toSet(),
        {superAdminProtectedReason},
      );
      // Anyone else's actions carry none.
      expect(
        adminActionsFor(
          _user('robin'),
          isSuperAdmin: false,
        ).map((a) => a.reason).whereType<String>(),
        isEmpty,
      );
    });

    testWidgets('Issue 224: on the profile of the super admin they are '
        'greyed out with the reason and make no call', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: UserManagementSection(
              user: _user('root', isSuperAdmin: true),
              isSuperAdmin: false,
              onStatusAction: calls.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(superAdminProtectedReason), findsOneWidget);
      for (final label in _protected) {
        expect(_button(tester, label).onPressed, isNull, reason: label);
        await tester.tap(find.text(label), warnIfMissed: false);
        await tester.pump();
      }
      expect(calls, isEmpty);
    });

    testWidgets('Issue 224: on anyone else they stay on, with no reason', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: UserManagementSection(
              user: _user('robin'),
              isSuperAdmin: false,
              onStatusAction: calls.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(superAdminProtectedReason), findsNothing);
      await tester.tap(find.text('Block'));
      await tester.pump();
      expect(calls, ['block']);
    });
  });
}
