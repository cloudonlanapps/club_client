import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/evaluation_scope.dart';

Future<List<int?>> _open(
  WidgetTester tester, {
  required StubEvaluations evaluations,
  int? templateId,
  String? username,
  int? eventId,
}) async {
  final results = <int?>[];
  final coach = viewer('kim', coach: true);
  await tallSurface(tester);
  await tester.pumpWidget(
    evaluationScope(
      templates: StubTemplates({1: template(1)}),
      evaluations: evaluations,
      users: {
        'ana': userInfo('ana', 'Ana Rao'),
        'kim': userInfo('kim', 'Kim', coach: true),
      },
      events: {
        9: event(9, 'Spring camp', coaches: ['kim']),
        8: event(8, 'Autumn camp', coaches: ['kim']),
        7: event(7, 'Winter league', coaches: ['kim']),
      },
      enrollments: {
        9: {'ana': sdk.EnrollmentStatus.assigned},
        7: {'ana': sdk.EnrollmentStatus.withdrawn},
      },
      child: Builder(
        builder: (context) => ShadButton(
          onPressed: () async => results.add(
            await showStartReviewDialog(
              context: context,
              currentUser: coach,
              templateId: templateId,
              username: username,
              eventId: eventId,
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

void main() {
  group('Issue 173: showStartReviewDialog', () {
    testWidgets('Issue 173: an enrolment row fixes the member and the event; '
        'Start creates the draft and returns its id', (tester) async {
      final stub = StubEvaluations({});
      final results = await _open(
        tester,
        evaluations: stub,
        templateId: 1,
        username: 'ana',
        eventId: 9,
      );
      expect(find.text('Ana Rao'), findsOneWidget);
      expect(find.text('Spring camp'), findsOneWidget);
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['create 1 ana 9']);
      expect(results, [42]);
    });

    testWidgets('Issue 173: a profile fixes the member; the event defaults '
        'to General', (tester) async {
      final stub = StubEvaluations({});
      await _open(tester, evaluations: stub, templateId: 1, username: 'ana');
      expect(find.text('General'), findsOneWidget);
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['create 1 ana null']);
    });

    testWidgets('Issue 173: a profile offers only the events the member is '
        'enrolled in', (tester) async {
      await _open(
        tester,
        evaluations: StubEvaluations({}),
        templateId: 1,
        username: 'ana',
      );

      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      expect(find.text('Spring camp'), findsOneWidget);
      expect(find.text('Autumn camp'), findsNothing);
      expect(find.text('Winter league'), findsNothing);
    });

    testWidgets('Issue 173: NOT_ELIGIBLE shows inline and keeps the dialog', (
      tester,
    ) async {
      final stub = StubEvaluations(
        {},
        createError: const sdk.ServerException(
          statusCode: 422,
          code: sdk.SdkErrorCode.notEligible,
          message: 'not eligible',
        ),
      );
      final results = await _open(
        tester,
        evaluations: stub,
        templateId: 1,
        username: 'ana',
        eventId: 9,
      );
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(
        find.text('The member is not eligible for this event and period.'),
        findsOneWidget,
      );
      expect(find.text('Start a review'), findsOneWidget);
      expect(results, isEmpty);
    });

    testWidgets('Issue 173: DUPLICATE_EVALUATION shows a friendly message '
        'inline and keeps the dialog', (tester) async {
      final stub = StubEvaluations(
        {},
        createError: const sdk.ServerException(
          statusCode: 422,
          code: 'DUPLICATE_EVALUATION',
          message: 'raw duplicate',
        ),
      );
      final results = await _open(
        tester,
        evaluations: stub,
        templateId: 1,
        username: 'ana',
        eventId: 9,
      );
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'A review of this member with this template and period already '
          'exists.',
        ),
        findsOneWidget,
      );
      expect(find.text('raw duplicate'), findsNothing);
      expect(find.text('Start a review'), findsOneWidget);
      expect(results, isEmpty);
    });
  });
}
