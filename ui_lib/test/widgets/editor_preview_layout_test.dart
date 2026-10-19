import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

Future<void> _pump(WidgetTester tester, double width) async {
  await tester.binding.setSurfaceSize(Size(width, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    const ShadApp(
      home: Scaffold(
        body: EditorPreviewLayout(
          editor: ShadInput(key: Key('editor')),
          preview: Text('the preview'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 28: EditorPreviewLayout', () {
    testWidgets('Issue 28: a wide screen shows both sides and no switch', (
      tester,
    ) async {
      await _pump(tester, EditorPreviewLayout.sideBySideMinWidth);
      expect(find.byKey(const Key('editor')), findsOneWidget);
      expect(find.text('the preview'), findsOneWidget);
      expect(find.text('Preview'), findsNothing);
      final editor = tester.getRect(find.byKey(const Key('editor')));
      final preview = tester.getRect(find.text('the preview'));
      expect(preview.left, greaterThan(editor.left));
    });

    testWidgets('Issue 28: a narrow screen switches between the sides and '
        'keeps what was typed', (tester) async {
      await _pump(tester, 400);
      expect(find.byKey(const Key('editor')), findsOneWidget);
      expect(find.text('the preview'), findsNothing);
      await tester.enterText(find.byKey(const Key('editor')), 'typed');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(find.text('the preview'), findsOneWidget);
      expect(find.byKey(const Key('editor')), findsNothing);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('typed'), findsOneWidget);
    });
  });
}
