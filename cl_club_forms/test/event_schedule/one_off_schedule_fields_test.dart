import 'package:cl_club_forms/src/models/one_off_schedule_data.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_dropdown.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/one_off_schedule_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<GlobalKey<ShadFormState>> _pumpField(
  WidgetTester tester, {
  OneOffScheduleData? initialValue,
  bool enabled = true,
  bool useAggregateValidator = false,
}) async {
  tester.view.physicalSize = const Size(1200, 1600);
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
            child: OneOffScheduleFormField(
              id: 'schedule',
              initialValue: initialValue,
              enabled: enabled,
              validator: useAggregateValidator
                  ? OneOffScheduleFormField.aggregateValidator
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

OneOffScheduleData? _read(GlobalKey<ShadFormState> formKey) =>
    formKey.currentState!.value['schedule'] as OneOffScheduleData?;

void main() {
  group('OneOffScheduleFormField.aggregateValidator', () {
    test('rejects null', () {
      expect(
        OneOffScheduleFormField.aggregateValidator(null),
        'Schedule is required',
      );
    });

    test('rejects missing date', () {
      expect(
        OneOffScheduleFormField.aggregateValidator(const OneOffScheduleData()),
        'Date is required',
      );
    });

    test('rejects missing start time', () {
      final value = OneOffScheduleData(date: DateTime(2026));
      expect(
        OneOffScheduleFormField.aggregateValidator(value),
        'Start time is required',
      );
    });

    test('rejects non-positive duration', () {
      final value = OneOffScheduleData(
        date: DateTime(2026),
        startTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        durationMinutes: 0,
      );
      expect(
        OneOffScheduleFormField.aggregateValidator(value),
        'Duration must be greater than 0',
      );
    });

    test('accepts a fully populated value', () {
      final value = OneOffScheduleData(
        date: DateTime(2026),
        startTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        durationMinutes: 120,
      );
      expect(
        OneOffScheduleFormField.aggregateValidator(value),
        isNull,
      );
    });
  });

  group('OneOffScheduleFormField widget', () {
    testWidgets(
      'with no initial value the form value is null until first edit',
      (tester) async {
        final formKey = await _pumpField(tester);
        expect(_read(formKey), isNull);

        // Renders the three labelled rows.
        expect(find.text('Date *'), findsOneWidget);
        expect(find.text('Start Time *'), findsOneWidget);
        expect(find.text('Duration *'), findsOneWidget);
      },
    );

    testWidgets(
      'initial value renders the duration as the formatted string',
      (tester) async {
        final initial = OneOffScheduleData(
          date: DateTime(2026),
          startTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          durationMinutes: 90,
        );
        await _pumpField(tester, initialValue: initial);

        // 90m → "1:30" in the duration picker.
        expect(find.text('1:30'), findsOneWidget);
      },
    );

    testWidgets(
      'editing the duration text updates the form value',
      (tester) async {
        final initial = OneOffScheduleData(
          date: DateTime(2026),
          startTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          durationMinutes: 60,
        );
        final formKey = await _pumpField(tester, initialValue: initial);

        // Drive the duration through the cluster's own handler, as the
        // duration picker does.
        tester
            .state<OneOffScheduleFormFieldBodyState>(
              find.byType(OneOffScheduleFormFieldBody),
            )
            .onDurationChanged(120);
        await tester.pumpAndSettle();

        final value = _read(formKey)!;
        expect(value.durationMinutes, 120);
        expect(value.date, DateTime(2026));
        expect(
          value.startTime,
          const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
        );
      },
    );

    testWidgets(
      'aggregate validator surfaces "Date is required" via saveAndValidate',
      (tester) async {
        final formKey = await _pumpField(
          tester,
          initialValue: const OneOffScheduleData(),
          useAggregateValidator: true,
        );

        // No interaction yet — saveAndValidate should fail with the
        // first aggregate error.
        final ok = formKey.currentState!.saveAndValidate();
        expect(ok, isFalse);
        await tester.pumpAndSettle();
        // Surfaced both inline (date validator) and as the aggregate
        // form-field error — assert at least one rendering exists.
        expect(find.text('Date is required'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'enabled=false disables the duration input',
      (tester) async {
        final initial = OneOffScheduleData(
          date: DateTime(2026),
          startTime: const ShadTimeOfDay(hour: 9, minute: 0, second: 0),
          durationMinutes: 60,
        );
        await _pumpField(tester, initialValue: initial, enabled: false);

        final input = tester.widget<DurationPickerDropdown>(
          find.byType(DurationPickerDropdown),
        );
        expect(input.enabled, isFalse);
      },
    );

    testWidgets(
      'pre-seeded ShadTimePickerController has minute/second defaults',
      (tester) async {
        // Verifies CLAUDE.md form rule 11: when the user has not yet picked
        // a time, the picker's minute/second slots are pre-seeded so a
        // subsequent hour entry can fire onChanged. We assert this on the
        // live state rather than driving the picker UI.
        await _pumpField(tester);

        final body = tester.state<OneOffScheduleFormFieldBodyState>(
          find.byType(OneOffScheduleFormFieldBody),
        );
        expect(body.startTimeController.minute, 0);
        expect(body.startTimeController.second, 0);
        // No hour seeded when the user hasn't picked yet.
        expect(body.startTimeController.hour, isNull);
      },
    );
  });
}
