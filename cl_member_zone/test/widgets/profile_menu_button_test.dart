import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_member_zone/src/widgets/profile_menu_button.dart';
import 'package:cl_remote_store/cl_remote_store.dart' show avatarImageProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show AvatarCircleVariant, CredentialedNetworkImage;

Widget _wrap({String? avatarUrl}) => ProviderScope(
  overrides: [
    avatarImageProvider.overrideWith((ref, username) async => avatarUrl),
    imageAuthHeadersProvider.overrideWith((ref) async => const {}),
  ],
  child: ShadApp(
    home: Scaffold(
      body: Center(
        child: ProfileMenuButton(
          username: 'uu',
          displayName: 'Usha User',
          onProfile: () {},
          onSignOut: () {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'shows initials in the app-bar anchor when the user has no avatar',
    (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(AvatarCircleVariant), findsOneWidget);
      expect(find.byType(CredentialedNetworkImage), findsNothing);
    },
  );

  testWidgets(
    'shows the avatar image in the app-bar anchor when one is available',
    (tester) async {
      await tester.pumpWidget(
        _wrap(avatarUrl: 'https://media.example/uu/original'),
      );
      await tester.pumpAndSettle();
      // Network image has no backend in tests; it falls back to initials via
      // errorBuilder, but the credentialed image widget is mounted (proving
      // the avatar path was taken rather than the plain-initials path).
      tester.takeException();
      expect(find.byType(CredentialedNetworkImage), findsOneWidget);
    },
  );
}
