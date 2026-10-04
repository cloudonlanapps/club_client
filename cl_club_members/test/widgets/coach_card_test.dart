import 'package:cl_club_members/cl_club_members.dart'
    show CoachCard, CoachesCardList;
import 'package:cl_club_members/src/widgets/placeholder_avatar.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

const _base = 'https://api.example.test/v1';

const _coach = PublicProfile(
  publicId: 'pc-1',
  displayName: 'Robin Frost',
  bio: 'Coached **juniors** for ten years.',
  achievements: 'National finalist.',
  avatar: MediaRef(
    uuid: 'avatar-robin',
    mimeType: 'image/jpeg',
    filename: 'robin.jpg',
  ),
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serverConfigProvider.overrideWithValue(
          const ServerConfig(baseUrl: _base),
        ),
      ],
      child: ShadApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('Issue 53: CoachCard shows a coach from the public staff list', () {
    testWidgets('Issue 53: name, bio and achievements, with the avatar', (
      tester,
    ) async {
      await _pump(tester, const CoachCard(coach: _coach, isMobile: false));

      expect(find.text('Robin Frost'), findsOneWidget);
      expect(find.byType(ThemedMarkdown), findsNWidgets(2));
      expect(find.textContaining('juniors'), findsOneWidget);
      expect(find.textContaining('National finalist'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        allOf(startsWith(_base), contains('avatar-robin')),
      );
    });

    testWidgets('Issue 53: a coach with no avatar gets the placeholder', (
      tester,
    ) async {
      await _pump(
        tester,
        const CoachCard(
          coach: PublicProfile(publicId: 'pc-2', displayName: 'Sam Vale'),
          isMobile: false,
        ),
      );

      expect(find.text('Sam Vale'), findsOneWidget);
      expect(find.byType(PlaceholderAvatar), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(ThemedMarkdown), findsNothing);
    });
  });

  group('Issue 53: CoachCard on a phone', () {
    testWidgets('Issue 53: a coach with no avatar gets a square placeholder '
        'above the text', (tester) async {
      await _pump(
        tester,
        const CoachCard(
          coach: PublicProfile(publicId: 'pc-2', displayName: 'Sam Vale'),
          isMobile: true,
        ),
      );

      expect(tester.takeException(), isNull);
      final placeholder = tester.getSize(find.byType(PlaceholderAvatar));
      expect(placeholder.width, placeholder.height);
      expect(
        tester.getTopLeft(find.byType(PlaceholderAvatar)).dy,
        lessThan(tester.getTopLeft(find.text('Sam Vale')).dy),
      );
    });
  });

  group('Issue 53: CoachesCardList', () {
    testWidgets('Issue 53: one card per coach', (tester) async {
      await _pump(
        tester,
        const CoachesCardList(
          coaches: [
            _coach,
            PublicProfile(publicId: 'pc-2', displayName: 'Sam Vale'),
          ],
        ),
      );

      expect(find.byType(CoachCard), findsNWidgets(2));
    });
  });
}
