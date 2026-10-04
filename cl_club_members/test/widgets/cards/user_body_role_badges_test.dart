import 'package:cl_club_members/src/widgets/cards/user_card.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserInfo _user(UserRoles roles) => UserInfo(
  username: 'badge_user',
  displayName: 'Badge User',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: roles,
);

Future<void> _pump(WidgetTester tester, UserInfo user) =>
    tester.pumpWidget(ShadApp(home: UserBody(user: user)));

void main() {
  testWidgets(
    'Issue 28: a user card badges staff roles only — never Member',
    (tester) async {
      // A stale `isMember` flag must not surface as a role badge.
      await _pump(
        tester,
        _user(const UserRoles(isCoach: true, isMember: true)),
      );
      expect(find.text('Coach'), findsOneWidget);
      expect(find.text('Member'), findsNothing);
    },
  );

  testWidgets('Issue 28: a user with no staff role gets no badge', (
    tester,
  ) async {
    await _pump(tester, _user(const UserRoles(isMember: true)));
    expect(find.text('Member'), findsNothing);
  });
}
