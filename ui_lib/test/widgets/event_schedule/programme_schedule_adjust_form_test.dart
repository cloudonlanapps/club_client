import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/event_schedule/programme_schedule_adjust_form_validators.dart'
    show ProgrammeScheduleAdjustFormValidators;
import 'package:ui_lib/ui_lib.dart';

final _options = [
  DateTime.utc(2030, 5, 13, 6),
  DateTime.utc(2030, 5, 16, 6),
  DateTime.utc(2030, 5, 20, 6),
];

final _initial = ProgrammeScheduleAdjustValue(
  from: _options.first,
  schedule: ProgrammeScheduleData(
    weekdays: const {DateTime.monday, DateTime.thursday},
    startDate: DateTime(2030, 5),
    sessionStartTime: const ShadTimeOfDay(hour: 12, minute: 0, second: 0),
  ),
  venueId: 7,
);

Future<ProgrammeScheduleAdjustFormState> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProgrammeScheduleAdjustForm(
            initialValue: _initial,
            fromOptions: _options,
            venues: const [
              EventVenueOption(id: 7, name: 'North Rink'),
              EventVenueOption(id: 9, name: 'Hall'),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<ProgrammeScheduleAdjustFormState>(
    find.byType(ProgrammeScheduleAdjustForm),
  );
}

void main() {
  testWidgets('Issue 38: the form shows From, the weekday, time and session '
      'fields and the venue, without a date range', (tester) async {
    await _pump(tester);

    for (final label in [
      'From *',
      'Days of Week *',
      'Start Time *',
      'Duration *',
      'Venue *',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Start Date *'), findsNothing);
    expect(find.text('End Date'), findsNothing);
  });

  testWidgets('Issue 38: an unedited form is clean, and another From alone '
      'does not make it dirty', (tester) async {
    final state = await _pump(tester);

    expect(state.isDirty, isFalse);
    expect(state.validate(), _initial);

    state.formKey.currentState!.setFieldValue<DateTime>(
      ProgrammeScheduleAdjustForm.fromId,
      _options[1],
    );
    await tester.pump();
    expect(state.isDirty, isFalse);
    expect(state.validate()?.from, _options[1]);
    await tester.pump();
    expect(
      find.text(ProgrammeScheduleAdjustForm.effectLine(_options[1])),
      findsOneWidget,
    );
  });

  testWidgets('Issue 38: changed days make the form dirty', (tester) async {
    final state = await _pump(tester);

    state.formKey.currentState!.setFieldValue<ProgrammeScheduleData>(
      ProgrammeScheduleAdjustForm.scheduleId,
      _initial.schedule.copyWith(weekdays: {DateTime.tuesday}),
    );
    await tester.pump();

    expect(state.isDirty, isTrue);
    expect(state.validate()?.schedule.weekdays, {DateTime.tuesday});
  });

  testWidgets('Issue 38: a refusal shows inline', (tester) async {
    final state = await _pump(tester);

    state.showFormError('This schedule clashes with another programme.');
    await tester.pump();

    expect(
      find.text('This schedule clashes with another programme.'),
      findsOneWidget,
    );
  });

  test('Issue 38: From must be one of the offered session starts', () {
    const v = ProgrammeScheduleAdjustFormValidators.from;
    expect(v(_options[1], _options), isNull);
    expect(
      v(null, _options),
      ProgrammeScheduleAdjustFormValidators.fromRequiredMessage,
    );
    expect(
      v(_options[1].add(const Duration(minutes: 30)), _options),
      ProgrammeScheduleAdjustFormValidators.fromNotASessionMessage,
    );
  });
}
