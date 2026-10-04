import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_club_website/src/icons/brand_icons.dart';
import 'package:cl_club_website/src/widgets/instagram_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<void> _pumpMark(WidgetTester tester) async {
  await tester.pumpWidget(
    const ShadApp(
      home: Scaffold(body: Center(child: InstagramMark(size: 20))),
    ),
  );
  // The asset load fails asynchronously; let it settle so the error
  // builder runs.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

void main() {
  group('Issue 57: the Instagram mark is a host asset', () {
    testWidgets(
      'Issue 57: renders the host asset at the conventional path',
      (tester) async {
        await _pumpMark(tester);

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.image, isA<AssetImage>());
        expect((image.image as AssetImage).assetName, kInstagramMarkAsset);
        expect(kInstagramMarkAsset, 'assets/images/instagram.png');
      },
    );

    testWidgets(
      'Issue 57: falls back to the placeholder icon when the host ships none',
      (tester) async {
        await _pumpMark(tester);

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, BrandIcons.instagram);
        expect(icon.size, 20);
      },
    );
  });
}
