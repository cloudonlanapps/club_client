import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  testWidgets(
    'Issue 740: edit mode shows a TextField; preview toggle renders the '
    'markdown and back',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TextEditingController(text: 'Say **hi**');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(MarkdownComposerField(controller: controller)),
      );

      // Starts in edit mode: a TextField is shown, no rendered markdown yet.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ThemedMarkdown), findsNothing);

      // Tap the preview (eye) toggle.
      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pumpAndSettle();

      // Preview mode: markdown is rendered, the editor TextField is gone.
      expect(find.byType(ThemedMarkdown), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Say **hi**'), findsNothing); // syntax not shown raw

      // Toggle back to edit (pencil) restores the TextField.
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ThemedMarkdown), findsNothing);
    },
  );

  testWidgets(
    'Issue 740: empty controller previews a placeholder instead of markdown',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(MarkdownComposerField(controller: controller)),
      );

      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pumpAndSettle();

      expect(find.text('Nothing to preview'), findsOneWidget);
      expect(find.byType(ThemedMarkdown), findsNothing);
    },
  );
}
