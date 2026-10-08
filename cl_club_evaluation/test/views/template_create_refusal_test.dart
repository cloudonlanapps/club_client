// Issue 92: Create template goes on working after a refused name, and
// neither greys out as "may not edit" nor leaves while it creates.
import 'dart:async';

import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/evaluation_scope.dart';

final sdk.EvaluationTemplate _skating = template(
  1,
  layout: const [sdk.EvaluationLayoutItem(12)],
  items: const [sdk.EvaluationQaItem(id: 12, question: 'Summary')],
);

const sdk.ServerException _nameTaken = sdk.ServerException(
  statusCode: 422,
  code: 'TEMPLATE_NAME_TAKEN',
  message: 'raw name taken',
);

const String _nameTakenText = 'A template with this name already exists.';

/// A template library whose creates answer in turn from [answers]: an
/// exception to throw, or a completer to wait on.
class _ScriptedTemplates extends StubTemplates {
  _ScriptedTemplates(super.templates, this.answers);

  final List<Object?> answers;

  @override
  Future<sdk.EvaluationTemplate> createTemplate({
    required String name,
    required List<sdk.EvaluationLayoutEntry<sdk.EvaluationTemplateItem>> layout,
  }) async {
    calls.add('create $name');
    final answer = answers.isEmpty ? null : answers.removeAt(0);
    if (answer is Completer<void>) await answer.future;
    if (answer is Exception) throw answer;
    return template(99, name: name);
  }
}

Future<void> _pump(
  WidgetTester tester,
  StubTemplates stub, {
  required List<int> created,
  required List<int> cancelled,
}) async {
  await tallSurface(tester);
  await tester.pumpWidget(
    evaluationScope(
      templates: stub,
      child: TemplateCreateView(
        currentUser: viewer('kim', coach: true),
        copyOfTemplateId: 1,
        onCreated: created.add,
        onCancel: () => cancelled.add(1),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 92: Create template', () {
    testWidgets('Issue 92: after a "name taken" refusal, a new name and '
        'Create make the template', (tester) async {
      final stub = _ScriptedTemplates({1: _skating}, [_nameTaken]);
      final created = <int>[];
      await _pump(tester, stub, created: created, cancelled: []);

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(find.text(_nameTakenText), findsOneWidget);
      expect(created, isEmpty);

      await tester.enterText(find.byType(EditableText).first, 'Edges');
      await tester.pump();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['create Skating (copy)', 'create Edges']);
      expect(created, [99]);
      expect(find.text(_nameTakenText), findsNothing);
    });

    testWidgets('Issue 92: while the template is created, the Sort tick '
        'and the add bar stay on screen, greyed', (tester) async {
      final wait = Completer<void>();
      final stub = _ScriptedTemplates({1: _skating}, [wait]);
      await _pump(tester, stub, created: [], cancelled: []);

      await tester.tap(find.text('Create'));
      await tester.pump();
      final sort = tester.widget<ShadCheckbox>(
        find.ancestor(
          of: find.text('Sort'),
          matching: find.byType(ShadCheckbox),
        ),
      );
      expect(sort.enabled, isFalse);
      final add = find.ancestor(
        of: find.byIcon(LucideIcons.plus),
        matching: find.byType(ShadButton),
      );
      expect(add, findsOneWidget);
      expect(tester.widget<ShadButton>(add).onPressed, isNull);

      wait.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('Issue 92: system back does nothing while the template is '
        'created', (tester) async {
      final wait = Completer<void>();
      final stub = _ScriptedTemplates({1: _skating}, [wait, _nameTaken]);
      final cancelled = <int>[];
      await _pump(tester, stub, created: [], cancelled: cancelled);

      await tester.tap(find.text('Create'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(cancelled, isEmpty);
      expect(find.text('Discard'), findsNothing);
      expect(find.text('New template'), findsOneWidget);

      // Once the create is over, back leaves as before.
      wait.complete();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(cancelled, [1]);
    });
  });
}
