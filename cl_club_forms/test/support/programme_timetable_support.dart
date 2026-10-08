import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_column.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_dropdown.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/schedule_duration_field.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/session_split_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'form_harness.dart';

/// Six in the morning, where the fixtures' occurrences start.
const ShadTimeOfDay kSixAm = ShadTimeOfDay(hour: 6, minute: 0, second: 0);

/// Two hours from six split into a half hour and the rest.
const List<SessionInput> kWarmUpAndDrills = [
  SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '06:30'),
  SessionInput(name: 'Drills', startTime: '06:30', endTime: '08:00'),
];

/// Mounts [field] in a `ShadForm` of its own and returns the form's key.
Future<GlobalKey<ShadFormState>> pumpFieldInForm(
  WidgetTester tester,
  Widget field, {
  Size size = kFormSurface,
}) async {
  final formKey = GlobalKey<ShadFormState>();
  await pumpForm(
    tester,
    ShadForm(key: formKey, child: field),
    size: size,
  );
  return formKey;
}

/// The length pickers of the session split on screen, one per session. The
/// Duration field of a schedule has a picker of its own ([durationPicker]),
/// which is not among them.
Finder sessionLengthPickers() => find.descendant(
  of: find.byType(SessionSplitField),
  matching: find.byType(DurationPickerDropdown),
);

/// What [picker] shows.
String _shown(DurationPickerDropdownState picker) =>
    picker.formatDuration(picker.clampDuration(picker.widget.value));

/// The sessions of the split on screen show these lengths, top to bottom.
List<String> shownDurations(WidgetTester tester) => [
  for (final picker in tester.stateList<DurationPickerDropdownState>(
    sessionLengthPickers(),
  ))
    _shown(picker),
];

/// Opens the length picker of the session at [row] and taps [hour] in its
/// Hours column, as a user does. Picking an hour above zero closes the
/// picker.
Future<void> pickHour(WidgetTester tester, int row, int hour) async {
  await tester.tap(sessionLengthPickers().at(row));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(DurationPickerColumn).first,
      matching: find.text('$hour'),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the length picker of the session at [row] and taps [minute] in its
/// Minutes column, which closes the picker.
Future<void> pickMinute(WidgetTester tester, int row, int minute) async {
  await tester.tap(sessionLengthPickers().at(row));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(DurationPickerColumn).last,
      matching: find.text(minute.toString().padLeft(2, '0')),
    ),
  );
  await tester.pumpAndSettle();
}

/// The hour and minute inputs of the time picker on screen.
Finder timePickerInputs() => find.descendant(
  of: find.byType(ShadTimePickerFormField),
  matching: find.byType(EditableText),
);

/// Types [hour] and [minute] into the time picker, as a user does.
Future<void> enterStartTime(
  WidgetTester tester,
  int hour, [
  int minute = 0,
]) async {
  await tester.enterText(timePickerInputs().at(0), '$hour');
  await tester.pumpAndSettle();
  await tester.enterText(timePickerInputs().at(1), '$minute');
  await tester.pumpAndSettle();
}

/// The picker of the Duration field of a schedule cluster.
Finder durationPicker() => find.descendant(
  of: find.byType(ScheduleDurationField),
  matching: find.byType(DurationPickerDropdown),
);

/// The length the Duration field shows, as `H:MM`.
String shownDuration(WidgetTester tester) =>
    _shown(tester.state<DurationPickerDropdownState>(durationPicker()));

/// The numbers the open duration picker offers in its Hours column (0) or
/// its Minutes column (1), top to bottom.
List<int> offeredInColumn(WidgetTester tester, int column) => tester
    .widget<DurationPickerColumn>(find.byType(DurationPickerColumn).at(column))
    .options;

/// Opens the Duration field's picker, or closes it when it is open.
Future<void> tapDurationPicker(WidgetTester tester) async {
  await tester.tap(durationPicker());
  await tester.pumpAndSettle();
}

/// Taps [hour] in the Hours column of the Duration field's picker, opening
/// it first when it is closed, as a user does.
Future<void> pickDurationHour(WidgetTester tester, int hour) async {
  if (find.byType(DurationPickerColumn).evaluate().isEmpty) {
    await tapDurationPicker(tester);
  }
  final hours = find.byType(DurationPickerColumn).first;
  final option = find.descendant(of: hours, matching: find.text('$hour'));
  // A long column scrolls: its last hours are not built until reached.
  await tester.scrollUntilVisible(
    option,
    40,
    scrollable: find.descendant(of: hours, matching: find.byType(Scrollable)),
  );
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

/// Taps [minute] in the Minutes column of the Duration field's picker,
/// opening it first when it is closed. The tap closes the picker.
Future<void> pickDurationMinute(WidgetTester tester, int minute) async {
  if (find.byType(DurationPickerColumn).evaluate().isEmpty) {
    await tapDurationPicker(tester);
  }
  await tester.tap(
    find.descendant(
      of: find.byType(DurationPickerColumn).last,
      matching: find.text(minute.toString().padLeft(2, '0')),
    ),
  );
  await tester.pumpAndSettle();
}

/// Picks [hours] and [minutes] in the Duration field, hour first, and
/// leaves its picker closed.
Future<void> pickDuration(
  WidgetTester tester,
  int hours, [
  int minutes = 0,
]) async {
  await pickDurationHour(tester, hours);
  final wanted = '$hours:${minutes.toString().padLeft(2, '0')}';
  final open = find.byType(DurationPickerColumn).evaluate().isNotEmpty;
  if (open || shownDuration(tester) != wanted) {
    await pickDurationMinute(tester, minutes);
  }
}

/// Opens the select showing [shown] and taps its option [option].
Future<void> pickOption(
  WidgetTester tester,
  String shown,
  String option,
) async {
  await tester.tap(find.text(shown));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

/// Every text input on screen refuses input.
void expectInputsDisabled(WidgetTester tester) {
  final inputs = tester.widgetList<ShadInput>(find.byType(ShadInput));
  expect(inputs, isNotEmpty);
  for (final input in inputs) {
    expect(input.enabled, isFalse);
  }
}
