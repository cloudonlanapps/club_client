import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_scope.dart';

void main() {
  group('Issue 173: the template designer title bar', () {
    testWidgets('Issue 173: Cancel and Create sit in the title bar, above '
        'the form', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          child: TemplateCreateView(
            currentUser: viewer('root', admin: true),
            onCreated: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final title = tester.getRect(find.text('New template'));
      final name = tester.getTopLeft(find.text('Template name')).dy;
      for (final action in ['Cancel', 'Create']) {
        final rect = tester.getRect(find.text(action));
        expect(rect.top, lessThan(name), reason: action);
        expect(rect.left, greaterThan(title.right), reason: action);
      }
    });

    testWidgets('Issue 173: on a narrow page the actions wrap under the '
        'title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        evaluationScope(
          child: TemplateCreateView(
            currentUser: viewer('root', admin: true),
            onCreated: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final title = tester.getRect(find.text('New template'));
      final create = tester.getRect(find.text('Create'));
      expect(create.top, greaterThanOrEqualTo(title.bottom));
    });
  });
}
