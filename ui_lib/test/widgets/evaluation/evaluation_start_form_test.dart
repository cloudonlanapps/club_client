import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/src/widgets/evaluation/start/evaluation_period_validators.dart'
    show EvaluationPeriodValidators;
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

const List<EvaluationStartChoice> _templates = [
  (id: 1, label: 'Skating'),
  (id: 2, label: 'Shooting'),
];
const List<EvaluationStartMember> _members = [
  (username: 'ana', label: 'Ana Rao'),
  (username: 'ben', label: 'Ben Iyer'),
];
const List<EvaluationStartChoice> _events = [(id: 9, label: 'Spring camp')];
const Map<String, List<EvaluationStartChoice>> _byMember = {
  'ana': [(id: 9, label: 'Spring camp')],
  'ben': [(id: 7, label: 'Autumn camp')],
};

Future<void> _openSelect(WidgetTester tester, String showing) async {
  await tester.tap(find.text(showing).last);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String option) async {
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<GlobalKey<EvaluationStartFormState>> _pump(
  WidgetTester tester, {
  EvaluationStartChoice? fixedTemplate,
  EvaluationStartMember? fixedMember,
  EvaluationStartChoice? fixedEvent,
  Map<String, List<EvaluationStartChoice>>? eventsByMember,
}) async {
  final key = GlobalKey<EvaluationStartFormState>();
  await tallSurface(tester);
  await tester.pumpWidget(
    wrapEvaluation(
      EvaluationStartForm(
        key: key,
        templates: _templates,
        members: _members,
        events: _events,
        fixedTemplate: fixedTemplate,
        fixedMember: fixedMember,
        fixedEvent: fixedEvent,
        eventsByMember: eventsByMember,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  group('Issue 173: EvaluationStartForm', () {
    testWidgets('Issue 173: a template and a member are required', (
      tester,
    ) async {
      final key = await _pump(tester);
      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('Choose a template.'), findsOneWidget);
      expect(find.text('Choose a member.'), findsOneWidget);
    });

    testWidgets('Issue 173: fixed values show read-only and are returned', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        fixedTemplate: _templates.first,
        fixedMember: _members.last,
        fixedEvent: _events.single,
      );
      expect(find.text('Skating'), findsOneWidget);
      expect(find.text('Ben Iyer'), findsOneWidget);
      expect(find.text('Spring camp'), findsOneWidget);
      expect(key.currentState!.validate(), {
        EvaluationStartFormFields.templateId: 1,
        EvaluationStartFormFields.memberId: 'ben',
        EvaluationStartFormFields.eventId: 9,
        EvaluationStartFormFields.periodStartId: null,
        EvaluationStartFormFields.periodEndId: null,
      });
    });

    testWidgets('Issue 173: the event defaults to General', (tester) async {
      final key = await _pump(
        tester,
        fixedTemplate: _templates.first,
        fixedMember: _members.first,
      );
      expect(find.text('General'), findsOneWidget);
      final values = key.currentState!.validate()!;
      expect(values[EvaluationStartFormFields.eventId], isNull);
      expect(values[EvaluationStartFormFields.memberId], 'ana');
    });

    test('Issue 173: the period needs both dates or neither, in order', () {
      final may = DateTime(2026, 5);
      final june = DateTime(2026, 6);
      expect(EvaluationPeriodValidators.period(null, null), isNull);
      expect(EvaluationPeriodValidators.period(may, june), isNull);
      expect(EvaluationPeriodValidators.period(may, may), isNull);
      expect(EvaluationPeriodValidators.period(may, null), isNotNull);
      expect(EvaluationPeriodValidators.period(null, june), isNotNull);
      expect(EvaluationPeriodValidators.period(june, may), isNotNull);
    });
  });

  group('Issue 173: events follow the member', () {
    testWidgets('Issue 173: a fixed member is offered only their own events', (
      tester,
    ) async {
      await _pump(
        tester,
        fixedMember: _members.last,
        eventsByMember: _byMember,
      );

      await _openSelect(tester, 'General');

      expect(find.text('Autumn camp'), findsOneWidget);
      expect(find.text('Spring camp'), findsNothing);
    });

    testWidgets('Issue 173: no member chosen offers General only', (
      tester,
    ) async {
      await _pump(tester, eventsByMember: _byMember);

      await _openSelect(tester, 'General');

      expect(find.text('Spring camp'), findsNothing);
      expect(find.text('Autumn camp'), findsNothing);
    });

    testWidgets(
      'Issue 173: a new member resets the event and offers their events',
      (tester) async {
        final key = await _pump(
          tester,
          fixedTemplate: _templates.first,
          eventsByMember: _byMember,
        );
        await _openSelect(tester, 'Choose a member');
        await _choose(tester, 'Ana Rao');
        await _openSelect(tester, 'General');
        await _choose(tester, 'Spring camp');

        await _openSelect(tester, 'Ana Rao');
        await _choose(tester, 'Ben Iyer');

        expect(
          key.currentState!.validate()![EvaluationStartFormFields.eventId],
          isNull,
        );
        await _openSelect(tester, 'General');
        expect(find.text('Autumn camp'), findsOneWidget);
        expect(find.text('Spring camp'), findsNothing);
      },
    );
  });

  group('Issue 173: EvaluationPeriodForm', () {
    testWidgets('Issue 173: returns the seeded period and is not dirty', (
      tester,
    ) async {
      final key = GlobalKey<EvaluationPeriodFormState>();
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationPeriodForm(
            key: key,
            initialValues: {
              EvaluationStartFormFields.periodStartId: DateTime(2026, 5),
              EvaluationStartFormFields.periodEndId: DateTime(2026, 6),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isFalse);
      expect(key.currentState!.validate(), {
        EvaluationStartFormFields.eventId: null,
        EvaluationStartFormFields.periodStartId: DateTime(2026, 5),
        EvaluationStartFormFields.periodEndId: DateTime(2026, 6),
      });
    });

    testWidgets('Issue 173: the event is seeded, offered with General and '
        'the given events, and returned by id', (tester) async {
      final key = GlobalKey<EvaluationPeriodFormState>();
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationPeriodForm(
            key: key,
            events: const [(id: 9, label: 'Spring camp')],
            initialValues: const {
              EvaluationStartFormFields.eventId: (id: 9, label: 'Spring camp'),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Event'), findsOneWidget);
      expect(key.currentState!.isDirty, isFalse);
      expect(
        key.currentState!.validate()?[EvaluationStartFormFields.eventId],
        9,
      );
      await _openSelect(tester, 'Spring camp');
      expect(find.text('General'), findsOneWidget);
      await _choose(tester, 'General');
      expect(key.currentState!.isDirty, isTrue);
      final values = key.currentState!.validate()!;
      expect(values.containsKey(EvaluationStartFormFields.eventId), isTrue);
      expect(values[EvaluationStartFormFields.eventId], isNull);
    });

    testWidgets('Issue 173: the current event stays offered when no longer '
        'among the events', (tester) async {
      final key = GlobalKey<EvaluationPeriodFormState>();
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationPeriodForm(
            key: key,
            events: const [(id: 9, label: 'Spring camp')],
            initialValues: const {
              EvaluationStartFormFields.eventId: (id: 4, label: 'Old camp'),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Old camp'), findsOneWidget);
      expect(
        key.currentState!.validate()?[EvaluationStartFormFields.eventId],
        4,
      );
      await _openSelect(tester, 'Old camp');
      await _choose(tester, 'Spring camp');
      expect(
        key.currentState!.validate()?[EvaluationStartFormFields.eventId],
        9,
      );
      expect(key.currentState!.isDirty, isTrue);
    });

    testWidgets('Issue 104: the form opens with its initialValues map, clean, '
        'and a changed date makes it dirty', (tester) async {
      final key = GlobalKey<EvaluationPeriodFormState>();
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationPeriodForm(
            key: key,
            events: const [(id: 9, label: 'Spring camp')],
            initialValues: {
              EvaluationStartFormFields.eventId: (id: 9, label: 'Spring camp'),
              EvaluationStartFormFields.periodStartId: DateTime(2026, 5),
              EvaluationStartFormFields.periodEndId: DateTime(2026, 6),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = key.currentState!;
      expect(find.text('Spring camp'), findsOneWidget);
      expect(state.isDirty, isFalse);
      expect(state.validate(), {
        EvaluationStartFormFields.eventId: 9,
        EvaluationStartFormFields.periodStartId: DateTime(2026, 5),
        EvaluationStartFormFields.periodEndId: DateTime(2026, 6),
      });

      state.formKey.currentState!.setFieldValue<DateTime?>(
        EvaluationStartFormFields.periodEndId,
        DateTime(2026, 6, 2),
      );
      await tester.pumpAndSettle();
      expect(state.isDirty, isTrue);
    });

    testWidgets('Issue 104: with no initialValues the form opens on General '
        'with no period, clean', (tester) async {
      final key = GlobalKey<EvaluationPeriodFormState>();
      await tester.pumpWidget(wrapEvaluation(EvaluationPeriodForm(key: key)));
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isFalse);
      expect(key.currentState!.validate(), {
        EvaluationStartFormFields.eventId: null,
        EvaluationStartFormFields.periodStartId: null,
        EvaluationStartFormFields.periodEndId: null,
      });
    });

    testWidgets('Issue 173: one date alone shows the form-level message', (
      tester,
    ) async {
      final key = GlobalKey<EvaluationPeriodFormState>();
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationPeriodForm(
            key: key,
            initialValues: {
              EvaluationStartFormFields.periodStartId: DateTime(2026, 5),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('Give both dates, or neither.'), findsOneWidget);
    });
  });
}
