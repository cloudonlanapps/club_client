import 'package:cl_club_app/src/screens/contact_screen.dart';
import 'package:cl_club_branding/cl_club_branding.dart' show appLogoUriProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ContactInfo, contactInfoProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show LocalizedText;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _contact = ContactInfo(
  clubName: 'Test Club',
  phoneNumber: '+911234567890',
  email: 'club@example.test',
  whatsappNumber: '+919876543210',
  addressLine1: LocalizedText('1 Rink Road'),
  city: LocalizedText('Pune'),
  postalCode: '411000',
);

Future<void> _pump(WidgetTester tester, {required Size size}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contactInfoProvider.overrideWithValue(_contact),
        // An unknown scheme renders the logo as an empty box, no image load.
        appLogoUriProvider.overrideWithValue(Uri.parse('none:logo')),
      ],
      child: ShadApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  const Scaffold(body: ContactScreen()),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('Issue 53: ContactScreen', () {
    testWidgets('Issue 53: renders contactInfoProvider at once', (
      tester,
    ) async {
      await _pump(tester, size: const Size(1280, 900));

      expect(find.text('+919876543210'), findsOneWidget);
      expect(find.text('+911234567890'), findsOneWidget);
      expect(find.text('club@example.test'), findsOneWidget);
      expect(find.text('1 Rink Road'), findsOneWidget);
      expect(find.text('Pune, 411000'), findsOneWidget);
    });

    testWidgets("Issue 53: the mobile header names the provider's club", (
      tester,
    ) async {
      await _pump(tester, size: const Size(400, 1200));

      expect(find.text('Test Club'), findsOneWidget);
    });
  });
}
