// Issue 92: Start review shows a refusal inside its form, and its Cancel
// does nothing while the draft is created.
import 'dart:async';

import 'package:cl_club_evaluation/src/widgets/start_review_dialog.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EvaluationStartForm;

import '../support/dialog_dismissal.dart';
import '../support/evaluation_scope.dart';

const sdk.ServerException _notEligible = sdk.ServerException(
  statusCode: 422,
  code: sdk.SdkErrorCode.notEligible,
  message: 'not eligible',
);

const String _notEligibleText =
    'The member is not eligible for this event and period.';

/// Evaluations whose creates answer in turn from [answers]: an exception
/// to throw, or a completer to wait on.
class _ScriptedEvaluations extends StubEvaluations {
  _ScriptedEvaluations(this.answers) : super({});

  final List<Object?> answers;

  @override
  Future<sdk.EvaluationStaffView> createEvaluation({
    required int templateId,
    required String createdFor,
    int? eventId,
    DateTime? periodStartUtc,
    DateTime? periodEndUtc,
  }) async {
    calls.add('create $templateId $createdFor $eventId');
    final answer = answers.isEmpty ? null : answers.removeAt(0);
    if (answer is Completer<void>) await answer.future;
    if (answer is Exception) throw answer;
    return staffView(42, templateId: templateId, createdFor: createdFor);
  }
}

Future<List<int?>> _open(WidgetTester tester, StubEvaluations stub) async {
  final results = <int?>[];
  final coach = viewer('kim', coach: true);
  await tallSurface(tester);
  await tester.pumpWidget(
    evaluationScope(
      templates: StubTemplates({1: template(1)}),
      evaluations: stub,
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
  return results;
}

ShadButton _button(WidgetTester tester, String label) => tester.widget(
  find.ancestor(of: find.text(label), matching: find.byType(ShadButton)).first,
);

void main() {
  group('Issue 92: StartReviewDialog', () {
    testWidgets('Issue 92: a refusal shows inside the start form and goes '
        'on the next validate', (tester) async {
      final wait = Completer<void>();
      final stub = _ScriptedEvaluations([_notEligible, wait]);
      final results = await _open(tester, stub);

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(EvaluationStartForm),
          matching: find.text(_notEligibleText),
        ),
        findsOneWidget,
      );
      expect(find.text(_notEligibleText), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(find.text(_notEligibleText), findsNothing);

      wait.complete();
      await tester.pumpAndSettle();
      expect(results, [42]);
    });

    testWidgets('Issue 92: Cancel does nothing while the draft is created', (
      tester,
    ) async {
      final wait = Completer<void>();
      final stub = _ScriptedEvaluations([wait]);
      final results = await _open(tester, stub);

      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(_button(tester, 'Cancel').onPressed, isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('Start a review'), findsOneWidget);
      expect(results, isEmpty);

      wait.complete();
      await tester.pumpAndSettle();
      expect(results, [42]);
    });
    testWidgets('Issue 113: while the draft is created, the X, a tap '
        'outside, Escape and system back do not close Start review', (
      tester,
    ) async {
      final wait = Completer<void>();
      final stub = _ScriptedEvaluations([wait]);
      final results = await _open(tester, stub);

      await tester.tap(find.text('Start'));
      await tester.pump();

      await expectNoDismissal(tester, find.byType(StartReviewDialog));
      expect(results, isEmpty);

      wait.complete();
      await tester.pumpAndSettle();
      expect(find.byType(StartReviewDialog), findsNothing);
      expect(results, [42]);
    });
  });
}
