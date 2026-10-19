import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/section_editor/section_editor_actions.dart';
import 'package:ui_lib/ui_lib.dart';

Future<List<bool>> _pump(
  WidgetTester tester, {
  bool Function()? isDirty,
  Future<bool> Function(String)? onSave,
}) async {
  final changes = <bool>[];
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: EditableSectionCard<String>(
          title: 'Basic',
          canEdit: true,
          read: const Text('read'),
          editBuilder: ({required enabled}) => const Text('editing'),
          onValidate: () => 'value',
          isDirty: isDirty,
          onSave: onSave ?? (_) async => true,
          onEditingChanged: changes.add,
        ),
      ),
    ),
  );
  return changes;
}

void main() {
  group(
    'Issue 1: EditableSectionCard says when its editor opens and closes',
    () {
      testWidgets('Issue 1: opening, then Cancel', (tester) async {
        final changes = await _pump(tester);

        await tester.tap(find.byType(SectionEditButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(SectionEditorActions.cancelLabel));
        await tester.pumpAndSettle();

        expect(changes, [true, false]);
      });

      testWidgets('Issue 1: a save that is stored closes it', (tester) async {
        final changes = await _pump(tester, isDirty: () => true);

        await tester.tap(find.byType(SectionEditButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(SectionEditorActions.saveLabel));
        await tester.pumpAndSettle();

        expect(changes, [true, false]);
      });

      testWidgets('Issue 1: a refused save leaves it open', (tester) async {
        final changes = await _pump(
          tester,
          isDirty: () => true,
          onSave: (_) async => false,
        );

        await tester.tap(find.byType(SectionEditButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(SectionEditorActions.saveLabel));
        await tester.pumpAndSettle();

        expect(changes, [true]);
      });
    },
  );
}
