import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/confirm_dialog.dart';
import 'package:ui_lib/src/widgets/discard_changes_prompt.dart';

/// Opens the prompt; the list fills with what it resolves to.
Future<List<bool>> _open(WidgetTester tester) async {
  final answers = <bool>[];
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ShadButton(
            onPressed: () async =>
                answers.add(await DiscardChangesPrompt.show(context)),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return answers;
}

void main() {
  group('Issue 98: the shared discard prompt', () {
    testWidgets('Issue 98: it is a ConfirmDialog with the one wording', (
      tester,
    ) async {
      await _open(tester);

      expect(find.byType(ConfirmDialog), findsOneWidget);
      expect(find.text(DiscardChangesPrompt.title), findsOneWidget);
      expect(find.text(DiscardChangesPrompt.message), findsOneWidget);
      expect(
        find.widgetWithText(ShadButton, DiscardChangesPrompt.discardLabel),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ShadButton, DiscardChangesPrompt.keepEditingLabel),
        findsOneWidget,
      );
    });

    testWidgets('Issue 98: Discard resolves to true', (tester) async {
      final answers = await _open(tester);

      await tester.tap(find.text(DiscardChangesPrompt.discardLabel));
      await tester.pumpAndSettle();

      expect(answers, [true]);
      expect(find.byType(ConfirmDialog), findsNothing);
    });

    testWidgets('Issue 98: Keep editing resolves to false', (tester) async {
      final answers = await _open(tester);

      await tester.tap(find.text(DiscardChangesPrompt.keepEditingLabel));
      await tester.pumpAndSettle();

      expect(answers, [false]);
      expect(find.byType(ConfirmDialog), findsNothing);
    });
  });
}
