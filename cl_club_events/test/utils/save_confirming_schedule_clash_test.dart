import 'package:cl_club_events/src/utils/save_confirming_schedule_clash.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/schedule_clash_fixtures.dart';

/// What one run of [saveConfirmingScheduleClash] did.
class _Run {
  final ClashingWrites writes = ClashingWrites();
  final List<bool> results = [];
  final List<Object> errors = [];

  /// Thrown by every write instead, when set.
  Exception? failure;
}

Future<_Run> _pump(WidgetTester tester) async {
  final run = _Run();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ShadButton(
            onPressed: () async {
              try {
                run.results.add(
                  await saveConfirmingScheduleClash(context, ({
                    required acceptConflicts,
                  }) async {
                    final failure = run.failure;
                    if (failure != null) throw failure;
                    run.writes.record(acceptConflicts: acceptConflicts);
                  }),
                );
              } on Object catch (e) {
                run.errors.add(e);
              }
            },
            child: const Text('save'),
          ),
        ),
      ),
    ),
  );
  return run;
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('save'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 278: saveConfirmingScheduleClash', () {
    testWidgets('Issue 278: no clash saves once, without accepting, and '
        'shows no dialog', (tester) async {
      final run = await _pump(tester);

      await _save(tester);

      expect(clashDialog, findsNothing);
      expect(run.writes.accepts, [false]);
      expect(run.results, [true]);
    });

    testWidgets('Issue 278: a clash then Save anyway re-sends with '
        'acceptConflicts true', (tester) async {
      final run = await _pump(tester);
      run.writes.clash = venueClash();

      await _save(tester);
      expect(clashDialog, findsOneWidget);
      expect(run.results, isEmpty);

      await saveAnyway(tester);

      expect(run.writes.accepts, [false, true]);
      expect(run.results, [true]);
    });

    testWidgets('Issue 278: a clash then Cancel sends nothing more', (
      tester,
    ) async {
      final run = await _pump(tester);
      run.writes.clash = coachOnlyClash();

      await _save(tester);
      await cancelClash(tester);

      expect(run.writes.accepts, [false]);
      expect(run.results, [false]);
      expect(run.errors, isEmpty);
    });

    testWidgets('Issue 278: any other refusal is rethrown, with no dialog', (
      tester,
    ) async {
      final run = await _pump(tester);
      run.failure = const ServerException(
        statusCode: 422,
        code: SdkErrorCode.invalidState,
        message: 'started',
      );

      await _save(tester);

      expect(clashDialog, findsNothing);
      expect(run.errors.single, isA<ServerException>());
      expect(run.results, isEmpty);
    });
  });
}
