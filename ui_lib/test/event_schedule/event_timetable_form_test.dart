import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        EventTimetableForm,
        EventTimetableFormState,
        EventTimetableFormValidators,
        EventTimetableValue,
        SessionInput,
        TimetableScheduleOption;

const ShadTimeOfDay _six = ShadTimeOfDay(hour: 6, minute: 0, second: 0);

const List<SessionInput> _split = [
  SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '06:30'),
  SessionInput(name: 'Drills', startTime: '06:30', endTime: '08:00'),
];

const TimetableScheduleOption _earlier = TimetableScheduleOption(
  id: 10,
  label: 'From 1 Jun 2026 until 1 Jul 2026',
  startTime: _six,
  totalMinutes: 90,
);

const TimetableScheduleOption _current = TimetableScheduleOption(
  id: 11,
  label: 'From 1 Jul 2026 (current)',
  startTime: _six,
  totalMinutes: 120,
  sessions: _split,
);

Future<EventTimetableFormState> _pump(
  WidgetTester tester, {
  required List<TimetableScheduleOption> schedules,
  int? initialScheduleIndex,
}) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey<EventTimetableFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EventTimetableForm(
            key: key,
            schedules: schedules,
            initialScheduleIndex: initialScheduleIndex,
            note: 'Corrects the timetable; no dates move.',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState!;
}

void main() {
  group('Issue 85: EventTimetableFormValidators.sessionsTotal', () {
    test('Issue 85: accepts no split and a split that fills the day', () {
      expect(EventTimetableFormValidators.sessionsTotal(const [], 120), isNull);
      expect(EventTimetableFormValidators.sessionsTotal(_split, 120), isNull);
    });

    test('Issue 85: rejects a split that does not fill the day', () {
      expect(
        EventTimetableFormValidators.sessionsTotal(_split, 90),
        EventTimetableFormValidators.totalMismatchMessage,
      );
    });
  });

  group('Issue 85: EventTimetableForm', () {
    testWidgets('Issue 85: an unedited form is clean and validates as seeded', (
      tester,
    ) async {
      final state = await _pump(tester, schedules: const [_current]);

      expect(state.isDirty, isFalse);
      expect(
        state.validate(),
        const EventTimetableValue(scheduleId: 11, sessions: _split),
      );
      expect(find.text('Corrects the timetable; no dates move.'), findsOne);
      expect(
        find.text('From 1 Jul 2026 (current)'),
        findsNothing,
        reason: 'one schedule needs no schedule picker',
      );
    });

    testWidgets('Issue 85: a changed split is dirty and returned', (
      tester,
    ) async {
      final state = await _pump(tester, schedules: const [_current]);

      state.formKey.currentState!.setFieldValue<List<SessionInput>>(
        EventTimetableForm.sessionsId,
        const [],
      );
      await tester.pump();

      expect(state.isDirty, isTrue);
      expect(
        state.validate(),
        const EventTimetableValue(scheduleId: 11, sessions: []),
      );
    });

    testWidgets('Issue 85: defaults to the latest schedule and switches', (
      tester,
    ) async {
      final state = await _pump(tester, schedules: const [_earlier, _current]);

      expect(state.selectedSchedule, _current, reason: 'the latest by default');
      expect(find.text('From 1 Jul 2026 (current)'), findsOne);

      state.formKey.currentState!.setFieldValue<int>(
        EventTimetableForm.scheduleId,
        0,
      );
      await tester.pumpAndSettle();

      expect(state.selectedSchedule, _earlier);
      expect(
        state.validate(),
        const EventTimetableValue(scheduleId: 10, sessions: []),
        reason: "the earlier schedule's own timetable is edited",
      );
      expect(state.isDirty, isFalse);
    });

    testWidgets(
      'Issue 85: a split that does not fill the day is refused inline',
      (tester) async {
        final state = await _pump(
          tester,
          schedules: const [
            TimetableScheduleOption(
              id: 11,
              label: 'current',
              startTime: _six,
              totalMinutes: 90,
              sessions: _split,
            ),
          ],
        );

        expect(state.validate(), isNull);
        await tester.pump();
        expect(
          find.text(EventTimetableFormValidators.totalMismatchMessage),
          findsOne,
        );
      },
    );

    testWidgets('Issue 85: a refusal from the server shows against the form', (
      tester,
    ) async {
      final state = await _pump(tester, schedules: const [_current]);

      state.showSessionsError('The sessions must add up to 2h.');
      await tester.pump();

      expect(find.text('The sessions must add up to 2h.'), findsOne);
    });
  });
}
