import 'package:cl_club_members/src/widgets/user_avatar.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

void main() {
  final user = UserInfo.create(
    publicId: 'john',
    username: 'john',
    firstName: 'John',
    lastName: 'Doe',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(),
  );

  Widget wrap(Widget child, {required List<Override> overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: ShadApp(
        home: Scaffold(
          body: SizedBox(width: 100, height: 100, child: child),
        ),
      ),
    );
  }

  testWidgets(
    'Issue 555: UserAvatar renders initials when no avatar URL is available',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          UserAvatar(user: user),
          overrides: [
            avatarImageProvider(user.username).overrideWith((_) async => null),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('JD'), findsOneWidget);
      expect(find.byType(CredentialedNetworkImage), findsNothing);
    },
  );

  testWidgets(
    'Issue 555: UserAvatar uses CredentialedNetworkImage when a URL exists',
    (tester) async {
      const url = 'https://example.test/avatar.png';
      await tester.pumpWidget(
        wrap(
          UserAvatar(user: user),
          overrides: [
            avatarImageProvider(user.username).overrideWith((_) async => url),
          ],
        ),
      );
      await tester.pump();
      expect(find.byType(CredentialedNetworkImage), findsOneWidget);
      final widget = tester.widget<CredentialedNetworkImage>(
        find.byType(CredentialedNetworkImage),
      );
      expect(widget.imageUrl, url);
    },
  );
}
