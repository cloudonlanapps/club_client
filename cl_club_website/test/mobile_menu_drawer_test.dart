import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_club_website/src/site/widgets/mobile_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show BorderedMenuList;

const _memberArea = 'Member Area';

Future<void> _pump(WidgetTester tester, Uri? memberApp) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [memberAppUriProvider.overrideWithValue(memberApp)],
      child: ShadApp(
        home: SiteStringsScope(
          strings: SiteStrings(const {
            'navMemberApp': _memberArea,
            'navContactUs': 'Speak to Us',
          }),
          child: const Scaffold(body: MobileMenuDrawer()),
        ),
      ),
    ),
  );
}

Finder _listOf(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(BorderedMenuList),
);

void main() {
  group('Issue 184: Member Area in the side menu', () {
    testWidgets('Issue 184: Member Area is its own block at the bottom', (
      tester,
    ) async {
      await _pump(tester, Uri.parse('https://member.example.test'));

      expect(find.text(_memberArea), findsOneWidget);
      final memberList = tester.widget<BorderedMenuList>(_listOf(_memberArea));
      expect(memberList.items.map((i) => i.label), [_memberArea]);
      expect(
        tester.getRect(_listOf(_memberArea)).top,
        greaterThan(tester.getRect(_listOf('Speak to Us')).bottom),
      );
    });

    testWidgets('Issue 184: no member app means no bottom block', (
      tester,
    ) async {
      await _pump(tester, null);

      expect(find.text(_memberArea), findsNothing);
      expect(find.byType(BorderedMenuList), findsNWidgets(2));
    });
  });
}
