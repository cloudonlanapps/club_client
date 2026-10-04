import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/evaluation/layout/evaluation_add_bar.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

class _Host {
  List<List<EvaluationLayoutEntry>> emitted = [];
  List<EvaluationItemValue> edited = [];
  List<String?> sectionTitles = [];
  List<EvaluationItemValue> viewed = [];
  EvaluationOutlineEdit<EvaluationItemValue>? Function(EvaluationItemValue)
  itemResult = (_) => null;
  EvaluationOutlineEdit<String>? sectionResult;

  Future<void> pump(
    WidgetTester tester, {
    List<EvaluationLayoutEntry> layout = sampleLayout,
    bool readOnly = false,
  }) async {
    await tallSurface(tester);
    await tester.pumpWidget(
      wrapEvaluation(
        EvaluationLayoutEditor(
          layout: layout,
          readOnly: readOnly,
          onLayoutChanged: emitted.add,
          onEditItem: (item) async {
            edited.add(item);
            return itemResult(item);
          },
          onEditSectionTitle: (title) async {
            sectionTitles.add(title);
            return sectionResult;
          },
          onViewItem: (item) async => viewed.add(item),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Finder _mainAddBar() => find.descendant(
  of: find.byType(EvaluationAddBar).last,
  matching: find.byType(ShadButton),
);

void main() {
  group('Issue 173: EvaluationLayoutEditor', () {
    testWidgets('Issue 173: Sort reveals the up and down arrows', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester);
      expect(find.byIcon(LucideIcons.arrowUp), findsNothing);
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      // One pair per row: info, section, two section items, Q & A.
      expect(find.byIcon(LucideIcons.arrowUp), findsNWidgets(5));
    });

    testWidgets('Issue 173: an arrow emits the reordered layout', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester);
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.arrowDown).first);
      await tester.pumpAndSettle();
      expect(host.emitted.single.first.sectionItems.first, infoItem);
    });

    testWidgets('Issue 173: rows carry no delete action, sorting or not', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester);
      expect(find.byIcon(LucideIcons.trash2), findsNothing);
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.trash2), findsNothing);
    });

    testWidgets('Issue 173: a Delete from the item dialog emits the layout '
        'without the row', (tester) async {
      final host = _Host()
        ..itemResult = (_) => const EvaluationOutlineEdit.delete();
      await host.pump(tester);
      await tester.tap(find.text('What to work on next'));
      await tester.pumpAndSettle();
      expect(EvaluationLayoutEntry.flatten(host.emitted.single), const [
        infoItem,
        levelsItem,
        yesNoItem,
      ]);
    });

    testWidgets('Issue 173: a Delete from the section dialog keeps its '
        'items', (tester) async {
      final host = _Host()
        ..sectionResult = const EvaluationOutlineEdit.delete();
      await host.pump(tester);
      await tester.tap(find.text('Skating'));
      await tester.pumpAndSettle();
      expect(host.sectionTitles.single, 'Skating');
      expect(host.emitted.single, const [
        EvaluationLayoutEntry.item(infoItem),
        EvaluationLayoutEntry.item(levelsItem),
        EvaluationLayoutEntry.item(yesNoItem),
        EvaluationLayoutEntry.item(qaItem),
      ]);
    });

    testWidgets('Issue 173: a Delete while adding adds nothing', (
      tester,
    ) async {
      final host = _Host()
        ..itemResult = (_) => const EvaluationOutlineEdit.delete();
      await host.pump(tester, layout: const []);
      await tester.tap(_mainAddBar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rating'));
      await tester.pumpAndSettle();
      expect(host.emitted, isEmpty);
    });

    testWidgets('Issue 173: tapping a row edits it in place', (tester) async {
      final host = _Host()
        ..itemResult = (item) =>
            EvaluationOutlineEdit.update(item.copyWith(text: 'Stride length'));
      await host.pump(tester);
      await tester.tap(find.text('Forward stride'));
      await tester.pumpAndSettle();
      expect(host.edited.single, levelsItem);
      expect(host.emitted.single[1].sectionItems.first.text, 'Stride length');
    });

    testWidgets('Issue 173: a cancelled edit emits nothing', (tester) async {
      final host = _Host();
      await host.pump(tester);
      await tester.tap(find.text('Forward stride'));
      await tester.pumpAndSettle();
      expect(host.edited, hasLength(1));
      expect(host.emitted, isEmpty);
    });

    testWidgets('Issue 173: the add bar has no Add text and adds a kind', (
      tester,
    ) async {
      final host = _Host()
        ..itemResult = (item) =>
            EvaluationOutlineEdit.update(item.copyWith(text: 'New'));
      await host.pump(tester, layout: const []);
      expect(find.text('Add'), findsNothing);
      await tester.tap(_mainAddBar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rating'));
      await tester.pumpAndSettle();
      expect(host.edited.single.kind, EvaluationItemKind.rating);
      expect(host.edited.single.id, isNull);
      expect(
        EvaluationLayoutEntry.flatten(host.emitted.single).single.text,
        'New',
      );
    });

    testWidgets('Issue 173: the add bar adds a titled section', (
      tester,
    ) async {
      final host = _Host()
        ..sectionResult = const EvaluationOutlineEdit.update('Passing');
      await host.pump(tester, layout: const []);
      await tester.tap(_mainAddBar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Section'));
      await tester.pumpAndSettle();
      expect(host.sectionTitles.single, isNull);
      expect(
        host.emitted.single.single,
        const EvaluationLayoutEntry.section(title: 'Passing'),
      );
    });

    testWidgets('Issue 173: read-only shows no Sort, add or delete', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester, readOnly: true);
      expect(find.text('Sort'), findsNothing);
      expect(find.byType(EvaluationAddBar), findsNothing);
      expect(find.byIcon(LucideIcons.trash2), findsNothing);
      expect(find.text('Skating'), findsOneWidget);
    });

    testWidgets('Issue 173: read-only opens an item to view, never to edit, '
        'and a section not at all', (tester) async {
      final host = _Host();
      await host.pump(tester, readOnly: true);
      await tester.tap(find.text('Forward stride'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skating'));
      await tester.pumpAndSettle();
      expect(host.viewed, [levelsItem]);
      expect(host.edited, isEmpty);
      expect(host.sectionTitles, isEmpty);
      expect(host.emitted, isEmpty);
    });
  });
}
