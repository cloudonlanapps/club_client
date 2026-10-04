import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/evaluation_scope.dart';

final sdk.EvaluationTemplate _skating = template(
  1,
  layout: const [sdk.EvaluationLayoutItem(11)],
  items: const [sdk.EvaluationQaItem(id: 11, question: 'Stride')],
);

void main() {
  final kim = viewer('kim', coach: true);
  final admin = viewer('root', admin: true);

  group('Issue 173: CoachReviewsView', () {
    testWidgets('Issue 173: groups the evaluations by status, skips deleted '
        'ones, and lists the templates with Start', (tester) async {
      final opened = <int>[];
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({1: _skating}),
          evaluations: StubEvaluations({
            1: staffView(1),
            2: staffView(2, status: sdk.EvaluationStatus.published),
            3: staffView(3).copyWith(deletedAtUtc: () => t0),
          }),
          users: {'ana': userInfo('ana', 'Ana Rao')},
          child: CoachReviewsView(
            currentUser: kim,
            onOpenEvaluation: opened.add,
            onOpenTemplates: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Drafts'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
      expect(find.text('Ana Rao'), findsNWidgets(2));
      expect(find.text('Start'), findsOneWidget);
      await tester.tap(find.text('Ana Rao').first);
      expect(opened, [1]);
    });

    testWidgets('Issue 173: Start opens the start dialog with the template '
        'fixed', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({1: _skating}),
          child: CoachReviewsView(
            currentUser: kim,
            onOpenEvaluation: (_) {},
            onOpenTemplates: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No evaluations yet.'), findsOneWidget);
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('Start a review'), findsOneWidget);
      expect(find.text('Skating'), findsNWidgets(2));
    });
  });

  group('Issue 173: TemplateLibraryView', () {
    testWidgets('Issue 173: lists the live templates, not a deleted one, '
        'and adds one', (tester) async {
      final opened = <int>[];
      var created = 0;
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({
            1: _skating,
            2: template(2, name: 'Gone').copyWith(deletedAtUtc: () => t0),
          }),
          child: TemplateLibraryView(
            currentUser: admin,
            onOpenTemplate: opened.add,
            onCreateTemplate: () => created++,
            onDuplicateTemplate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gone'), findsNothing);
      expect(find.textContaining('Deleted'), findsNothing);
      await tester.tap(find.text('Skating'));
      await tester.tap(find.text('Add template'));
      expect(opened, [1]);
      expect(created, 1);
    });

    testWidgets('Issue 173: a template in use says so as plain text', (
      tester,
    ) async {
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({
            1: _skating,
            2: template(2, name: 'Edges', inUse: true),
          }),
          child: TemplateLibraryView(
            currentUser: admin,
            onOpenTemplate: (_) {},
            onCreateTemplate: () {},
            onDuplicateTemplate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 question'), findsOneWidget);
      expect(find.text('0 questions · In use'), findsOneWidget);
    });

    testWidgets('Issue 173: with no templates shows the empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        evaluationScope(
          child: TemplateLibraryView(
            currentUser: admin,
            onOpenTemplate: (_) {},
            onCreateTemplate: () {},
            onDuplicateTemplate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No templates yet.'), findsOneWidget);
    });
  });

  group('Issue 173: TemplateCreateView', () {
    testWidgets('Issue 173: Create validates before any call; Cancel on a '
        'clean form leaves', (tester) async {
      final stub = StubTemplates({});
      var cancelled = 0;
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: stub,
          child: TemplateCreateView(
            currentUser: admin,
            onCreated: (_) {},
            onCancel: () => cancelled++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(stub.calls, isEmpty);
      expect(find.text('Add at least one question.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(cancelled, 1);
    });

    testWidgets('Issue 173: Cancel on a dirty form asks before leaving', (
      tester,
    ) async {
      var cancelled = 0;
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          child: TemplateCreateView(
            currentUser: admin,
            onCreated: (_) {},
            onCancel: () => cancelled++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'Skating');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard this template?'), findsOneWidget);
      expect(cancelled, 0);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(cancelled, 1);
    });
  });

  group('Issue 173: TemplateDetailView', () {
    testWidgets('Issue 173: renames through the dialog', (tester) async {
      final stub = StubTemplates({1: _skating});
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: stub,
          child: TemplateDetailView(
            currentUser: admin,
            templateId: 1,
            onBack: () {},
            onDuplicate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Stride'), findsOneWidget);
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(ShadDialog),
          matching: find.byType(EditableText),
        ),
        'Skating II',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['rename 1 Skating II']);
      expect(find.text('Template renamed.'), findsOneWidget);
    });

    testWidgets('Issue 173: a template in use opens read-only with the '
        'explanation, and Rename still works', (tester) async {
      final stub = StubTemplates({
        1: _skating.copyWith(inUse: true),
      });
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: stub,
          child: TemplateDetailView(
            currentUser: admin,
            templateId: 1,
            onBack: () {},
            onDuplicate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Stride'), findsOneWidget);
      expect(find.textContaining('in use by an evaluation'), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsNothing);
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(ShadDialog),
          matching: find.byType(EditableText),
        ),
        'Skating II',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['rename 1 Skating II']);
    });

    testWidgets('Issue 173: a template not in use opens editable with no '
        'explanation', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({1: _skating}),
          child: TemplateDetailView(
            currentUser: admin,
            templateId: 1,
            onBack: () {},
            onDuplicate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('in use by an evaluation'), findsNothing);
      expect(find.text('Sort'), findsOneWidget);
    });

    testWidgets('Issue 173: TEMPLATE_IN_USE turns the layout read-only with '
        'an explanation', (tester) async {
      final stub = StubTemplates(
        {1: _skating},
        failWith: const sdk.ServerException(
          statusCode: 422,
          code: sdk.SdkErrorCode.templateInUse,
          message: 'in use',
        ),
      );
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: stub,
          child: TemplateDetailView(
            currentUser: admin,
            templateId: 1,
            onBack: () {},
            onDuplicate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stride'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ShadDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(stub.calls, ['remove 1 11']);
      expect(find.textContaining('in use by an evaluation'), findsWidgets);
      expect(find.text('Sort'), findsNothing);
      expect(find.text('Stride'), findsOneWidget);
    });
  });
}
