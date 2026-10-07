import 'package:cl_club_forms/src/models/camp_schedule_data.dart';
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_date_exclusion_calendar.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<GlobalKey<ShadFormState>> _pumpField(
  WidgetTester tester, {
  CampScheduleData? initialValue,
  bool enabled = true,
  bool useAggregateValidator = false,
}) async {
  tester.view.physicalSize = const Size(1400, 3200);
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
            child: CampScheduleFormField(
              id: 'schedule',
              initialValue: initialValue,
              enabled: enabled,
              validator: useAggregateValidator
                  ? CampScheduleFormField.aggregateValidator
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

CampScheduleData? _read(GlobalKey<ShadFormState> formKey) =>
    formKey.currentState!.value['schedule'] as CampScheduleData?;

CampScheduleFormFieldBodyState _body(WidgetTester tester) =>
    tester.state<CampScheduleFormFieldBodyState>(
      find.byType(CampScheduleFormFieldBody),
    );

void main() {
  group('CampScheduleFormField.aggregateValidator', () {
    test('rejects null', () {
      expect(
        CampScheduleFormField.aggregateValidator(null),
        'Schedule is required',
      );
    });

    test('rejects missing start date', () {
      expect(
        CampScheduleFormField.aggregateValidator(const CampScheduleData()),
        'Start date is required',
      );
    });

    test('rejects training days < 1', () {
      final value = CampScheduleData(
        startDate: DateTime(2026),
        trainingDays: 0,
      );
      expect(
        CampScheduleFormField.aggregateValidator(value),
        'Training days must be at least 1',
      );
    });

    test('rejects missing session start time', () {
      final value = CampScheduleData(
        startDate: DateTime(2026),
        trainingDays: 5,
      );
      expect(
        CampScheduleFormField.aggregateValidator(value),
        'Start time is required',
      );
    });

    test('rejects non-positive duration', () {
      final value = CampScheduleData(
        startDate: DateTime(2026),
        trainingDays: 5,
        sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        durationMinutes: 0,
      );
      expect(
        CampScheduleFormField.aggregateValidator(value),
        'Duration must be greater than 0',
      );
    });

    test('accepts a fully populated value', () {
      final value = CampScheduleData(
        startDate: DateTime(2026),
        trainingDays: 5,
        sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        durationMinutes: 120,
      );
      expect(CampScheduleFormField.aggregateValidator(value), isNull);
    });
  });

  group('CampScheduleFormField widget', () {
    testWidgets('renders all top-level row labels', (tester) async {
      await _pumpField(tester);
      expect(find.text('Start Date *'), findsOneWidget);
      expect(find.text('Training Days *'), findsOneWidget);
      expect(find.text('Start Time *'), findsOneWidget);
      expect(find.text('Duration *'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
    });

    testWidgets('initial value seeds body state and controllers', (
      tester,
    ) async {
      final initial = CampScheduleData(
        startDate: DateTime(2026),
        trainingDays: 4,
        sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        durationMinutes: 90,
      );
      await _pumpField(tester, initialValue: initial);

      final body = _body(tester);
      expect(body.selectedStartDate, DateTime(2026));
      expect(body.actualTrainingDays, 4);
      expect(body.durationMinutes, 90);
      expect(body.durationController.text, '1h 30m');
      expect(body.trainingDaysController.text, '4');
    });

    testWidgets(
      'rest-day calendar appears once a start date is set, not before',
      (tester) async {
        await _pumpField(tester);
        expect(find.byType(CampDateExclusionCalendar), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpField(
          tester,
          initialValue: CampScheduleData(
            startDate: DateTime(2026),
            trainingDays: 5,
            sessionStartTime: const ShadTimeOfDay(
              hour: 9,
              minute: 0,
              second: 0,
            ),
            durationMinutes: 90,
          ),
        );
        expect(find.byType(CampDateExclusionCalendar), findsOneWidget);
      },
    );

    testWidgets('training-days input updates body state and form value', (
      tester,
    ) async {
      final initial = CampScheduleData(
        startDate: DateTime(2026),
        trainingDays: 5,
        sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        durationMinutes: 90,
      );
      final formKey = await _pumpField(tester, initialValue: initial);
      final body = _body(tester);

      body
        // setState is protected; calling it directly mirrors how the
        // widget's own onChanged path mutates state before emit().
        // ignore: invalid_use_of_protected_member
        ..setState(() => body.actualTrainingDays = 8)
        ..emit();
      await tester.pumpAndSettle();

      expect(_read(formKey)!.trainingDays, 8);
    });

    testWidgets(
      'duration text changes update both body state and form value',
      (tester) async {
        final initial = CampScheduleData(
          startDate: DateTime(2026),
          trainingDays: 5,
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          durationMinutes: 90,
        );
        final formKey = await _pumpField(tester, initialValue: initial);
        final body = _body(tester)..onDurationTextChanged('2h');
        await tester.pumpAndSettle();
        expect(body.durationMinutes, 120);
        expect(_read(formKey)!.durationMinutes, 120);
      },
    );

    testWidgets('unparseable duration text leaves state unchanged', (
      tester,
    ) async {
      final initial = CampScheduleData(
        startDate: DateTime(2026),
        trainingDays: 5,
        sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        durationMinutes: 90,
      );
      await _pumpField(tester, initialValue: initial);
      final body = _body(tester)..onDurationTextChanged('xx');
      await tester.pumpAndSettle();
      expect(body.durationMinutes, 90);
    });

    testWidgets(
      'Issue 702: splitting the daily session spills into a new segment and '
      'emits named sessions',
      (tester) async {
        final initial = CampScheduleData(
          startDate: DateTime(2026),
          trainingDays: 5,
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          durationMinutes: 120,
        );
        final formKey = await _pumpField(tester, initialValue: initial);

        final body = _body(tester)
          ..onSessionDurationChanged(0, const Duration(minutes: 30));
        await tester.pumpAndSettle();
        expect(body.sessionDurations, [30, 90]);

        final value = _read(formKey)!;
        expect(value.sessions.length, 2);
        expect(value.sessions[0].startTime, '09:00');
        expect(value.sessions[0].endTime, '09:30');
        expect(value.sessions[1].startTime, '09:30');
        expect(value.sessions[1].endTime, '11:00');
      },
    );

    testWidgets(
      'Issue 702: removeSession refunds the freed minutes to the last row',
      (tester) async {
        final initial = CampScheduleData(
          startDate: DateTime(2026),
          trainingDays: 5,
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          durationMinutes: 120,
        );
        await _pumpField(tester, initialValue: initial);

        final body = _body(tester)
          ..onSessionDurationChanged(0, const Duration(minutes: 30));
        await tester.pumpAndSettle();
        expect(body.sessionDurations, [30, 90]);

        body.removeSession(0);
        await tester.pumpAndSettle();
        expect(body.sessionDurations, [120]);
      },
    );

    testWidgets(
      'Issue 702: a single undivided session emits an empty sessions list',
      (tester) async {
        final initial = CampScheduleData(
          startDate: DateTime(2026),
          trainingDays: 5,
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          durationMinutes: 120,
        );
        final formKey = await _pumpField(tester, initialValue: initial);
        expect(_body(tester).sessionDurations, [120]);
        expect(_read(formKey)!.sessions, isEmpty);
      },
    );

    testWidgets(
      'Issue 702: initial sessions seed the split editor',
      (tester) async {
        final initial = CampScheduleData(
          startDate: DateTime(2026),
          trainingDays: 5,
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          durationMinutes: 120,
          sessions: const [
            SessionInput(name: 'Off-Ice', startTime: '09:00', endTime: '09:30'),
            SessionInput(name: 'On-Ice', startTime: '09:30', endTime: '11:00'),
          ],
        );
        await _pumpField(tester, initialValue: initial);
        expect(_body(tester).sessionDurations, [30, 90]);
      },
    );

    testWidgets(
      'aggregate validator surfaces the first failure via saveAndValidate',
      (tester) async {
        final formKey = await _pumpField(
          tester,
          initialValue: const CampScheduleData(),
          useAggregateValidator: true,
        );
        final ok = formKey.currentState!.saveAndValidate();
        expect(ok, isFalse);
        await tester.pumpAndSettle();
        expect(find.text('Start date is required'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('enabled=false propagates to all ShadInputFormFields', (
      tester,
    ) async {
      await _pumpField(
        tester,
        initialValue: CampScheduleData(
          startDate: DateTime(2026),
          trainingDays: 5,
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          durationMinutes: 90,
        ),
        enabled: false,
      );
      final inputs = tester.widgetList<ShadInputFormField>(
        find.byType(ShadInputFormField),
      );
      expect(inputs, isNotEmpty);
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

    testWidgets('durationDays = trainingDays + excludedDates count', (
      tester,
    ) async {
      await _pumpField(
        tester,
        initialValue: CampScheduleData(
          startDate: DateTime(2026),
          trainingDays: 5,
          sessionStartTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          durationMinutes: 90,
          excludedDates: {DateTime(2026, 1, 3), DateTime(2026, 1, 4)},
        ),
      );
      final body = _body(tester);
      expect(body.durationDays, 7);
    });

    testWidgets('formatDuration renders minutes-only and decimal hours', (
      tester,
    ) async {
      await _pumpField(tester);
      final body = _body(tester);
      expect(body.formatDuration(15), '15m');
      expect(body.formatDuration(60), '1h');
      expect(body.formatDuration(90), '1h 30m');
      expect(body.formatDuration(75), '1h 15m');
    });

    testWidgets('parseDuration accepts canonical and shorthand forms', (
      tester,
    ) async {
      await _pumpField(tester);
      final body = _body(tester);
      expect(body.parseDuration('2h'), 120);
      expect(body.parseDuration('1.5h'), 90);
      expect(body.parseDuration('1h 30m'), 90);
      expect(body.parseDuration('45m'), 45);
      expect(body.parseDuration(''), isNull);
      expect(body.parseDuration('xx'), isNull);
    });
  });
}
