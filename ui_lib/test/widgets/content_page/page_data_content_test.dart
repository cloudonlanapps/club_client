import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

// No hero image and no fallback: the hero collapses, so nothing here needs
// the ProviderScope its media would.
const page = PageData(
  hero: PageHeroData(title: 'Camps'),
  emptyState: PageEmptyStateData(
    iconName: 'sparkles',
    title: 'Nothing yet',
    description: 'Check back soon.',
    buttonText: 'Tell me',
  ),
  cta: PageCtaData(
    title: 'Join us',
    description: 'Sign up today.',
    primaryButtonText: 'Sign up',
    primaryRoute: '/signup',
    secondaryButtonText: 'Other camps',
    secondaryRoute: '/camps',
  ),
);

Future<void> pumpPage(WidgetTester tester, PageDataContent content) async {
  tester.view.physicalSize = const Size(1280, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(body: SingleChildScrollView(child: content)),
    ),
  );
}

void main() {
  group('Issue 157: PageDataContent navigates through its host', () {
    testWidgets('Issue 157: a CTA button hands its route to onNavigate', (
      tester,
    ) async {
      final routes = <String>[];
      await pumpPage(
        tester,
        PageDataContent(
          pageData: page,
          activeContent: const Text('the camps'),
          onNavigate: routes.add,
        ),
      );

      await tester.tap(find.text('Sign up'));
      await tester.tap(find.text('Other camps'));

      expect(routes, ['/signup', '/camps']);
    });

    testWidgets(
      "Issue 157: the empty state's button calls onEmptyStateAction",
      (tester) async {
        var pressed = 0;
        await pumpPage(
          tester,
          PageDataContent(
            pageData: page,
            onEmptyStateAction: () => pressed++,
          ),
        );

        expect(find.text('Nothing yet'), findsOneWidget);
        await tester.tap(find.text('Tell me'));

        expect(pressed, 1);
      },
    );
  });
}
