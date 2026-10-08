import 'dart:async';

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

/// Holds the period update until [answer] completes, then refuses it.
class _HeldEvaluations extends StubEvaluations {
  _HeldEvaluations(super.evaluations);

  final Completer<void> answer = Completer<void>();

  @override
  Future<sdk.EvaluationStaffView> updateEvaluation(
    int id, {
    int? Function()? eventId,
    DateTime? Function()? periodStartUtc,
    DateTime? Function()? periodEndUtc,
  }) async {
    await answer.future;
    throw const sdk.ServerException(
      statusCode: 409,
      code: 'DUPLICATE_EVALUATION',
      message: 'raw duplicate',
    );
  }
}

bool _formOn(WidgetTester tester) => tester
    .widget<EvaluationPeriodForm>(find.byType(EvaluationPeriodForm))
    .enabled;

void main() {
  testWidgets('Issue 91: the Review Period form is off while its save is in '
      'flight, and on again once it is refused', (tester) async {
    final evaluation = staffView(
      5,
      periodStartUtc: DateTime.utc(2026, 5),
      periodEndUtc: DateTime.utc(2026, 5, 31),
    );
    final stub = _HeldEvaluations({5: evaluation});
    await tallSurface(tester);
    await tester.pumpWidget(
      evaluationScope(
        evaluations: stub,
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
    expect(_formOn(tester), isTrue);

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(_formOn(tester), isFalse);

    stub.answer.complete();
    await tester.pumpAndSettle();
    expect(_formOn(tester), isTrue);
  });
}
