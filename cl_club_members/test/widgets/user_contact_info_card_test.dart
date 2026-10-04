import 'package:cl_club_members/src/widgets/user_contact_info_card.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _user() => UserPrivate(
  username: 'robin',
  displayName: 'Robin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  email: 'robin@example.test',
  phone: '+10000000001',
  createdAtUtc: DateTime.utc(2024, 6, 15),
);

Future<void> _pump(WidgetTester tester, {required bool canEdit}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UserContactInfoCard(user: _user(), canEdit: canEdit),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group("Issue 53: the member's contact card", () {
    testWidgets('Issue 53: shows the contact fields it has, read-only', (
      tester,
    ) async {
      await _pump(tester, canEdit: false);

      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('robin'), findsOneWidget);
      expect(find.text('robin@example.test'), findsOneWidget);
      expect(find.text('+10000000001'), findsOneWidget);
      expect(find.text('Emergency Contact'), findsNothing);
      expect(find.byIcon(LucideIcons.pencil), findsNothing);
    });

    testWidgets('Issue 53: an editor gets the edit pencil', (tester) async {
      await _pump(tester, canEdit: true);

      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    });
  });
}
