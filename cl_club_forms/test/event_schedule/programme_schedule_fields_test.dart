import 'package:cl_club_forms/src/models/programme_schedule_data.dart';
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/programme_schedule_fields.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/weekday_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<GlobalKey<ShadFormState>> _pumpField(
  WidgetTester tester, {
  ProgrammeScheduleData? initialValue,
  bool enabled = true,
  bool useAggregateValidator = false,
}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final formKey = GlobalKey<ShadFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ShadForm(
            key: formKey,
            child: ProgrammeScheduleFormField(
              id: 'schedule',
              initialValue: initialValue,
              enabled: enabled,
              validator: useAggregateValidator
                  ? ProgrammeScheduleFormField.aggregateValidator
                  : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return formKey;
}

ProgrammeScheduleData? _read(GlobalKey<ShadFormState> formKey) =>
    formKey.currentState!.value['schedule'] as ProgrammeScheduleData?;

ProgrammeScheduleFormFieldBodyState _body(WidgetTester tester) =>
    tester.state<ProgrammeScheduleFormFieldBodyState>(
      find.byType(ProgrammeScheduleFormFieldBody),
    );

void main() {
  group('ProgrammeScheduleFormField static helpers', () {
    test('parseHM accepts canonical 24-hour HH:MM and HH:MM:SS', () {
      expect(ProgrammeScheduleFormField.parseHM('06:00'), 360);
      expect(ProgrammeScheduleFormField.parseHM('06:45:00'), 405);
      expect(ProgrammeScheduleFormField.parseHM('13:05'), 13 * 60 + 5);
      expect(ProgrammeScheduleFormField.parseHM('00:00'), 0);
    });

    test('parseHM rejects out-of-range hours and minutes', () {
      expect(ProgrammeScheduleFormField.parseHM('24:00'), isNull);
      expect(ProgrammeScheduleFormField.parseHM('10:60'), isNull);
      expect(ProgrammeScheduleFormField.parseHM('-1:00'), isNull);
    });

    test('parseHM falls back to legacy 12-hour AM/PM', () {
      expect(ProgrammeScheduleFormField.parseHM('6:00 AM'), 360);
      expect(ProgrammeScheduleFormField.parseHM('6:45 AM'), 405);
      expect(ProgrammeScheduleFormField.parseHM('1:05 PM'), 13 * 60 + 5);
      expect(ProgrammeScheduleFormField.parseHM('12:00 AM'), 0);
      expect(ProgrammeScheduleFormField.parseHM('12:00 PM'), 12 * 60);
    });

    test('parseHM returns null for unparseable input', () {
      expect(ProgrammeScheduleFormField.parseHM('xx'), isNull);
      expect(ProgrammeScheduleFormField.parseHM('10'), isNull);
      expect(ProgrammeScheduleFormField.parseHM(''), isNull);
    });

    test('formatHM zero-pads to canonical 24-hour HH:MM', () {
      expect(ProgrammeScheduleFormField.formatHM(9 * 60), '09:00');
      expect(ProgrammeScheduleFormField.formatHM(13 * 60 + 5), '13:05');
      expect(ProgrammeScheduleFormField.formatHM(0), '00:00');
    });

    test('sessionMinutes returns end - start across both formats', () {
      expect(
        ProgrammeScheduleFormField.sessionMinutes(
          const SessionInput(
            name: 'a',
            startTime: '06:00',
            endTime: '06:45',
          ),
        ),
        45,
      );
      expect(
        ProgrammeScheduleFormField.sessionMinutes(
          const SessionInput(
            name: 'a',
            startTime: '6:00 AM',
            endTime: '6:45 AM',
          ),
        ),
        45,
      );
    });

    test('sessionMinutes returns 0 when either side fails to parse', () {
      expect(
        ProgrammeScheduleFormField.sessionMinutes(
          const SessionInput(name: 'a', startTime: 'xx', endTime: '06:45'),
        ),
        0,
      );
    });
  });

  group('ProgrammeScheduleFormField.aggregateValidator', () {
    test('rejects null', () {
      expect(
        ProgrammeScheduleFormField.aggregateValidator(null),
        'Schedule is required',
      );
    });

    test('rejects empty weekdays', () {
      expect(
        ProgrammeScheduleFormField.aggregateValidator(
          const ProgrammeScheduleData(),
        ),
        'Pick at least one day',
      );
    });

    test('rejects missing start date', () {
      expect(
        ProgrammeScheduleFormField.aggregateValidator(
          const ProgrammeScheduleData(weekdays: {1}),
        ),
        'Start date is required',
      );
    });

    test('rejects missing session start time', () {
      final value = ProgrammeScheduleData(
        weekdays: const {1},
        startDate: DateTime(2026),
      );
      expect(
        ProgrammeScheduleFormField.aggregateValidator(value),
        'Start time is required',
      );
    });

    test('rejects non-positive duration', () {
      final value = ProgrammeScheduleData(
        weekdays: const {1},
        startDate: DateTime(2026),
        sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        totalDurationMinutes: 0,
      );
      expect(
        ProgrammeScheduleFormField.aggregateValidator(value),
        'Duration must be greater than 0',
      );
    });

    test('rejects total duration above 4h cap', () {
      final value = ProgrammeScheduleData(
        weekdays: const {1},
        startDate: DateTime(2026),
        sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        totalDurationMinutes: 5 * 60,
      );
      expect(
        ProgrammeScheduleFormField.aggregateValidator(value),
        'Programme session cannot exceed 4h',
      );
    });

    test('rejects end date before start date when not ongoing', () {
      final value = ProgrammeScheduleData(
        weekdays: const {1},
        startDate: DateTime(2026, 5, 10),
        endDate: DateTime(2026, 5, 1),
        hasNoEndDate: false,
        sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        totalDurationMinutes: 60,
      );
      expect(
        ProgrammeScheduleFormField.aggregateValidator(value),
        'End date must be after start date',
      );
    });

    test('accepts a fully populated value', () {
      final value = ProgrammeScheduleData(
        weekdays: const {1, 3, 5},
        startDate: DateTime(2026),
        sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        totalDurationMinutes: 60,
      );
      expect(
        ProgrammeScheduleFormField.aggregateValidator(value),
        isNull,
      );
    });
  });

  group('ProgrammeScheduleFormField widget', () {
    testWidgets('renders weekday chips, date pickers, time picker, duration', (
      tester,
    ) async {
      await _pumpField(tester);
      expect(find.byType(WeekdayChip), findsNWidgets(7));
      expect(find.text('Days of Week *'), findsOneWidget);
      expect(find.text('Start Date *'), findsOneWidget);
      expect(find.text('End Date'), findsOneWidget);
      expect(find.text('Start Time *'), findsOneWidget);
      expect(find.text('Duration *'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
    });

    testWidgets('initial value seeds weekdays, duration text, and body state', (
      tester,
    ) async {
      final initial = ProgrammeScheduleData(
        weekdays: const {1, 3, 5},
        startDate: DateTime(2026),
        endDate: DateTime(2026, 6, 1),
        hasNoEndDate: false,
        sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        totalDurationMinutes: 90,
      );
      await _pumpField(tester, initialValue: initial);

      final body = _body(tester);
      expect(body.selectedWeekdays, {1, 3, 5});
      expect(body.selectedStartDate, DateTime(2026));
      expect(body.selectedEndDate, DateTime(2026, 6, 1));
      expect(body.hasNoEndDate, isFalse);
      expect(
        body.selectedSessionStartTime,
        const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
      );
      expect(body.totalDurationMinutes, 90);
      // The Duration picker and the one session both show the length.
      expect(find.text('1:30'), findsNWidgets(2));
    });

    testWidgets('tapping a weekday chip emits the toggled day in form value', (
      tester,
    ) async {
      final initial = ProgrammeScheduleData(
        weekdays: const {},
        startDate: DateTime(2026),
        sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
      );
      final formKey = await _pumpField(tester, initialValue: initial);

      await tester.tap(find.byType(WeekdayChip).first);
      await tester.pumpAndSettle();

      expect(_read(formKey)!.weekdays, {1});
    });

    testWidgets(
      'tapping a selected weekday chip removes it from the form value',
      (tester) async {
        final initial = ProgrammeScheduleData(
          weekdays: const {1, 2},
          startDate: DateTime(2026),
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        );
        final formKey = await _pumpField(tester, initialValue: initial);

        await tester.tap(find.byType(WeekdayChip).first);
        await tester.pumpAndSettle();

        expect(_read(formKey)!.weekdays, {2});
      },
    );

    testWidgets(
      'parsing duration text updates totalDurationMinutes and resets sessions',
      (tester) async {
        final initial = ProgrammeScheduleData(
          weekdays: const {1},
          startDate: DateTime(2026),
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          totalDurationMinutes: 60,
          sessions: const [
            SessionInput(name: 'A', startTime: '09:00', endTime: '09:30'),
            SessionInput(name: 'B', startTime: '09:30', endTime: '10:00'),
          ],
        );
        final formKey = await _pumpField(tester, initialValue: initial);

        final body = _body(tester);
        // Initial state: split into two sessions of 30m each.
        expect(body.sessionDurations, [30, 30]);

        body.onTotalDurationChanged(120);
        await tester.pumpAndSettle();

        expect(body.totalDurationMinutes, 120);
        // A new total collapses back to a single session.
        expect(body.sessionDurations, [120]);

        final value = _read(formKey)!;
        expect(value.totalDurationMinutes, 120);
        // Single-row collapses to [] per buildSessions().
        expect(value.sessions, isEmpty);
      },
    );

    testWidgets(
      'session-split absorption: shrinking row 1 spills into a new last row',
      (tester) async {
        final initial = ProgrammeScheduleData(
          weekdays: const {1},
          startDate: DateTime(2026),
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          totalDurationMinutes: 120,
        );
        final formKey = await _pumpField(tester, initialValue: initial);

        final body = _body(tester);
        // Single 120m row to start.
        expect(body.sessionDurations, [120]);

        // Shrink row 0 to 30m → 90m must spill into a freshly added last row.
        body.onSessionDurationChanged(0, const Duration(minutes: 30));
        await tester.pumpAndSettle();

        expect(body.sessionDurations, [30, 90]);
        // Now there are two sessions, so buildSessions() emits a list with
        // synthetic names and the cursor advancing from 09:00.
        final value = _read(formKey)!;
        expect(value.sessions.length, 2);
        expect(value.sessions[0].startTime, '09:00');
        expect(value.sessions[0].endTime, '09:30');
        expect(value.sessions[1].startTime, '09:30');
        expect(value.sessions[1].endTime, '11:00');
      },
    );

    testWidgets(
      'session-split absorption: growing row 1 absorbs from the last row',
      (tester) async {
        final initial = ProgrammeScheduleData(
          weekdays: const {1},
          startDate: DateTime(2026),
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          totalDurationMinutes: 120,
        );
        await _pumpField(tester, initialValue: initial);

        final body = _body(tester)
          // Split into two rows first.
          ..onSessionDurationChanged(0, const Duration(minutes: 30));
        await tester.pumpAndSettle();
        expect(body.sessionDurations, [30, 90]);

        // Grow row 0 back to 90m. The last row should absorb the delta and
        // collapse if fully consumed.
        body.onSessionDurationChanged(0, const Duration(minutes: 90));
        await tester.pumpAndSettle();
        expect(body.sessionDurations, [90, 30]);
      },
    );

    testWidgets(
      'removeSession refunds the freed minutes to the last remaining row',
      (tester) async {
        final initial = ProgrammeScheduleData(
          weekdays: const {1},
          startDate: DateTime(2026),
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          totalDurationMinutes: 120,
        );
        await _pumpField(tester, initialValue: initial);

        final body = _body(tester)
          ..onSessionDurationChanged(0, const Duration(minutes: 30));
        await tester.pumpAndSettle();
        expect(body.sessionDurations, [30, 90]);

        body.removeSession(0);
        await tester.pumpAndSettle();
        // The freed 30m flows into the (now sole) last row.
        expect(body.sessionDurations, [120]);
      },
    );

    testWidgets(
      'removeSession is a no-op when only one session remains',
      (tester) async {
        await _pumpField(
          tester,
          initialValue: ProgrammeScheduleData(
            weekdays: const {1},
            startDate: DateTime(2026),
            sessionStartTime: const ShadTimeOfDay(
              hour: 9,
              minute: 0,
              second: 0,
            ),
            totalDurationMinutes: 60,
          ),
        );
        final body = _body(tester)..removeSession(0);
        expect(body.sessionDurations, [60]);
      },
    );

    testWidgets(
      'clearEndDate sets endDate to null, hasNoEndDate to true, and emits',
      (tester) async {
        final initial = ProgrammeScheduleData(
          weekdays: const {1},
          startDate: DateTime(2026),
          endDate: DateTime(2026, 6, 1),
          hasNoEndDate: false,
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          totalDurationMinutes: 60,
        );
        final formKey = await _pumpField(tester, initialValue: initial);

        // Clear button is rendered only when an end date is set.
        expect(find.text('Clear'), findsOneWidget);
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        final body = _body(tester);
        expect(body.selectedEndDate, isNull);
        expect(body.hasNoEndDate, isTrue);

        final value = _read(formKey)!;
        expect(value.endDate, isNull);
        expect(value.hasNoEndDate, isTrue);
        // The clear button hides once the end date is gone.
        expect(find.text('Clear'), findsNothing);
      },
    );

    testWidgets(
      'validateEndDate rejects an end date earlier than the start date',
      (tester) async {
        await _pumpField(
          tester,
          initialValue: ProgrammeScheduleData(
            weekdays: const {1},
            startDate: DateTime(2026, 5, 10),
            sessionStartTime: const ShadTimeOfDay(
              hour: 9,
              minute: 0,
              second: 0,
            ),
            totalDurationMinutes: 60,
          ),
        );
        final body = _body(tester);
        expect(
          body.validateEndDate(DateTime(2026, 5, 1)),
          'End date must be after start date',
        );
        expect(body.validateEndDate(DateTime(2026, 5, 11)), isNull);
        expect(body.validateEndDate(null), isNull);
      },
    );

    testWidgets(
      'aggregate validator surfaces the first failure via saveAndValidate',
      (tester) async {
        final formKey = await _pumpField(
          tester,
          initialValue: const ProgrammeScheduleData(),
          useAggregateValidator: true,
        );
        final ok = formKey.currentState!.saveAndValidate();
        expect(ok, isFalse);
        await tester.pumpAndSettle();
        // Inline weekday-required validator + aggregate both surface
        // "Pick at least one day".
        expect(find.text('Pick at least one day'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('enabled=false disables the duration input', (tester) async {
      await _pumpField(
        tester,
        initialValue: ProgrammeScheduleData(
          weekdays: const {1},
          startDate: DateTime(2026),
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          totalDurationMinutes: 60,
        ),
        enabled: false,
      );

      final inputs = tester.widgetList<ShadInputFormField>(
        find.byType(ShadInputFormField),
      );
      expect(inputs.every((i) => !i.enabled), isTrue);
    });

    testWidgets(
      'pre-seeded ShadTimePickerController has minute/second defaults',
      (tester) async {
        await _pumpField(tester);
        final body = _body(tester);
        expect(body.sessionStartTimeController.minute, 0);
        expect(body.sessionStartTimeController.second, 0);
        expect(body.sessionStartTimeController.hour, isNull);
      },
    );
  });
}
