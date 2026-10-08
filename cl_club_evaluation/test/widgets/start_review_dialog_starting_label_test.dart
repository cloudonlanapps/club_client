// Issue 108: while the draft is created, Start is off and reads
// "Starting…".
import 'dart:async';

import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/evaluation_scope.dart';

/// Evaluations whose create waits on [held].
class _HeldEvaluations extends StubEvaluations {
  _HeldEvaluations(this.held) : super({});

  final Completer<void> held;

  @override
  Future<sdk.EvaluationStaffView> createEvaluation({
    required int templateId,
    required String createdFor,
    int? eventId,
    DateTime? periodStartUtc,
    DateTime? periodEndUtc,
  }) async {
    await held.future;
    return staffView(42, templateId: templateId, createdFor: createdFor);
  }
}

ShadButton _button(WidgetTester tester, String label) =>
    tester.widget<ShadButton>(find.widgetWithText(ShadButton, label));

void main() {
  testWidgets('Issue 108: Start review reads "Starting…" on a Start that is '
      'off while the draft is created', (tester) async {
    final held = Completer<void>();
    final results = <int?>[];
    final coach = viewer('kim', coach: true);
    await tallSurface(tester);
    await tester.pumpWidget(
      evaluationScope(
        templates: StubTemplates({1: template(1)}),
        evaluations: _HeldEvaluations(held),
        users: {
          'ana': userInfo('ana', 'Ana Rao'),
          'kim': userInfo('kim', 'Kim', coach: true),
        },
        events: {
          9: event(9, 'Spring camp', coaches: ['kim']),
        },
        enrollments: {
          9: {'ana': sdk.EnrollmentStatus.assigned},
        },
        child: Builder(
          builder: (context) => ShadButton(
            onPressed: () async => results.add(
              await showStartReviewDialog(
                context: context,
                currentUser: coach,
                templateId: 1,
                username: 'ana',
                eventId: 9,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(_button(tester, 'Start').enabled, isTrue);
    expect(find.text('Starting…'), findsNothing);

    await tester.tap(find.widgetWithText(ShadButton, 'Start'));
    await tester.pump();

    expect(find.widgetWithText(ShadButton, 'Start'), findsNothing);
    expect(_button(tester, 'Starting…').enabled, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    held.complete();
    await tester.pumpAndSettle();
    expect(results, [42]);
  });
}
