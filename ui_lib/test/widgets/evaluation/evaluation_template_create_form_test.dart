import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

Future<GlobalKey<EvaluationTemplateCreateFormState>> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
}) async {
  await tallSurface(tester);
  final key = GlobalKey<EvaluationTemplateCreateFormState>();
  await tester.pumpWidget(
    wrapEvaluation(
      EvaluationTemplateCreateForm(
        key: key,
        initialValues: initialValues,
        onEditItem: (item) async =>
            EvaluationOutlineEdit.update(item.copyWith(text: 'Edges')),
        onEditSectionTitle: (_) async =>
            const EvaluationOutlineEdit.update('Skating'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  group('Issue 173: EvaluationTemplateCreateForm', () {
    testWidgets('Issue 173: no question shows the form-level message', (
      tester,
    ) async {
      final key = await _pump(tester);
      await tester.enterText(find.byType(EditableText).first, 'Skating');
      await tester.pump();
      expect(key.currentState!.handleSubmit(), isNull);
      await tester.pump();
      expect(find.text('Add at least one question.'), findsOneWidget);
    });

    testWidgets('Issue 173: an info text alone is not a question', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        initialValues: {
          EvaluationTemplateCreateFormFields.nameId: 'Skating',
          EvaluationTemplateCreateFormFields.layoutId: const [
            EvaluationLayoutEntry.item(infoItem),
          ],
        },
      );
      expect(key.currentState!.handleSubmit(), isNull);
    });

    testWidgets('Issue 173: the name is required', (tester) async {
      final key = await _pump(
        tester,
        initialValues: {
          EvaluationTemplateCreateFormFields.nameId: '',
          EvaluationTemplateCreateFormFields.layoutId: sampleLayout,
        },
      );
      expect(key.currentState!.handleSubmit(), isNull);
      await tester.pump();
      expect(find.text('Template name is required'), findsOneWidget);
    });

    testWidgets('Issue 173: a valid template submits name and layout', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        initialValues: {
          EvaluationTemplateCreateFormFields.nameId: ' Skating term 1 ',
          EvaluationTemplateCreateFormFields.layoutId: sampleLayout,
        },
      );
      final value = key.currentState!.handleSubmit();
      expect(
        value,
        const EvaluationTemplateCreateValue(
          name: 'Skating term 1',
          layout: sampleLayout,
        ),
      );
    });

    testWidgets('Issue 173: items added in the editor reach the submit', (
      tester,
    ) async {
      final key = await _pump(tester);
      await tester.enterText(find.byType(EditableText).first, 'Skating');
      await tester.tap(find.byIcon(LucideIcons.plus).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Number'));
      await tester.pumpAndSettle();
      final value = key.currentState!.handleSubmit();
      expect(value?.layout.single.item?.kind, EvaluationItemKind.number);
      expect(value?.layout.single.item?.text, 'Edges');
    });

    testWidgets('Issue 173: isDirty follows the name and the layout', (
      tester,
    ) async {
      final key = await _pump(tester);
      expect(key.currentState!.isDirty, isFalse);
      await tester.enterText(find.byType(EditableText).first, 'Skating');
      await tester.pump();
      expect(key.currentState!.isDirty, isTrue);
    });
  });
}
