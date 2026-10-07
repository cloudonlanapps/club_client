import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:cl_club_forms/src/models/programme_schedule_data.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/programme_schedule_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'form_harness.dart';
import 'programme_timetable_support.dart';

/// The cluster's id in the test form.
const String programmeFieldId = 'schedule';

/// Nine in the morning.
const ShadTimeOfDay kNineAm = ShadTimeOfDay(hour: 9, minute: 0, second: 0);

/// A complete schedule: Mondays from 6 May 2030, two hours from nine.
final ProgrammeScheduleData validProgramme = ProgrammeScheduleData(
  weekdays: const {DateTime.monday},
  startDate: DateTime(2030, 5, 6),
  sessionStartTime: kNineAm,
  totalDurationMinutes: 120,
);

/// Mounts the cluster in a form, with its aggregate validator.
Future<GlobalKey<ShadFormState>> pumpProgrammeField(
  WidgetTester tester, {
  ProgrammeScheduleData? initialValue,
  bool showDateRange = true,
  bool enabled = true,
  Size size = kFormSurface,
}) => pumpFieldInForm(
  tester,
  ProgrammeScheduleFormField(
    id: programmeFieldId,
    initialValue: initialValue,
    showDateRange: showDateRange,
    enabled: enabled,
    validator: ProgrammeScheduleFormField.aggregateValidator,
  ),
  size: size,
);

/// The cluster's value in [form].
ProgrammeScheduleData programmeValue(GlobalKey<ShadFormState> form) =>
    form.currentState!.value[programmeFieldId] as ProgrammeScheduleData;

/// Picks [day] in the date field at [index] (0 start, 1 end), as its
/// calendar does.
Future<void> pickProgrammeDate(
  WidgetTester tester,
  int index,
  DateTime? day,
) async {
  tester
      .state<FormFieldState<DateTime?>>(
        find.byType(CLDatePickerFormField).at(index),
      )
      .didChange(day);
  await tester.pumpAndSettle();
}

/// Saves and validates [form], and lets the messages show.
Future<bool> validateProgramme(
  WidgetTester tester,
  GlobalKey<ShadFormState> form,
) async {
  final valid = form.currentState!.saveAndValidate();
  await tester.pumpAndSettle();
  return valid;
}
