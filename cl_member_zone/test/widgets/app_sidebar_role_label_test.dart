import 'package:cl_member_zone/src/widgets/sidebar/app_sidebar.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

AppSidebar _sidebar(UserRoles roles) => AppSidebar(
  currentUser: UserInfo(
    username: 'label_user',
    displayName: 'Label User',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: roles,
  ),
  onNavigate: (_) {},
);

void main() {
  test('Issue 28: the sidebar role label names staff roles only', () {
    // A stale `isMember` flag must not change the label.
    expect(
      _sidebar(const UserRoles(isCoach: true, isMember: true)).roleLabel,
      'Coach',
    );
    expect(
      _sidebar(const UserRoles(isAdmin: true, isCoach: true)).roleLabel,
      'Admin / Coach',
    );
  });

  test('Issue 28: a user with no staff role is labelled Member', () {
    expect(_sidebar(const UserRoles()).roleLabel, 'Member');
  });
}
