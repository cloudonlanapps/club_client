import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_club_website/src/site/widgets/member_app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<void> _pump(WidgetTester tester, Uri? memberApp) => tester.pumpWidget(
  ProviderScope(
    overrides: [memberAppUriProvider.overrideWithValue(memberApp)],
    child: ShadApp(
      home: SiteStringsScope(
        strings: SiteStrings(const {'navMemberApp': 'Members'}),
        child: const Scaffold(body: MemberAppButton()),
      ),
    ),
  ),
);

void main() {
  group('Issue 179: MemberAppButton', () {
    testWidgets('Issue 179: shows a user icon when the app URL is set', (
      tester,
    ) async {
      await _pump(tester, Uri.parse('https://member.example.test'));
      expect(find.byIcon(LucideIcons.circleUser), findsOneWidget);
      expect(find.bySemanticsLabel('Members'), findsOneWidget);
    });

    testWidgets('Issue 179: renders nothing without an app URL', (
      tester,
    ) async {
      await _pump(tester, null);
      expect(find.byIcon(LucideIcons.circleUser), findsNothing);
    });
  });
}
