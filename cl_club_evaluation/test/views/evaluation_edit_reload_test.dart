import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:cl_club_evaluation/src/constants/evaluation_view_strings.dart';
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

/// The evaluations, whose every load after the first fails.
class _FailingEvaluations extends StubEvaluations {
  _FailingEvaluations(super.evaluations);

  int loads = 0;

  @override
  Future<Map<int, sdk.EvaluationStaffView>> build() async {
    if (++loads > 1) throw Exception('offline');
    return super.build();
  }
}

/// The evaluations, whose every load fails.
class _UnreachableEvaluations extends StubEvaluations {
  _UnreachableEvaluations() : super(const {});

  @override
  Future<Map<int, sdk.EvaluationStaffView>> build() async =>
      throw Exception('offline');
}

/// The templates, whose every load after the first fails.
class _FailingTemplates extends StubTemplates {
  _FailingTemplates(super.templates);

  int loads = 0;

  @override
  Future<Map<int, sdk.EvaluationTemplate>> build() async {
    if (++loads > 1) throw Exception('offline');
    return super.build();
  }
}

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

  for (final name in ['the evaluations', 'the templates']) {
    testWidgets('Issue 268: a failed reload of $name keeps the evaluation '
        'page and the answer being typed', (tester) async {
      await tallSurface(tester);
      final failEvaluations = name == 'the evaluations';
      await tester.pumpWidget(
        evaluationScope(
          templates: failEvaluations
              ? StubTemplates({1: _template})
              : _FailingTemplates({1: _template}),
          evaluations: failEvaluations
              ? _FailingEvaluations({5: staffView(5)})
              : StubEvaluations({5: staffView(5)}),
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
      ).invalidate(reloads[name]!);
      await tester.pumpAndSettle();

      expect(find.text(EvaluationViewStrings.loadFailed), findsNothing);
      expect(find.text('Work on edges'), findsOneWidget);
    });
  }

  testWidgets('Issue 268: a first load that fails still shows that the '
      'evaluation could not be loaded', (tester) async {
    await tallSurface(tester);
    await tester.pumpWidget(
      evaluationScope(
        templates: StubTemplates({1: _template}),
        evaluations: _UnreachableEvaluations(),
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

    expect(find.text(EvaluationViewStrings.loadFailed), findsOneWidget);
  });
}
