import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

void main() {
  testWidgets('Issue 47: renders the title and one list per group', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: MobileMenuDrawer(
            title: 'Navigate',
            menuItemGroups: [
              [BorderedMenuItem(label: 'Home', onTap: () {})],
              [
                BorderedMenuItem(label: 'Events', onTap: () {}),
                BorderedMenuItem(label: 'Rinks', onTap: () {}),
              ],
            ],
          ),
        ),
      ),
    );

    expect(find.text('Navigate'), findsOneWidget);
    expect(find.byType(BorderedMenuList), findsNWidgets(2));
    for (final label in ['Home', 'Events', 'Rinks']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  group('Issue 184: footer items', () {
    Future<void> pump(
      WidgetTester tester, {
      List<BorderedMenuItem> footerItems = const [],
    }) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: MobileMenuDrawer(
              menuItemGroups: [
                [BorderedMenuItem(label: 'Home', onTap: () {})],
                [BorderedMenuItem(label: 'Contact', onTap: () {})],
              ],
              footerItems: footerItems,
            ),
          ),
        ),
      );
    }

    testWidgets('Issue 184: footer items form their own list at the bottom', (
      tester,
    ) async {
      await pump(
        tester,
        footerItems: [BorderedMenuItem(label: 'Members', onTap: () {})],
      );

      expect(find.byType(BorderedMenuList), findsNWidgets(3));
      final footer = tester.getRect(
        find.ancestor(
          of: find.text('Members'),
          matching: find.byType(BorderedMenuList),
        ),
      );
      final contact = tester.getRect(find.text('Contact'));
      expect(footer.top, greaterThan(contact.bottom));
      // Pinned to the bottom: only the drawer's padding lies below it.
      expect(900 - footer.bottom, lessThanOrEqualTo(32));
    });

    testWidgets('Issue 184: no footer items means no footer list', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byType(BorderedMenuList), findsNWidgets(2));
    });
  });
}
