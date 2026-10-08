import 'package:cl_club_forms/src/models/camp_schedule_data.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_fields.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_form.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

CampScheduleData _seed() => CampScheduleData(
  startDate: DateTime(2026, 8, 1),
  trainingDays: 5,
  sessionStartTime: const ShadTimeOfDay(hour: 6, minute: 0, second: 0),
  durationMinutes: 120,
);

Future<GlobalKey<CampScheduleFormState>> _pump(
  WidgetTester tester,
  CampScheduleData initial,
) async {
  tester.view.physicalSize = const Size(1400, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final key = GlobalKey<CampScheduleFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CampScheduleForm(key: key, initialValue: initial),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

CampScheduleFormFieldBodyState _body(WidgetTester tester) =>
    tester.state<CampScheduleFormFieldBodyState>(
      find.byType(CampScheduleFormFieldBody),
    );

void main() {
  testWidgets('Issue 705: seeded form validates and starts clean', (
    tester,
  ) async {
    final initial = _seed();
    final key = await _pump(tester, initial);

    final value = key.currentState!.validate();
    expect(value, {CampScheduleFormFields.scheduleId: initial});
    expect(key.currentState!.isDirty, isFalse);
  });

  testWidgets('Issue 705: an edit is caught as dirty', (tester) async {
    final key = await _pump(tester, _seed());
    expect(key.currentState!.isDirty, isFalse);

    // Change the daily duration through the field's own handler.
    _body(tester).onDurationChanged(180);
    await tester.pumpAndSettle();

    expect(key.currentState!.isDirty, isTrue);
    final value = key.currentState!.validate();
    expect(value, isNotNull);
    final schedule =
        value![CampScheduleFormFields.scheduleId] as CampScheduleData;
    expect(schedule.durationMinutes, 180);
  });

  testWidgets('Issue 54: a split the server refused shows on the schedule', (
    tester,
  ) async {
    final key = await _pump(tester, _seed());

    key.currentState!.showErrors(
      fieldErrors: const {
        CampScheduleFormFields.scheduleId: 'The sessions must add up.',
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('The sessions must add up.'), findsOneWidget);
  });

  testWidgets('Issue 54: the rest days are a labelled row of the form', (
    tester,
  ) async {
    await _pump(tester, _seed());

    expect(find.text('Rest Days (tap to toggle)'), findsOneWidget);
  });
}
