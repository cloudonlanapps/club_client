import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_column.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_dropdown.dart';
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

/// The duration pickers on screen show these lengths, top to bottom.
List<String> shownDurations(WidgetTester tester) => [
  for (final picker in tester.stateList<DurationPickerDropdownState>(
    find.byType(DurationPickerDropdown),
  ))
    picker.formatDuration(picker.clampDuration(picker.widget.value)),
];

/// Opens the duration picker at [row] and taps [hour] in its Hours column,
/// as a user does. Picking an hour above zero closes the picker.
Future<void> pickHour(WidgetTester tester, int row, int hour) async {
  await tester.tap(find.byType(DurationPickerDropdown).at(row));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(DurationPickerColumn).first,
      matching: find.text('$hour'),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the duration picker at [row] and taps [minute] in its Minutes
/// column, which closes the picker.
Future<void> pickMinute(WidgetTester tester, int row, int minute) async {
  await tester.tap(find.byType(DurationPickerDropdown).at(row));
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

/// The Duration input of a schedule cluster: the one text input that is a
/// form field (session names are plain inputs).
Finder durationInput() => find.descendant(
  of: find.byType(ShadInputFormField),
  matching: find.byType(EditableText),
);

/// Types [text] into the Duration input.
Future<void> enterDuration(WidgetTester tester, String text) async {
  await tester.enterText(durationInput(), text);
  await tester.pumpAndSettle();
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
