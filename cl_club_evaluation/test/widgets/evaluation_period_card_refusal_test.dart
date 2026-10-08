// Issue 97: the Review Period editor shows a refusal by the server inline
// in its form, and a failure that is not about the event or the period in
// a toast.
import 'dart:async';

import 'package:cl_club_evaluation/src/constants/evaluation_view_strings.dart';
import 'package:cl_club_evaluation/src/widgets/evaluation_period_card.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        EvaluationPeriodForm,
        EvaluationPeriodFormState,
        EvaluationStartFormFields;

import '../support/evaluation_scope.dart';

/// Fails the period update with [failure].
class _FailingEvaluations extends StubEvaluations {
  _FailingEvaluations(super.evaluations, this.failure);

  final Exception failure;

  @override
  Future<sdk.EvaluationStaffView> updateEvaluation(
    int id, {
    int? Function()? eventId,
    DateTime? Function()? periodStartUtc,
    DateTime? Function()? periodEndUtc,
  }) async => throw failure;
}

/// Opens the editor, moves the last day and saves, the save failing with
/// [failure].
Future<void> _saveFailing(WidgetTester tester, Exception failure) async {
  final evaluation = staffView(
    5,
    periodStartUtc: DateTime.utc(2026, 5),
    periodEndUtc: DateTime.utc(2026, 5, 31),
  );
  await tallSurface(tester);
  await tester.pumpWidget(
    evaluationScope(
      evaluations: _FailingEvaluations({5: evaluation}, failure),
      users: {'ana': userInfo('ana', 'Cara Mendes')},
      child: EvaluationPeriodCard(evaluation: evaluation),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(LucideIcons.pencil));
  await tester.pumpAndSettle();
  tester
      .state<EvaluationPeriodFormState>(find.byType(EvaluationPeriodForm))
      .formKey
      .currentState!
      .fields[EvaluationStartFormFields.periodEndId]!
      .didChange(DateTime(2026, 5, 30));
  await tester.pump();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

Finder _inForm(String text) => find.descendant(
  of: find.byType(EvaluationPeriodForm),
  matching: find.text(text),
);

bool _formOn(WidgetTester tester) => tester
    .widget<EvaluationPeriodForm>(find.byType(EvaluationPeriodForm))
    .enabled;

void main() {
  group('Issue 97: the Review Period editor shows a failed save where it '
      'belongs', () {
    testWidgets('Issue 97: a review the member already has for the period '
        'shows inline in the form, with no toast', (tester) async {
      await _saveFailing(
        tester,
        const sdk.ServerException(
          statusCode: 422,
          code: sdk.SdkErrorCode.duplicateEvaluation,
          message: 'raw duplicate',
        ),
      );

      expect(_inForm(EvaluationViewStrings.duplicateEvaluation), findsOne);
      expect(find.byType(ShadToast), findsNothing);
      expect(find.textContaining('raw duplicate'), findsNothing);
      expect(_formOn(tester), isTrue);
    });

    testWidgets('Issue 97: a server that cannot be reached is a toast, not '
        'a message in the form, and the editor is on again', (tester) async {
      await _saveFailing(tester, TimeoutException('connection closed'));

      expect(find.byType(ShadToast), findsOneWidget);
      expect(find.text(EvaluationViewStrings.saveFailed), findsOneWidget);
      expect(_inForm(EvaluationViewStrings.saveFailed), findsNothing);
      expect(find.textContaining('connection closed'), findsNothing);
      expect(_formOn(tester), isTrue);
    });

    testWidgets('Issue 97: a server that fails is a toast as well', (
      tester,
    ) async {
      await _saveFailing(
        tester,
        const sdk.ServerException(
          statusCode: 500,
          code: 'INTERNAL_ERROR',
          message: 'raw failure',
        ),
      );

      expect(find.byType(ShadToast), findsOneWidget);
      expect(_inForm(EvaluationViewStrings.saveFailed), findsNothing);
      expect(find.textContaining('raw failure'), findsNothing);
    });
  });
}
