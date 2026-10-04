import 'package:cl_club_branding/cl_club_branding.dart'
    show initialThemeModeProvider;
import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_club_website/src/widgets/hero_top_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _drawerText = 'side menu';

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  Uri? memberApp,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        memberAppUriProvider.overrideWithValue(memberApp),
      ],
      child: ShadApp(
        home: SiteStringsScope(
          strings: SiteStrings(const {
            'navMenu': 'Menu',
            'navMemberApp': 'Members',
          }),
          child: const Scaffold(
            endDrawer: Drawer(child: Text(_drawerText)),
            body: Align(alignment: Alignment.topRight, child: HeroTopActions()),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Issue 180: the landing hero offers the menu', () {
    for (final (label, size) in [
      ('mobile', const Size(390, 800)),
      ('tablet', const Size(900, 800)),
      ('desktop', const Size(1440, 900)),
    ]) {
      testWidgets('Issue 180: the menu button opens the side menu on $label', (
        tester,
      ) async {
        await _pump(tester, size);

        expect(find.byIcon(LucideIcons.menu), findsOneWidget);
        expect(find.bySemanticsLabel('Menu'), findsOneWidget);
        expect(find.text(_drawerText), findsNothing);

        await tester.tap(find.byIcon(LucideIcons.menu));
        await tester.pumpAndSettle();

        expect(find.text(_drawerText), findsOneWidget);
      });
    }

    testWidgets('Issue 180: the theme toggle stays beside the menu', (
      tester,
    ) async {
      await _pump(tester, const Size(1440, 900));
      expect(find.byIcon(LucideIcons.moon), findsOneWidget);
    });
  });

  group('Issue 184: the landing hero has no user icon', () {
    testWidgets('Issue 184: its menu carries the Member Area instead', (
      tester,
    ) async {
      await _pump(
        tester,
        const Size(1440, 900),
        memberApp: Uri.parse('https://member.example.test'),
      );
      expect(find.byIcon(LucideIcons.circleUser), findsNothing);
      expect(find.byIcon(LucideIcons.menu), findsOneWidget);
    });
  });
}
