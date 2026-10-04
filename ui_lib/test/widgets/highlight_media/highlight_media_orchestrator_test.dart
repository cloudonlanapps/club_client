import 'package:cl_gallery_viewer/cl_gallery_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

/// Builds [orchestrator] against a live context and returns the tree it
/// produces, without mounting it: [HighlightMedia] needs a ProviderScope,
/// which ui_lib (Riverpod-free) does not provide.
Future<Widget> buildOnce(
  WidgetTester tester,
  HighlightMediaOrchestrator orchestrator,
) async {
  late Widget built;
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        built = orchestrator.build(context);
        return const SizedBox.shrink();
      },
    ),
  );
  return built;
}

void main() {
  testWidgets(
    'Issue 47: isVideo true takes the video path for a URL with no extension',
    (tester) async {
      final built = await buildOnce(
        tester,
        const HighlightMediaOrchestrator(
          uri: 'https://example.test/media/1/download',
          isVideo: true,
        ),
      );

      final backdrop = (built as ClipRRect).child! as ColoredBox;
      expect(backdrop.color, Colors.black);
      final media = (backdrop.child! as Stack).children.first as HighlightMedia;
      expect(media.url, 'https://example.test/media/1/download');
      expect(media.playerFactory, isNotNull);
    },
  );

  testWidgets(
    'Issue 47: isVideo false takes the image path for a video extension',
    (tester) async {
      final built = await buildOnce(
        tester,
        const HighlightMediaOrchestrator(
          uri: 'https://example.test/clip.mp4',
          isVideo: false,
        ),
      );

      final media = (built as ClipRRect).child! as HighlightMedia;
      expect(media.url, 'https://example.test/clip.mp4');
      expect(media.playerFactory, isNull);
    },
  );
}
