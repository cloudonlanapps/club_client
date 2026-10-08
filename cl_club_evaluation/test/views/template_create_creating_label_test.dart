// Issue 108: while the template is created, Create is off and reads
// "Creating…".
import 'dart:async';

import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/evaluation_scope.dart';

final sdk.EvaluationTemplate _skating = template(
  1,
  layout: const [sdk.EvaluationLayoutItem(12)],
  items: const [sdk.EvaluationQaItem(id: 12, question: 'Summary')],
);

/// A template library whose create waits on [held].
class _HeldTemplates extends StubTemplates {
  _HeldTemplates(super.templates, this.held);

  final Completer<void> held;

  @override
  Future<sdk.EvaluationTemplate> createTemplate({
    required String name,
    required List<sdk.EvaluationLayoutEntry<sdk.EvaluationTemplateItem>> layout,
  }) async {
    await held.future;
    return template(99, name: name);
  }
}

ShadButton _button(WidgetTester tester, String label) =>
    tester.widget<ShadButton>(find.widgetWithText(ShadButton, label));

void main() {
  testWidgets('Issue 108: Create template reads "Creating…" on a Create '
      'that is off while the template is created', (tester) async {
    final held = Completer<void>();
    final created = <int>[];
    await tallSurface(tester);
    await tester.pumpWidget(
      evaluationScope(
        templates: _HeldTemplates({1: _skating}, held),
        child: TemplateCreateView(
          currentUser: viewer('kim', coach: true),
          copyOfTemplateId: 1,
          onCreated: created.add,
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_button(tester, 'Create').onPressed, isNotNull);
    expect(find.text('Creating…'), findsNothing);

    await tester.tap(find.widgetWithText(ShadButton, 'Create'));
    await tester.pump();

    expect(find.widgetWithText(ShadButton, 'Create'), findsNothing);
    expect(_button(tester, 'Creating…').onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    held.complete();
    await tester.pumpAndSettle();
    expect(created, [99]);
  });
}
