import 'package:cl_club_members/src/views/public_profile_view.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show mediaRefDownloadUrlProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show MediaRef, PublicProfile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show CredentialedNetworkImage;

void main() {
  Widget wrap(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: ShadApp(home: Scaffold(body: child)),
    );
  }

  testWidgets(
    'Issue 260: PublicProfileView shows name + achievements, initials when '
    'no avatar',
    (tester) async {
      const profile = PublicProfile(
        publicId: 'hmac-id',
        displayName: 'Coach Alice',
        bio: 'Loves hockey.',
        achievements: 'National champion.',
      );
      await tester.pumpWidget(wrap(const PublicProfileView(profile: profile)));
      await tester.pump();

      expect(find.text('Coach Alice'), findsWidgets);
      expect(find.text('Achievements'), findsOneWidget);
      // No avatar uuid → initials placeholder, no network image.
      expect(find.byType(CredentialedNetworkImage), findsNothing);
      expect(find.text('C'), findsOneWidget); // initial of "Coach Alice"
    },
  );

  testWidgets(
    'Issue 260: PublicProfileView shows empty-state when no bio/achievements',
    (tester) async {
      const profile = PublicProfile(publicId: 'id', displayName: 'Coach Bob');
      await tester.pumpWidget(wrap(const PublicProfileView(profile: profile)));
      await tester.pump();

      expect(find.text('No public details available.'), findsOneWidget);
      expect(find.text('Achievements'), findsNothing);
    },
  );

  testWidgets(
    'Issue 260: PublicProfileView renders the public avatar when present',
    (tester) async {
      const avatar = MediaRef(
        uuid: 'media-1',
        mimeType: 'image/webp',
        filename: 'media-1-face.webp',
      );
      const profile = PublicProfile(
        publicId: 'id',
        displayName: 'Coach Carol',
        avatar: avatar,
      );
      const url =
          'https://example.test/media/by_id/media-1/download/media-1-face.webp';
      await tester.pumpWidget(
        wrap(
          const PublicProfileView(profile: profile),
          overrides: [
            mediaRefDownloadUrlProvider((
              media: avatar,
              variant: 'original',
            )).overrideWithValue(url),
            imageAuthHeadersProvider.overrideWith(
              (ref) async => const <String, String>{},
            ),
          ],
        ),
      );
      await tester.pump();

      final img = tester.widget<CredentialedNetworkImage>(
        find.byType(CredentialedNetworkImage),
      );
      expect(img.imageUrl, url);
    },
  );
}
