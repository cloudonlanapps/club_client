import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/evaluation_scope.dart';

/// A Q & A, then a section of one yes / no.
final sdk.EvaluationTemplate _skating = template(
  1,
  layout: const [
    sdk.EvaluationLayoutItem(11),
    sdk.EvaluationLayoutSection('Edges', [12]),
  ],
  items: const [
    sdk.EvaluationQaItem(id: 11, question: 'Stride'),
    sdk.EvaluationYesNoItem(id: 12, question: 'Stops'),
  ],
);

Future<StubTemplates> _pump(WidgetTester tester, {bool inUse = false}) async {
  final stub = StubTemplates({1: _skating.copyWith(inUse: inUse)});
  await tallSurface(tester);
  await tester.pumpWidget(
    evaluationScope(
      templates: stub,
      child: TemplateDetailView(
        currentUser: viewer('root', admin: true),
        templateId: 1,
        onBack: () {},
        onDuplicate: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return stub;
}

Finder _inDialog(Finder finder) =>
    find.descendant(of: find.byType(ShadDialog), matching: finder);

Future<void> _open(WidgetTester tester, String row) async {
  await tester.tap(find.text(row));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 173: the item dialog', () {
    testWidgets('Issue 173: the outline rows carry no delete icon', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.byIcon(LucideIcons.trash2), findsNothing);
    });

    testWidgets('Issue 173: tapping outside does not close it', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester, 'Stride');
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byType(ShadDialog), findsOneWidget);
    });

    testWidgets('Issue 173: Escape on an untouched item cancels', (
      tester,
    ) async {
      final stub = await _pump(tester);
      await _open(tester, 'Stride');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ShadDialog), findsNothing);
      expect(stub.calls, isEmpty);
    });

    testWidgets('Issue 173: leaving a changed item asks first', (
      tester,
    ) async {
      final stub = await _pump(tester);
      await _open(tester, 'Stride');
      await tester.enterText(
        _inDialog(find.byType(EditableText)).first,
        'Stride length',
      );
      await tester.pump();
      await tester.tap(_inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Stride length'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byType(ShadDialog), findsNothing);
      expect(stub.calls, isEmpty);
    });

    testWidgets('Issue 173: Delete in the dialog asks, then removes the '
        'item', (tester) async {
      final stub = await _pump(tester);
      await _open(tester, 'Stride');
      await tester.tap(_inDialog(find.text('Delete')));
      await tester.pumpAndSettle();
      expect(find.text('Delete this item?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(stub.calls, ['remove 1 11']);
    });

    testWidgets('Issue 173: cancelling the delete prompt keeps the item', (
      tester,
    ) async {
      final stub = await _pump(tester);
      await _open(tester, 'Stride');
      await tester.tap(_inDialog(find.text('Delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      expect(find.text('Delete this item?'), findsNothing);
      expect(find.byType(ShadDialog), findsOneWidget);
      expect(stub.calls, isEmpty);
    });

    testWidgets('Issue 173: a section deletes from its dialog and keeps its '
        'items', (tester) async {
      final stub = await _pump(tester);
      await _open(tester, 'Edges');
      await tester.tap(_inDialog(find.text('Delete')));
      await tester.pumpAndSettle();
      expect(find.text('Delete this section?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(stub.calls, ['layout 1']);
    });
  });

  group('Issue 173: a frozen template', () {
    testWidgets('Issue 173: an item opens read-only, with Close and nothing '
        'to save or delete', (tester) async {
      final stub = await _pump(tester, inUse: true);
      await _open(tester, 'Stride');
      expect(find.byType(ShadDialog), findsOneWidget);
      expect(_inDialog(find.text('Close')), findsOneWidget);
      expect(_inDialog(find.text('Save')), findsNothing);
      expect(_inDialog(find.text('Delete')), findsNothing);
      final form = tester.widget<ShadForm>(_inDialog(find.byType(ShadForm)));
      expect(form.enabled, isFalse);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(ShadDialog), findsNothing);
      expect(stub.calls, isEmpty);
    });

    testWidgets('Issue 173: a section row does not open', (tester) async {
      await _pump(tester, inUse: true);
      await _open(tester, 'Edges');
      expect(find.byType(ShadDialog), findsNothing);
    });
  });
}
