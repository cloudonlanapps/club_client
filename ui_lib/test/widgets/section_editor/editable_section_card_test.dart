import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// Pumps an [EditableSectionCard] with controllable validate / dirty / save
/// behaviour and records the values passed to `onSave`.
Future<List<String>> _pumpCard(
  WidgetTester tester, {
  required bool canEdit,
  String? validateResult = 'value',
  bool isDirty = true,
  bool saveSucceeds = true,
  bool isEmpty = false,
  String? emptyHint,
}) async {
  final saved = <String>[];
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: EditableSectionCard<String>(
          title: 'Demo',
          canEdit: canEdit,
          isEmpty: isEmpty,
          emptyHint: emptyHint,
          read: const Text('READ MODE'),
          editBuilder: () => const Text('EDIT FORM'),
          onValidate: () => validateResult,
          isDirty: () => isDirty,
          onSave: (value) async {
            saved.add(value);
            return saveSucceeds;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return saved;
}

void main() {
  testWidgets('Issue 673: pencil hidden when canEdit is false', (tester) async {
    await _pumpCard(tester, canEdit: false);
    expect(find.byIcon(LucideIcons.pencil), findsNothing);
    expect(find.text('READ MODE'), findsOneWidget);
  });

  testWidgets('Issue 673: pencil shown when canEdit is true', (tester) async {
    await _pumpCard(tester, canEdit: true);
    expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
  });

  testWidgets('Issue 673: tapping pencil enters inline edit mode with '
      'Save/Cancel', (tester) async {
    await _pumpCard(tester, canEdit: true);
    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();

    expect(find.text('EDIT FORM'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    // Pencil is hidden while editing.
    expect(find.byIcon(LucideIcons.pencil), findsNothing);
  });

  testWidgets('Issue 673: Cancel returns to read mode without saving', (
    tester,
  ) async {
    final saved = await _pumpCard(tester, canEdit: true);
    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('READ MODE'), findsOneWidget);
    expect(find.text('EDIT FORM'), findsNothing);
    expect(saved, isEmpty);
  });

  testWidgets('Issue 673: invalid form keeps edit mode open, does not save', (
    tester,
  ) async {
    // onValidate returns null → invalid.
    final saved = await _pumpCard(
      tester,
      canEdit: true,
      validateResult: null,
    );
    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('EDIT FORM'), findsOneWidget); // still editing
    expect(saved, isEmpty);
  });

  testWidgets(
    'Issue 673: unchanged Save is a no-op that exits without saving',
    (tester) async {
      final saved = await _pumpCard(tester, canEdit: true, isDirty: false);
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('READ MODE'), findsOneWidget); // exited edit mode
      expect(saved, isEmpty); // onSave never called
    },
  );

  testWidgets(
    'Issue 673: dirty + valid Save calls onSave and exits on success',
    (tester) async {
      final saved = await _pumpCard(tester, canEdit: true);
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, ['value']);
      expect(find.text('READ MODE'), findsOneWidget);
    },
  );

  testWidgets('Issue 673: empty section is hidden from a read-only viewer', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      canEdit: false,
      isEmpty: true,
      emptyHint: 'Tap to add demo',
    );
    // The whole card is gone — no title, no read content, no hint.
    expect(find.text('Demo'), findsNothing);
    expect(find.text('READ MODE'), findsNothing);
    expect(find.text('Tap to add demo'), findsNothing);
    expect(find.byIcon(LucideIcons.pencil), findsNothing);
  });

  testWidgets('Issue 673: empty section shows a tap-to-add hint to an editor '
      'and tapping it enters edit mode', (tester) async {
    await _pumpCard(
      tester,
      canEdit: true,
      isEmpty: true,
      emptyHint: 'Tap to add demo',
    );
    // The section is visible with the add hint (and the pencil).
    expect(find.text('Demo'), findsOneWidget);
    expect(find.text('Tap to add demo'), findsOneWidget);
    expect(find.byIcon(LucideIcons.pencil), findsOneWidget);

    // Tapping the hint enters edit mode.
    await tester.tap(find.text('Tap to add demo'));
    await tester.pumpAndSettle();
    expect(find.text('EDIT FORM'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('Issue 673: failed Save keeps edit mode open', (tester) async {
    final saved = await _pumpCard(
      tester,
      canEdit: true,
      saveSucceeds: false,
    );
    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, ['value']);
    expect(find.text('EDIT FORM'), findsOneWidget); // still editing for retry
  });
}
