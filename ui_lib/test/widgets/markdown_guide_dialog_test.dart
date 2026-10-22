import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/markdown/markdown_composer_field.dart';
import 'package:ui_lib/src/widgets/markdown/markdown_editor_dialog.dart';
import 'package:ui_lib/src/widgets/markdown/markdown_guide_dialog.dart';

Future<void> openGuideAndClose(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Markdown help'));
  await tester.pumpAndSettle();
  expect(find.byType(MarkdownGuideDialog), findsOneWidget);
  expect(find.text('Markdown Guide'), findsOneWidget);
  expect(find.byType(HelpRow), findsNWidgets(7));

  await tester.tap(find.text('Close'));
  await tester.pumpAndSettle();
  expect(find.byType(MarkdownGuideDialog), findsNothing);
}

void main() {
  testWidgets(
    'Issue 247: the markdown editor dialog opens the shared Markdown Guide',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => MarkdownEditorDialog.show(
                  context,
                  label: 'Bio',
                  initialValue: '',
                  onSave: (_) {},
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await openGuideAndClose(tester);
      expect(
        find.byType(MarkdownEditorDialog),
        findsOneWidget,
        reason: 'closing the guide leaves the editor open',
      );
    },
  );

  testWidgets(
    'Issue 247: the markdown composer field opens the shared Markdown Guide',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(body: MarkdownComposerField(controller: controller)),
        ),
      );

      await openGuideAndClose(tester);
      expect(find.byType(MarkdownComposerField), findsOneWidget);
    },
  );
}
