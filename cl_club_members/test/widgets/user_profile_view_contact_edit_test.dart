import 'package:cl_club_members/src/views/user_profile_view.dart'
    show UserProfileView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show avatarImageProvider, clUserPrivateProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._user);
  final UserPrivate? _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

UserPrivate _user({
  required String username,
  required UserStatus status,
  bool isAdmin = false,
}) {
  return UserPrivate(
    username: username,
    displayName: username,
    status: status,
    isSuperAdmin: false,
    roles: UserRoles(isAdmin: isAdmin),
    createdAtUtc: DateTime.utc(2024, 6, 15),
  );
}

void main() {
  testWidgets(
    'Issue 473: section edit affordances unmount without overlay '
    'assertion when navigating away',
    (tester) async {
      final target = _user(username: 'newbie', status: UserStatus.active);
      final admin = _user(
        username: 'admin1',
        status: UserStatus.active,
        isAdmin: true,
      );

      Widget app(Widget body) => ProviderScope(
        overrides: [
          clUserPrivateProvider(
            target.username,
          ).overrideWith((_) async => target),
          authStateProvider.overrideWith(() => _StubAuthNotifier(admin)),
          avatarImageProvider(target.username).overrideWith((_) async => null),
        ],
        child: ShadApp(home: Scaffold(body: body)),
      );

      await tester.pumpWidget(
        app(UserProfileView(targetUsername: target.username)),
      );
      await tester.pumpAndSettle();

      // One edit pencil per section card (personal details, contact, address);
      // shown because the viewer is an admin acting on a mutable user.
      // Counted by widget: the avatar's own pencil is not a section's
      // (club_client#89).
      expect(find.byType(SectionEditButton), findsNWidgets(3));

      // Tap an affordance to enter inline edit mode — should not throw layout
      // / overlay assertions.
      await tester.tap(find.byType(SectionEditButton).first);
      await tester.pumpAndSettle();

      // Unmount the profile view by replacing the widget tree. This mimics
      // navigating away to a different route. The edit affordance is overlay-
      // free (GestureDetector, no tooltip portal), so unmounting must stay
      // clean.
      await tester.pumpWidget(app(const SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
