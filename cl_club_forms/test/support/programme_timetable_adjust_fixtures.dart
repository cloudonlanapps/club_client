import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'form_harness.dart';

/// The upcoming session starts offered as From.
final List<DateTime> adjustFromOptions = [
  DateTime.utc(2030, 5, 13, 6),
  DateTime.utc(2030, 5, 16, 6),
  DateTime.utc(2030, 5, 20, 6),
];

/// Noon, when the fixture's sessions start.
const ShadTimeOfDay adjustNoon = ShadTimeOfDay(hour: 12, minute: 0, second: 0);

final ProgrammeScheduleData adjustSchedule = ProgrammeScheduleData(
  weekdays: const {DateTime.monday, DateTime.thursday},
  startDate: DateTime(2030, 5),
  sessionStartTime: adjustNoon,
);

/// The form's seed: the present terms from the first session, at venue 7.
final ProgrammeScheduleAdjustValue adjustInitial = ProgrammeScheduleAdjustValue(
  from: adjustFromOptions.first,
  schedule: adjustSchedule,
  venueId: 7,
);

/// The venues offered.
const List<EventVenueOption> adjustVenues = [
  EventVenueOption(id: 7, name: 'North Rink'),
  EventVenueOption(id: 9, name: 'Hall'),
];

/// How the picker writes the From session [from].
String shownFrom(DateTime from) =>
    ProgrammeScheduleAdjustForm.fromFormat.format(from.toLocal());

/// Mounts the form through the shared harness and returns its state.
Future<ProgrammeScheduleAdjustFormState> mountAdjustForm(
  WidgetTester tester, {
  ProgrammeScheduleAdjustValue? initialValue,
  bool enabled = true,
}) async {
  final key = GlobalKey<ProgrammeScheduleAdjustFormState>();
  await pumpForm(
    tester,
    ProgrammeScheduleAdjustForm(
      key: key,
      initialValue: initialValue ?? adjustInitial,
      fromOptions: adjustFromOptions,
      venues: adjustVenues,
      enabled: enabled,
    ),
  );
  return key.currentState!;
}
