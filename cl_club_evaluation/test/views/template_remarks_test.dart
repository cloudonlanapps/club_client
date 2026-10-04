import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/evaluation_scope.dart';

/// A section holding a copied question (with an origin), then a Q & A.
final sdk.EvaluationTemplate _skating = template(
  1,
  layout: const [
    sdk.EvaluationLayoutSection('Edges', [11]),
    sdk.EvaluationLayoutItem(12),
  ],
  items: const [
    sdk.EvaluationYesNoItem(id: 11, question: 'Stops', originItemId: 70),
    sdk.EvaluationQaItem(id: 12, question: 'Summary'),
  ],
);

const sdk.ServerException _nameTaken = sdk.ServerException(
  statusCode: 422,
  code: 'TEMPLATE_NAME_TAKEN',
  message: 'raw name taken',
);

const String _nameTakenText = 'A template with this name already exists.';

ShadButton _button(WidgetTester tester, String label) => tester.widget(
  find.ancestor(of: find.text(label), matching: find.byType(ShadButton)).first,
);

void main() {
  final kim = viewer('kim', coach: true);

  group('Issue 173: Manage Templates on the coach view', () {
    testWidgets('Issue 173: every coach gets it, at the bottom right', (
      tester,
    ) async {
      var opened = 0;
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({1: _skating}),
          child: CoachReviewsView(
            currentUser: kim,
            onOpenEvaluation: (_) {},
            onOpenTemplates: () => opened++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.text('Manage Templates');
      expect(button, findsOneWidget);
      final start = tester.getBottomLeft(find.text('Start'));
      expect(tester.getTopLeft(button).dy, greaterThan(start.dy));
      expect(
        tester.getTopRight(button).dx,
        greaterThan(tester.getTopRight(find.text('Skating')).dx),
      );
      await tester.tap(button);
      expect(opened, 1);
    });
  });

  group('Issue 173: the template library for coaches and admins', () {
    Future<StubTemplates> pump(
      WidgetTester tester, {
      required Map<int, sdk.EvaluationTemplate> templates,
      ValueChanged<int>? onDuplicate,
    }) async {
      final stub = StubTemplates(templates);
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: stub,
          child: TemplateLibraryView(
            currentUser: kim,
            onOpenTemplate: (_) {},
            onCreateTemplate: () {},
            onDuplicateTemplate: onDuplicate ?? (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      return stub;
    }

    testWidgets('Issue 173: a coach duplicates a template from its row', (
      tester,
    ) async {
      final duplicated = <int>[];
      await pump(tester, templates: {1: _skating}, onDuplicate: duplicated.add);
      await tester.tap(find.text('Duplicate'));
      expect(duplicated, [1]);
    });

    testWidgets('Issue 173: Delete asks, then deletes; in use it is '
        'disabled', (tester) async {
      final stub = await pump(
        tester,
        templates: {
          1: _skating,
          2: template(2, name: 'Used', inUse: true),
        },
      );
      final deletes = find.text('Delete');
      expect(deletes, findsNWidgets(2));
      final used = find.descendant(
        of: find
            .ancestor(of: find.text('Used'), matching: find.byType(ShadCard))
            .first,
        matching: find.byType(ShadButton),
      );
      expect(
        tester
            .widgetList<ShadButton>(used)
            .where((b) => b.onPressed == null)
            .length,
        1,
      );
      final skating = find.descendant(
        of: find
            .ancestor(of: find.text('Skating'), matching: find.byType(ShadCard))
            .first,
        matching: find.text('Delete'),
      );
      await tester.tap(skating);
      await tester.pumpAndSettle();
      expect(find.text('Delete this template?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(stub.calls, ['delete 1']);
    });

    testWidgets('Issue 173: a deleted template is not listed, and nothing '
        'offers Restore', (tester) async {
      await pump(
        tester,
        templates: {
          1: template(1, name: 'Gone').copyWith(deletedAtUtc: () => t0),
          2: template(2, name: 'Kept'),
        },
      );
      expect(find.text('Gone'), findsNothing);
      expect(find.text('Kept'), findsOneWidget);
      expect(find.textContaining('Deleted'), findsNothing);
      expect(find.text('Restore'), findsNothing);
    });

    testWidgets('Issue 173: the delete prompt does not promise restore', (
      tester,
    ) async {
      await pump(tester, templates: {1: template(1, name: 'Kept')});
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('It leaves the library.'), findsOneWidget);
      expect(find.textContaining('restored'), findsNothing);
    });
  });

  group('Issue 173: the template detail', () {
    Future<StubTemplates> pump(
      WidgetTester tester,
      sdk.EvaluationTemplate t, {
      VoidCallback? onBack,
      ValueChanged<int>? onDuplicate,
      Exception? failWith,
    }) async {
      final stub = StubTemplates({t.id: t}, failWith: failWith);
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: stub,
          child: TemplateDetailView(
            currentUser: kim,
            templateId: t.id,
            onBack: onBack ?? () {},
            onDuplicate: onDuplicate ?? (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      return stub;
    }

    testWidgets('Issue 173: Delete always shows; disabled while in use', (
      tester,
    ) async {
      await pump(tester, _skating.copyWith(inUse: true));
      expect(_button(tester, 'Delete').onPressed, isNull);
    });

    testWidgets('Issue 173: Delete asks, deletes and leaves', (tester) async {
      var back = 0;
      final stub = await pump(tester, _skating, onBack: () => back++);
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(stub.calls, ['delete 1']);
      expect(back, 1);
    });

    testWidgets('Issue 173: Duplicate hands over the template', (
      tester,
    ) async {
      final duplicated = <int>[];
      await pump(tester, _skating, onDuplicate: duplicated.add);
      await tester.tap(find.text('Duplicate'));
      expect(duplicated, [1]);
    });

    testWidgets('Issue 173: TEMPLATE_NAME_TAKEN shows inline in the rename '
        'dialog, which stays open', (tester) async {
      await pump(tester, _skating, failWith: _nameTaken);
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(ShadDialog),
          matching: find.byType(EditableText),
        ),
        'Edges',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.text(_nameTakenText), findsOneWidget);
      expect(find.text('raw name taken'), findsNothing);
    });
  });

  group('Issue 173: the template designer', () {
    testWidgets('Issue 173: a duplicate opens pre-filled and is created '
        'with brand-new, unlinked questions', (tester) async {
      final stub = StubTemplates({1: _skating});
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: stub,
          child: TemplateCreateView(
            currentUser: kim,
            copyOfTemplateId: 1,
            onCreated: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Skating (copy)'), findsOneWidget);
      expect(find.text('Stops'), findsOneWidget);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['create Skating (copy) 2']);
      final items = [
        for (final entry in stub.createdLayout!) ...entry.items,
      ];
      expect(items, hasLength(2));
      for (final item in items) {
        expect(item.id, isNull);
        if (item is sdk.EvaluationQuestionItem) {
          expect(item.originItemId, isNull);
        }
      }
    });

    testWidgets('Issue 173: TEMPLATE_NAME_TAKEN shows under the name', (
      tester,
    ) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({1: _skating}, failWith: _nameTaken),
          child: TemplateCreateView(
            currentUser: kim,
            copyOfTemplateId: 1,
            onCreated: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(find.text(_nameTakenText), findsOneWidget);
      expect(find.text('raw name taken'), findsNothing);
    });
  });
}
