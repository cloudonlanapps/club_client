import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// Pumps an [EditableSectionCard] whose form shows what the card told it
/// (`FORM ON` / `FORM OFF`) and whose save is [onSave], then opens the
/// editor.
Future<void> _pumpEditing(
  WidgetTester tester, {
  required Future<bool> Function(String value) onSave,
}) async {
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: EditableSectionCard<String>(
          title: 'Demo',
          canEdit: true,
          read: const Text('READ MODE'),
          editBuilder: ({required enabled}) =>
              Text(enabled ? 'FORM ON' : 'FORM OFF'),
          onValidate: () => 'value',
          onSave: onSave,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(LucideIcons.pencil));
  await tester.pumpAndSettle();
}

/// The editor's actions, Cancel then Save. Save shows a spinner in place of
/// its label while the save is in flight, so they are found by position.
ShadButton _cancel(WidgetTester tester) =>
    tester.widget<ShadButton>(find.byType(ShadButton).first);

ShadButton _save(WidgetTester tester) =>
    tester.widget<ShadButton>(find.byType(ShadButton).last);

void main() {
  group('Issue 91: the card turns its form off while it saves', () {
    testWidgets('Issue 91: the form is on when the editor opens', (
      tester,
    ) async {
      await _pumpEditing(tester, onSave: (_) async => true);

      expect(find.text('FORM ON'), findsOneWidget);
    });

    testWidgets('Issue 91: the form is off while the save is in flight and '
        'on again when it is refused', (tester) async {
      final answer = Completer<bool>();
      await _pumpEditing(tester, onSave: (_) => answer.future);

      await tester.tap(find.widgetWithText(ShadButton, 'Save'));
      await tester.pump();
      expect(find.text('FORM OFF'), findsOneWidget);
      expect(find.text('FORM ON'), findsNothing);

      answer.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('FORM ON'), findsOneWidget);
      expect(find.text('FORM OFF'), findsNothing);
    });

    testWidgets('Issue 91: the form is off while the save is in flight and '
        'the editor closes when it is stored', (tester) async {
      final answer = Completer<bool>();
      await _pumpEditing(tester, onSave: (_) => answer.future);

      await tester.tap(find.widgetWithText(ShadButton, 'Save'));
      await tester.pump();
      expect(find.text('FORM OFF'), findsOneWidget);

      answer.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('READ MODE'), findsOneWidget);
    });

    testWidgets('Issue 91: a save that throws leaves the form on, with '
        'Cancel and Save live', (tester) async {
      final answer = Completer<void>();
      await _pumpEditing(
        tester,
        onSave: (_) async {
          await answer.future;
          throw StateError('save failed');
        },
      );

      // Save is pressed in a zone of its own: what the save throws is not
      // caught by the card, and would otherwise fail the test as an
      // unhandled error.
      Object? thrown;
      runZonedGuarded(
        () => _save(tester).onPressed!(),
        (error, _) => thrown = error,
      );
      await tester.pump();
      expect(find.text('FORM OFF'), findsOneWidget);
      expect(_save(tester).enabled, isFalse);
      expect(_cancel(tester).enabled, isFalse);

      answer.complete();
      await tester.pumpAndSettle();
      expect(thrown, isStateError);

      expect(find.text('FORM ON'), findsOneWidget);
      expect(_save(tester).enabled, isTrue);
      expect(_cancel(tester).enabled, isTrue);

      // Cancel is live: it closes the editor.
      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('READ MODE'), findsOneWidget);
    });
  });
}
