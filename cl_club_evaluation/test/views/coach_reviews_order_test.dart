import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_scope.dart';

final sdk.EvaluationTemplate _skating = template(
  1,
  layout: const [sdk.EvaluationLayoutItem(11)],
  items: const [sdk.EvaluationQaItem(id: 11, question: 'Stride')],
);

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  group('Issue 173: the order of the coach view', () {
    testWidgets('Issue 173: Drafts come first, then Finalized, Published, '
        'and New to start from a template; no Open', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({1: _skating}),
          evaluations: StubEvaluations({
            1: staffView(1),
            2: staffView(2, status: sdk.EvaluationStatus.published),
            3: staffView(3, status: sdk.EvaluationStatus.saved),
          }),
          child: CoachReviewsView(
            currentUser: viewer('kim', coach: true),
            onOpenEvaluation: (_) {},
            onOpenTemplates: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final order = ['Drafts', 'Finalized', 'Published', 'New'];
      for (final heading in order) {
        expect(find.text(heading), findsOneWidget, reason: heading);
      }
      final tops = [for (final h in order) _top(tester, h)];
      expect(tops, [...tops]..sort());
      expect(find.text('Open'), findsNothing);
      expect(find.text('Saved'), findsNothing);
    });
  });
}
