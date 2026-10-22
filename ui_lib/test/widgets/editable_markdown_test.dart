import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/markdown/markdown_editor_dialog.dart';

Future<void> openEditor(
  WidgetTester tester, {
  Size? surfaceSize,
  String initial = '',
  ValueChanged<String>? onSave,
}) async {
  if (surfaceSize != null) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = surfaceSize;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
  }
  await tester.pumpWidget(
    ShadApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => MarkdownEditorDialog.show(
                ctx,
                label: 'Bio',
                initialValue: initial,
                onSave: onSave ?? (_) {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Issue 254: editor renders as constrained dialog, not fullscreen',
    (tester) async {
      await openEditor(tester, surfaceSize: const Size(1280, 900));

      expect(find.byType(MarkdownEditorDialog), findsOneWidget);
      expect(
        find.byType(Scaffold),
        findsOneWidget, // only the host scaffold
        reason: 'editor should not introduce its own Scaffold',
      );
      expect(
        find.byType(AppBar),
        findsNothing,
        reason: 'editor should not use an AppBar',
      );

      final dialogSize = tester.getSize(
        find.byKey(const Key('markdownEditorDialogFrame')),
      );
      expect(
        dialogSize.width,
        lessThanOrEqualTo(MarkdownEditorDialog.maxDialogWidth),
        reason: 'wide layouts cap dialog width at maxDialogWidth',
      );
      expect(
        dialogSize.width,
        lessThan(1280),
        reason: 'dialog must not span the full viewport on desktop',
      );
      expect(
        dialogSize.height,
        lessThan(900),
        reason: 'dialog must not span the full viewport height',
      );
    },
  );

  testWidgets('Issue 254: editor shows label, save, and cancel actions', (
    tester,
  ) async {
    await openEditor(
      tester,
      surfaceSize: const Size(1280, 900),
      initial: 'hello',
    );

    expect(find.text('Bio'), findsOneWidget);
    expect(find.widgetWithText(ShadButton, 'Save'), findsOneWidget);
    expect(find.widgetWithText(ShadButton, 'Cancel'), findsOneWidget);
  });

  testWidgets('Issue 254: save invokes onSave with edited markdown', (
    tester,
  ) async {
    String? saved;
    await openEditor(
      tester,
      surfaceSize: const Size(1280, 900),
      initial: 'old',
      onSave: (v) => saved = v,
    );

    await tester.enterText(find.byType(TextField), 'new content');
    await tester.pump();
    await tester.tap(find.widgetWithText(ShadButton, 'Save'));
    await tester.pumpAndSettle();

    expect(saved, 'new content');
    expect(
      find.byType(MarkdownEditorDialog),
      findsNothing,
      reason: 'editor closes after save',
    );
  });

  testWidgets('Issue 254: cancel without edits closes immediately', (
    tester,
  ) async {
    await openEditor(tester, surfaceSize: const Size(1280, 900));

    await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownEditorDialog), findsNothing);
  });

  testWidgets('Issue 254: narrow viewport uses smaller inset padding', (
    tester,
  ) async {
    await openEditor(tester, surfaceSize: const Size(400, 800));

    final size = tester.getSize(
      find.byKey(const Key('markdownEditorDialogFrame')),
    );
    // narrow inset is 16 on each side → dialog width = 400 - 32 = 368
    expect(
      size.width,
      400 - 2 * MarkdownEditorDialog.narrowInsetPadding,
      reason: 'narrow layouts use narrowInsetPadding, not the wide value',
    );
  });

  testWidgets(
    'Issue 241: with edited text, Escape asks "Discard changes?" and keeps '
    'the editor open',
    (tester) async {
      await openEditor(tester, surfaceSize: const Size(1280, 900));
      await tester.enterText(find.byType(TextField), 'typed text');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.byType(MarkdownEditorDialog), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.byType(MarkdownEditorDialog), findsOneWidget);
      expect(find.text('typed text'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byType(MarkdownEditorDialog), findsNothing);
    },
  );

  testWidgets(
    'Issue 241: with edited text, system back asks "Discard changes?"',
    (tester) async {
      await openEditor(tester, surfaceSize: const Size(1280, 900));
      await tester.enterText(find.byType(TextField), 'typed text');
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.byType(MarkdownEditorDialog), findsOneWidget);
    },
  );

  testWidgets('Issue 241: unedited, Escape closes the editor directly', (
    tester,
  ) async {
    await openEditor(
      tester,
      surfaceSize: const Size(1280, 900),
      initial: 'hello',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byType(MarkdownEditorDialog), findsNothing);
  });

  testWidgets(
    'Issue 166: portrait phone with the keyboard up, the editor fits above '
    'the keyboard and scrolls inside',
    (tester) => expectEditorUsableAboveKeyboard(
      tester,
      screen: const Size(360, 640),
      keyboard: 280,
    ),
  );

  testWidgets(
    'Issue 166: landscape phone with the keyboard up, the editor does not '
    'overflow and keeps a usable text box',
    (tester) => expectEditorUsableAboveKeyboard(
      tester,
      screen: const Size(640, 360),
      keyboard: 180,
    ),
  );
}

/// Four lines of text plus the field's padding.
const double usableEditorHeight = 96;

/// Opens the editor on [screen], raises a keyboard of [keyboard] logical
/// pixels the way a mobile browser does (the size stays, the bottom inset
/// grows), types past the box's height, and checks that nothing overflows,
/// the text box keeps a usable height and the line being typed is in view.
Future<void> expectEditorUsableAboveKeyboard(
  WidgetTester tester, {
  required Size screen,
  required double keyboard,
}) async {
  await openEditor(tester, surfaceSize: screen);

  await tester.tap(find.byType(TextField));
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpAndSettle();

  final lines = List.generate(30, (i) => 'line ${i + 1}').join('\n');
  await tester.enterText(find.byType(TextField), lines);
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull, reason: 'no overflow');

  final frame = tester.getRect(
    find.byKey(const Key('markdownEditorDialogFrame')),
  );
  expect(
    frame.bottom,
    lessThanOrEqualTo(screen.height - keyboard),
    reason: 'the dialog sits above the keyboard',
  );

  final field = tester.getRect(find.byType(TextField));
  expect(
    field.height,
    greaterThanOrEqualTo(usableEditorHeight),
    reason: 'the text box keeps a usable height',
  );

  final editable = tester
      .state<EditableTextState>(find.byType(EditableText))
      .renderEditable;
  final caret = MatrixUtils.transformRect(
    editable.getTransformTo(null),
    editable.getLocalRectForCaret(TextPosition(offset: lines.length)),
  );
  final visible = frame.intersect(field);
  expect(
    caret.top,
    greaterThanOrEqualTo(visible.top),
    reason: 'the line being typed is in view',
  );
  expect(
    caret.bottom,
    lessThanOrEqualTo(visible.bottom),
    reason: 'the line being typed is in view',
  );
}
