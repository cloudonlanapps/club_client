import 'package:cl_club_members/src/widgets/role_chips.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  testWidgets(
    'Issue 135: one chip per role, admin and coach, and none for super admin',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          RoleChips(
            roles: UserRoles.fromList(const ['admin', 'super_admin']),
            onToggle: (_, {required selected}) {},
          ),
        ),
      );

      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Coach'), findsOneWidget);
      expect(find.textContaining('uper'), findsNothing);
      expect(find.byType(ShadButton), findsNWidgets(2));
    },
  );

  testWidgets('Issue 135: tapping a chip toggles that role', (tester) async {
    final toggled = <(Role, bool)>[];
    await tester.pumpWidget(
      _wrap(
        RoleChips(
          roles: const UserRoles(isAdmin: true),
          onToggle: (role, {required selected}) =>
              toggled.add((role, selected)),
        ),
      ),
    );

    await tester.tap(find.text('Admin'));
    await tester.tap(find.text('Coach'));

    expect(toggled, [(Role.admin, false), (Role.coach, true)]);
  });
}
