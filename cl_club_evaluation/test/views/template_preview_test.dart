import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EvaluationTemplatePreview;

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

Finder _inPreview(Finder finder) => find.descendant(
  of: find.byType(EvaluationTemplatePreview),
  matching: finder,
);

Widget _detail(StubTemplates stub) => evaluationScope(
  templates: stub,
  child: TemplateDetailView(
    currentUser: viewer('root', admin: true),
    templateId: 1,
    onBack: () {},
    onDuplicate: (_) {},
    onSaveTemplateFile: (_, _) async => true,
  ),
);

Widget _designer(StubTemplates stub, {int? copyOf}) => evaluationScope(
  templates: stub,
  child: TemplateCreateView(
    currentUser: viewer('root', admin: true),
    copyOfTemplateId: copyOf,
    onCreated: (_) {},
    onCancel: () {},
  ),
);

void main() {
  group('Issue 28: the template live preview', () {
    testWidgets('Issue 28: the detail shows the template as the review form '
        'beside its editor', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_detail(StubTemplates({1: _skating})));
      await tester.pumpAndSettle();
      expect(inTemplateEditor(find.text('Stride')), findsOneWidget);
      expect(_inPreview(find.text('Stride')), findsOneWidget);
      expect(_inPreview(find.text('Edges')), findsOneWidget);
      expect(_inPreview(find.text('Yes')), findsOneWidget);
      final editor = tester.getRect(inTemplateEditor(find.text('Stride')));
      final preview = tester.getRect(_inPreview(find.text('Stride')));
      expect(preview.left, greaterThan(editor.right));
    });

    testWidgets('Issue 28: a template in use is previewed too', (
      tester,
    ) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        _detail(StubTemplates({1: _skating.copyWith(inUse: true)})),
      );
      await tester.pumpAndSettle();
      expect(_inPreview(find.text('Stops')), findsOneWidget);
    });

    testWidgets('Issue 28: the detail preview follows each saved change', (
      tester,
    ) async {
      final stub = StubTemplates({1: _skating});
      await tallSurface(tester);
      await tester.pumpWidget(_detail(stub));
      await tester.pumpAndSettle();
      expect(_inPreview(find.text('Stride')), findsOneWidget);
      // A saved change reaches the library as the template the server
      // returns; here, Stride removed.
      stub.state = AsyncData({
        1: _skating.copyWith(
          layout: const [
            sdk.EvaluationLayoutSection('Edges', [12]),
          ],
          items: const [sdk.EvaluationYesNoItem(id: 12, question: 'Stops')],
        ),
      });
      await tester.pumpAndSettle();
      expect(_inPreview(find.text('Stride')), findsNothing);
      expect(_inPreview(find.text('Stops')), findsOneWidget);
    });

    testWidgets('Issue 28: the designer previews an item before the '
        'template is created', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(_designer(StubTemplates({})));
      await tester.pumpAndSettle();
      expect(
        _inPreview(find.text('Add a question to see it here.')),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(LucideIcons.plus).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes / No'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(ShadDialog),
              matching: find.byType(EditableText),
            )
            .first,
        'Stops on both sides',
      );
      await tester.pump();
      expect(_inPreview(find.text('Stops on both sides')), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(ShadDialog),
          matching: find.text('Add'),
        ),
      );
      await tester.pumpAndSettle();
      expect(_inPreview(find.text('Stops on both sides')), findsOneWidget);
      expect(_inPreview(find.text('Yes')), findsOneWidget);
    });

    testWidgets('Issue 28: a duplicate is previewed as soon as it opens', (
      tester,
    ) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        _designer(StubTemplates({1: _skating}), copyOf: 1),
      );
      await tester.pumpAndSettle();
      expect(_inPreview(find.text('Stride')), findsOneWidget);
      expect(_inPreview(find.text('Stops')), findsOneWidget);
    });

    testWidgets('Issue 28: a narrow screen switches between Edit and '
        'Preview', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_detail(StubTemplates({1: _skating})));
      await tester.pumpAndSettle();
      expect(inTemplateEditor(find.text('Stride')), findsOneWidget);
      expect(_inPreview(find.text('Stride')), findsNothing);
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(_inPreview(find.text('Stride')), findsOneWidget);
      expect(inTemplateEditor(find.text('Stride')), findsNothing);
      expect(find.text('Rename'), findsOneWidget, reason: 'the header stays');
    });
  });
}
