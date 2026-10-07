import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'form_harness.dart';

// What the test files of EventCreateForm share.

const String titleId = EventCreateFormFields.titleId;
const String visibilityId = EventCreateFormFields.visibilityId;
const String venueId = EventCreateFormFields.venueId;
const String scheduleId = EventCreateFormFields.scheduleId;

const createFormVenues = [
  EventVenueOption(id: 1, name: 'Main Rink'),
  EventVenueOption(id: 2, name: 'Practice Rink'),
];

final createFormNow = DateTime(2030, 6, 10, 10, 30);

const nineOClock = ShadTimeOfDay(hour: 9, minute: 0, second: 0);

/// A complete schedule of [type], so only what a test leaves out is wrong.
Object completeSchedule(EventFormType type) => switch (type) {
  EventFormType.camp => CampScheduleData(
    startDate: DateTime(2030, 7),
    trainingDays: 4,
    sessionStartTime: nineOClock,
    durationMinutes: 90,
  ),
  EventFormType.oneOff => OneOffScheduleData(
    date: DateTime(2030, 7),
    startTime: nineOClock,
    durationMinutes: 45,
  ),
  EventFormType.programme => ProgrammeScheduleData(
    weekdays: const {1, 3},
    startDate: DateTime(2030, 7),
    sessionStartTime: nineOClock,
    totalDurationMinutes: 90,
  ),
};

/// Initial values of a form that is ready to create.
Map<String, dynamic> completeCreateValues(EventFormType type) => {
  titleId: 'Open day',
  visibilityId: EventFormVisibility.private,
  venueId: 2,
  scheduleId: completeSchedule(type),
};

Future<EventCreateFormState> pumpCreateForm(
  WidgetTester tester,
  EventFormType type, {
  Map<String, dynamic>? initial,
  bool enabled = true,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<EventCreateFormState>();
  await pumpForm(
    tester,
    EventCreateForm(
      key: key,
      eventType: type,
      venues: createFormVenues,
      initialValues:
          initial ?? EventCreateForm.defaultValues(type, now: createFormNow),
      enabled: enabled,
    ),
    size: size,
  );
  return key.currentState!;
}

/// Opens the select showing [current] and picks [option].
Future<void> pickOption(
  WidgetTester tester,
  String current,
  String option,
) async {
  await tester.tap(find.text(current));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

/// The camp's Training Days input: the one that shows [days].
Finder trainingDaysInput(String days) => find.byWidgetPredicate(
  (widget) => widget is EditableText && widget.controller.text == days,
  description: 'the input showing "$days"',
);
