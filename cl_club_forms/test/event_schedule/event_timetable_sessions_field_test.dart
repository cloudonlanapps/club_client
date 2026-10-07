// EventTimetableSessionsField is one custom field: it has no label of its
// own (the form's row labels it), no rule across fields and no host chrome.
// Its only validator is the one the form passes in.
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_column.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/event_timetable_form_validators.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/event_timetable_sessions_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/form_harness.dart';
import '../support/programme_timetable_support.dart';

const String _id = 'sessions';

const List<SessionInput> _halves = [
  SessionInput(name: 'First', startTime: '06:00', endTime: '06:45'),
  SessionInput(name: 'Second', startTime: '06:45', endTime: '07:30'),
];

Widget _field({
  List<SessionInput> initialValue = kWarmUpAndDrills,
  int totalMinutes = 120,
  Object scheduleKey = 0,
  bool enabled = true,
}) => EventTimetableSessionsField(
  id: _id,
  scheduleKey: scheduleKey,
  totalMinutes: totalMinutes,
  startTime: kSixAm,
  initialValue: initialValue,
  enabled: enabled,
  validator: (sessions) =>
      EventTimetableFormValidators.sessionsTotal(sessions, totalMinutes),
);

List<SessionInput>? _value(GlobalKey<ShadFormState> form) =>
    form.currentState!.value[_id] as List<SessionInput>?;

List<String> _names(WidgetTester tester) => [
  for (final input in tester.widgetList<ShadInput>(find.byType(ShadInput)))
    input.controller!.text,
];

void main() {
  testWidgets('Issue 61: the field holds the seeded split and shows a row '
      'for each session', (tester) async {
    final form = await pumpFieldInForm(tester, _field());

    expect(_value(form), kWarmUpAndDrills);
    expect(_names(tester), ['Warm-up', 'Drills']);
    expect(shownDurations(tester), ['0:30', '1:30']);
    expect(form.currentState!.saveAndValidate(), isTrue);
  });

  testWidgets('Issue 61: an edit in the split editor becomes the field value', (
    tester,
  ) async {
    final form = await pumpFieldInForm(tester, _field());

    // Drills: 1:30 -> 0:30, the freed hour becomes a third session.
    await pickHour(tester, 1, 0);

    expect(_value(form), const [
      SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '06:30'),
      SessionInput(name: 'Drills', startTime: '06:30', endTime: '07:00'),
      SessionInput(name: 'Session 3', startTime: '07:00', endTime: '08:00'),
    ]);

    await tester.enterText(find.byType(EditableText).last, 'Game');
    await tester.pumpAndSettle();
    expect(_value(form)!.last.name, 'Game');
  });

  testWidgets('Issue 61: removing down to one row leaves an empty split', (
    tester,
  ) async {
    final form = await pumpFieldInForm(tester, _field());

    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    expect(_value(form), isEmpty);
    expect(form.currentState!.saveAndValidate(), isTrue);
  });

  testWidgets('Issue 61: the validator message shows under the editor', (
    tester,
  ) async {
    final form = await pumpFieldInForm(tester, _field(totalMinutes: 150));

    expect(form.currentState!.saveAndValidate(), isFalse);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: fieldWithId(_id),
        matching: find.text(EventTimetableFormValidators.totalMismatchMessage),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Issue 61: a new schedule key rebuilds the editor from the '
      "field's value, an unchanged key keeps it", (tester) async {
    final form = await pumpFieldInForm(tester, _field());

    form.currentState!.setFieldValue<List<SessionInput>>(_id, _halves);
    await pumpForm(
      tester,
      ShadForm(key: form, child: _field(totalMinutes: 120)),
    );
    expect(
      _names(tester),
      ['Warm-up', 'Drills'],
      reason: 'same schedule: the editor keeps its rows',
    );

    await pumpForm(
      tester,
      ShadForm(
        key: form,
        child: _field(scheduleKey: 1, totalMinutes: 90),
      ),
    );
    expect(_names(tester), ['First', 'Second']);
    expect(shownDurations(tester), ['0:45', '0:45']);
    expect(_value(form), _halves);
  });

  testWidgets('Issue 61: disabled, the editor does not respond', (
    tester,
  ) async {
    final form = await pumpFieldInForm(tester, _field(enabled: false));

    await tester.tap(find.text('1:30'));
    await tester.pumpAndSettle();
    expect(find.byType(DurationPickerColumn), findsNothing);
    await tester.tap(find.byType(IconButton).first, warnIfMissed: false);
    await tester.pumpAndSettle();
    for (final input in tester.widgetList<ShadInput>(find.byType(ShadInput))) {
      expect(input.enabled, isFalse);
    }

    expect(_value(form), kWarmUpAndDrills);
  });

  testWidgets('Issue 61: the field fits a phone', (tester) async {
    await pumpFieldInForm(tester, _field(), size: kPhoneSurface);
    expect(tester.takeException(), isNull);
    expect(_names(tester), ['Warm-up', 'Drills']);
  });
}
