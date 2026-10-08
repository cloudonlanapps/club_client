import 'package:cl_club_evaluation/src/models/evaluation_period_form_submit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show EvaluationStartFormFields;

import '../support/evaluation_scope.dart';

/// The Review Period form's values: [event], from [start] to [end] (local
/// dates).
Map<String, dynamic> _values({int? event, DateTime? start, DateTime? end}) => {
  EvaluationStartFormFields.eventId: event,
  EvaluationStartFormFields.periodStartId: start,
  EvaluationStartFormFields.periodEndId: end,
};

void main() {
  group('Issue 104: buildEvaluationPeriodFormInitialValues', () {
    test('Issue 104: an evaluation gives its event as named and its period '
        'as local days', () {
      final evaluation = staffView(
        5,
        eventId: 9,
        periodStartUtc: DateTime.utc(2026, 5),
        periodEndUtc: DateTime.utc(2026, 5, 31),
      );

      expect(
        buildEvaluationPeriodFormInitialValues(
          evaluation,
          event: (id: 9, label: 'Spring camp'),
        ),
        {
          EvaluationStartFormFields.eventId: (id: 9, label: 'Spring camp'),
          EvaluationStartFormFields.periodStartId: DateTime(2026, 5),
          EvaluationStartFormFields.periodEndId: DateTime(2026, 5, 31),
        },
      );
    });

    test('Issue 104: a general evaluation with no period gives no event '
        'and no dates', () {
      expect(buildEvaluationPeriodFormInitialValues(staffView(5)), {
        EvaluationStartFormFields.eventId: null,
        EvaluationStartFormFields.periodStartId: null,
        EvaluationStartFormFields.periodEndId: null,
      });
    });

    test('Issue 104: no evaluation gives no event and no dates', () {
      expect(buildEvaluationPeriodFormInitialValues(null), {
        EvaluationStartFormFields.eventId: null,
        EvaluationStartFormFields.periodStartId: null,
        EvaluationStartFormFields.periodEndId: null,
      });
    });
  });

  group('Issue 173: EvaluationPeriodFormSubmit.updateReviewPeriod', () {
    final may1 = DateTime.utc(2026, 5);
    final may31 = DateTime.utc(2026, 5, 31);
    final draft = staffView(
      5,
      eventId: 9,
      periodStartUtc: may1,
      periodEndUtc: may31,
    );

    Future<List<String>> submit(Map<String, dynamic> values) async {
      final stub = StubEvaluations({5: draft});
      await EvaluationPeriodFormSubmit.updateReviewPeriod(
        evaluation: draft,
        values: values,
        notifier: stub,
      );
      return stub.calls;
    }

    test('Issue 173: a new event alone sends only the event', () async {
      final calls = await submit(
        _values(event: 8, start: DateTime(2026, 5), end: DateTime(2026, 5, 31)),
      );
      expect(calls, ['update 5 event=8 start=- end=-']);
    });

    test('Issue 173: General sends the event cleared', () async {
      final calls = await submit(
        _values(start: DateTime(2026, 5), end: DateTime(2026, 5, 31)),
      );
      expect(calls, ['update 5 event=null start=- end=-']);
    });

    test('Issue 173: a new period alone sends both dates, as UTC '
        'midnights', () async {
      final calls = await submit(
        _values(event: 9, start: DateTime(2026, 5, 2), end: DateTime(2026, 6)),
      );
      final start = DateTime.utc(2026, 5, 2);
      final end = DateTime.utc(2026, 6);
      expect(calls, ['update 5 event=- start=$start end=$end']);
    });

    test('Issue 173: event and period change together; no dates clear the '
        'period', () async {
      final calls = await submit(_values(event: 8));
      expect(calls, ['update 5 event=8 start=null end=null']);
    });

    test('Issue 173: nothing changed makes no call', () async {
      final calls = await submit(
        _values(event: 9, start: DateTime(2026, 5), end: DateTime(2026, 5, 31)),
      );
      expect(calls, isEmpty);
    });
  });
}
