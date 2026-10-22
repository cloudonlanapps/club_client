import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationTemplatesMasterProvider, clEvaluationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/evaluation_scope.dart';

/// One Q & A, so the test has a text answer to type into.
final sdk.EvaluationTemplate _template = template(
  1,
  layout: const [sdk.EvaluationLayoutItem(13)],
  items: const [sdk.EvaluationQaItem(id: 13, question: 'What next')],
);

void main() {
  final reloads = <String, ProviderOrFamily>{
    'the evaluations': clEvaluationsMasterProvider,
    'the templates': clEvaluationTemplatesMasterProvider,
  };
  for (final MapEntry(key: name, value: provider) in reloads.entries) {
    testWidgets('Issue 162: a reload of $name keeps the evaluation page and '
        'the answer being typed', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({1: _template}),
          evaluations: StubEvaluations({5: staffView(5)}),
          users: {'ana': userInfo('ana', 'Ana Rao')},
          child: EvaluationEditView(
            currentUser: viewer('coach', coach: true),
            evaluationId: 5,
            onBack: () {},
            onDeleted: () {},
            onTransferred: () {},
            onOpenPdfBytes: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byType(EditableText).first;
      await tester.enterText(field, 'Work on edges');
      await tester.pump();

      ProviderScope.containerOf(
        tester.element(find.byType(EvaluationEditView)),
      ).invalidate(provider);
      await tester.pump();
      expect(find.byType(ShadProgress), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('Work on edges'), findsOneWidget);
    });
  }
}
