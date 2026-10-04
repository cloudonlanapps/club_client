import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

void main() {
  Widget wrap({required List<PickerUser> users}) {
    return ShadApp(
      home: Scaffold(
        body: UserSelectionDialogContent(
          title: 'Pick',
          users: users,
        ),
      ),
    );
  }

  testWidgets(
    'Issue 272: dialog renders only the users it is handed (server-side '
    'eligibility and caller-side exclusions happen before this widget)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          users: const [
            PickerUser(username: 'alice', displayName: 'Alice'),
            PickerUser(username: 'bob', displayName: 'Bob'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('charlie'), findsNothing);
    },
  );

  testWidgets(
    'Issue 272: empty user list shows the no-users message',
    (tester) async {
      await tester.pumpWidget(wrap(users: const []));
      await tester.pumpAndSettle();

      expect(find.text('No users available.'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 267: non-member users (coaches/admins) are hidden by default '
    'when the user list contains any non-member; filter trigger is shown',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          users: const [
            PickerUser(username: 'alice', displayName: 'Alice'),
            PickerUser(
              username: 'coach',
              displayName: 'Coach Carl',
              isCoach: true,
            ),
            PickerUser(
              username: 'admin',
              displayName: 'Admin Anna',
              isAdmin: true,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Coach Carl'), findsNothing);
      expect(find.text('Admin Anna'), findsNothing);
      expect(find.text('Filter (1)'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 267: checking "Coaches" in the filter popover reveals coaches '
    'while keeping members visible (combination filtering)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          users: const [
            PickerUser(username: 'alice', displayName: 'Alice'),
            PickerUser(
              username: 'coach',
              displayName: 'Coach Carl',
              isCoach: true,
            ),
            PickerUser(
              username: 'admin',
              displayName: 'Admin Anna',
              isAdmin: true,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Open the filter popover.
      await tester.tap(find.text('Filter (1)'));
      await tester.pumpAndSettle();

      // Tick the "Coaches" checkbox.
      await tester.tap(find.text('Coaches'));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Coach Carl'), findsOneWidget);
      expect(find.text('Admin Anna'), findsNothing);
      expect(find.text('Filter (2)'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 267: role label appears inline on coach/admin tiles, '
    'plain members have no label',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          users: const [
            PickerUser(username: 'alice', displayName: 'Alice'),
            PickerUser(
              username: 'coach',
              displayName: 'Coach Carl',
              isCoach: true,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Reveal coach via filter.
      await tester.tap(find.text('Filter (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coaches'));
      await tester.pumpAndSettle();

      expect(find.text(' · Coach'), findsOneWidget);
      expect(find.text(' · Admin'), findsNothing);
    },
  );

  testWidgets(
    'Issue 267: role-filter trigger is always shown — even when every user '
    'in the list is a plain member — so the operator can always adjust',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          users: const [
            PickerUser(username: 'alice', displayName: 'Alice'),
            PickerUser(username: 'bob', displayName: 'Bob'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Filter (1)'), findsOneWidget);
    },
  );
}
