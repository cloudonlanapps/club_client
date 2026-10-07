import 'package:cl_club_events/src/models/programme_schedule_form_helpers.dart';
import 'package:cl_club_events/src/utils/programme_end_date.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_schedule_section.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_adjust_schedule_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_schedule_actions.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_schedule_read.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ProgrammeScheduleAdjustForm,
        ProgrammeScheduleAdjustFormFields,
        ProgrammeScheduleAdjustFormState,
        ProgrammeScheduleData;
import 'package:cl_club_forms/src/widgets/event_schedule/event_venue_select_field.dart'
    show EventVenueSelectField;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventSchedulesProvider, clEventsMasterProvider, clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/programme_fixtures.dart';
import '../../support/recording_schedule_events.dart';

Venue _venue(int id, String name) => Venue(
  id: id,
  name: name,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

Future<RecordingScheduleEvents> _pump(
  WidgetTester tester,
  Event event, {
  bool canEdit = true,
  List<EventSchedule> schedules = const [],
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final events = RecordingScheduleEvents(event);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        clEventSchedulesProvider.overrideWith((ref, id) async => schedules),
        clVenuesProvider.overrideWith(
          (ref, key) async => [_venue(7, 'North Rink'), _venue(9, 'Hall')],
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventScheduleSection(event: event, canEdit: canEdit),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

Future<void> _openAdjust(WidgetTester tester) async {
  await tester.tap(find.text(ProgrammeScheduleActions.adjustScheduleLabel));
  await tester.pumpAndSettle();
}

ProgrammeScheduleAdjustFormState _form(WidgetTester tester) =>
    tester.state<ProgrammeScheduleAdjustFormState>(
      find.byType(ProgrammeScheduleAdjustForm),
    );

/// Changes the open dialog's days to Tuesday and Saturday.
Future<void> _pickTuesdayAndSaturday(WidgetTester tester) async {
  final form = _form(tester);
  form.formKey.currentState!.setFieldValue<ProgrammeScheduleData>(
    ProgrammeScheduleAdjustFormFields.scheduleId,
    form.widget.initialValue.schedule.copyWith(
      weekdays: {DateTime.tuesday, DateTime.saturday},
    ),
  );
  await tester.pump();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Issue 38: Adjust Schedule opens the schedule editor seeded with the '
    'present schedule, from the next session, and says what saving does',
    (tester) async {
      final event = programmeFixture(rrule: 'FREQ=WEEKLY;BYDAY=MO,TH');
      await _pump(tester, event);

      await _openAdjust(tester);

      final form = _form(tester);
      final options = programmeAdjustFromOptions(event);
      expect(form.widget.fromOptions, options);
      expect(form.currentValue.from, options.first);
      expect(form.currentValue.schedule.weekdays, {
        DateTime.monday,
        DateTime.thursday,
      });
      expect(form.currentValue.venueId, 7);
      expect(
        find.text(ProgrammeScheduleAdjustForm.effectLine(options.first)),
        findsOneWidget,
      );
      expect(find.text('Start Date *'), findsNothing);
      expect(find.text('End Date'), findsNothing);
    },
  );

  testWidgets('Issue 38: saving with nothing changed sends nothing', (
    tester,
  ) async {
    final events = await _pump(tester, programmeFixture());

    await _openAdjust(tester);
    await _save(tester);

    expect(events.futureUpdates, isEmpty);
    expect(find.byType(ProgrammeAdjustScheduleDialog), findsNothing);
  });

  testWidgets(
    'Issue 38: new days are saved from the chosen session onward in one '
    'call',
    (tester) async {
      final event = programmeFixture();
      final events = await _pump(tester, event);
      final options = programmeAdjustFromOptions(event);

      await _openAdjust(tester);
      _form(tester).formKey.currentState!.setFieldValue<DateTime>(
        ProgrammeScheduleAdjustFormFields.fromId,
        options[2],
      );
      await _pickTuesdayAndSaturday(tester);
      expect(
        find.text(ProgrammeScheduleAdjustForm.effectLine(options[2])),
        findsOneWidget,
      );
      await _save(tester);

      final call = events.futureUpdates.single;
      expect(call.effectiveDateTimeUtc, options[2]);
      expect(call.version, 4);
      expect(call.rrule, 'FREQ=WEEKLY;BYDAY=TU,SA');
      expect(find.text(programmeScheduleAdjustedMessage), findsOneWidget);
      expect(find.byType(ProgrammeAdjustScheduleDialog), findsNothing);
    },
  );

  testWidgets(
    'Issue 38: a From that is not an upcoming session start is refused',
    (tester) async {
      final event = programmeFixture();
      final events = await _pump(tester, event);

      await _openAdjust(tester);
      _form(tester).formKey.currentState!.setFieldValue<DateTime>(
        ProgrammeScheduleAdjustFormFields.fromId,
        programmeAdjustFromOptions(
          event,
        ).first.add(const Duration(minutes: 45)),
      );
      await _pickTuesdayAndSaturday(tester);
      await _save(tester);

      expect(events.futureUpdates, isEmpty);
      expect(find.byType(ProgrammeAdjustScheduleDialog), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 38: a clash with another programme stops the save with a '
    'readable message naming it',
    (tester) async {
      final events = await _pump(tester, programmeFixture());
      events.error = const ServerException(
        statusCode: 409,
        code: SdkErrorCode.timeConflict,
        message: 'raw server text',
        details: {
          'hasConflict': true,
          'venueConflicts': [
            {'eventId': 5, 'eventTitle': 'Evening Skills'},
          ],
        },
      );

      await _openAdjust(tester);
      await _pickTuesdayAndSaturday(tester);
      await _save(tester);

      expect(
        find.textContaining('clashes with another programme (Evening Skills)'),
        findsOneWidget,
      );
      expect(find.textContaining('raw server text'), findsNothing);
      expect(
        find.byType(ProgrammeAdjustScheduleDialog),
        findsOneWidget,
        reason: 'the dialog stays open to change the terms',
      );
    },
  );

  testWidgets(
    'Issue 38: a stale version closes the dialog on the reloaded programme '
    'and asks the user to check it',
    (tester) async {
      final events = await _pump(tester, programmeFixture());
      events.error = StaleVersionException(
        message: 'stale',
        version: 5,
        updatedBy: 'coach_a',
        updatedAtUtc: DateTime.utc(2026, 9, 1, 10),
      );

      await _openAdjust(tester);
      await _pickTuesdayAndSaturday(tester);
      await _save(tester);

      expect(find.textContaining('changed by coach_a'), findsOneWidget);
      expect(find.textContaining('check it and try again'), findsOneWidget);
      expect(find.byType(ProgrammeAdjustScheduleDialog), findsNothing);
    },
  );

  testWidgets(
    'Issue 38: while a change is pending the block shows the present terms '
    'and the day the next ones start',
    (tester) async {
      final pendingFrom = localNoon(6).toUtc();
      // The event describes its latest schedule: the pending one.
      final event = programmeFixture(
        rrule: 'FREQ=WEEKLY;BYDAY=SA',
      ).copyWith(startTimeUtc: pendingFrom);
      await _pump(
        tester,
        event,
        schedules: [
          scheduleFixture(
            21,
            localNoon(-20).toUtc(),
            until: pendingFrom,
            rrule: 'FREQ=WEEKLY;BYDAY=MO',
          ),
          scheduleFixture(22, pendingFrom, rrule: 'FREQ=WEEKLY;BYDAY=SA'),
        ],
      );

      expect(find.text(programmeNextScheduleLine(pendingFrom)), findsOneWidget);
      expect(find.textContaining('Monday'), findsOneWidget);
      expect(find.textContaining('Saturday'), findsNothing);
    },
  );

  testWidgets('Issue 38: with no change pending there is no next-terms line', (
    tester,
  ) async {
    await _pump(tester, programmeFixture());

    expect(find.textContaining('New schedule from'), findsNothing);
  });

  testWidgets('Issue 38: a viewer who may not edit is not offered Adjust '
      'Schedule', (tester) async {
    await _pump(tester, programmeFixture(), canEdit: false);

    expect(
      find.text(ProgrammeScheduleActions.adjustScheduleLabel),
      findsNothing,
    );
  });

  testWidgets('Issue 38: a camp is not offered Adjust Schedule', (
    tester,
  ) async {
    final start = localNoon(3).toUtc();
    await _pump(
      tester,
      programmeFixture().copyWith(
        type: EventType.camp,
        startTimeUtc: start,
        endTimeUtc: start.add(const Duration(hours: 1)),
        rrule: () => 'FREQ=DAILY;COUNT=3',
      ),
    );

    expect(
      find.text(ProgrammeScheduleActions.adjustScheduleLabel),
      findsNothing,
    );
  });

  testWidgets(
    'Issue 38: a programme with an end date is warned that adjusting the '
    'schedule clears it',
    (tester) async {
      final event = programmeFixture(untilTimeUtc: localNoon(40).toUtc());
      await _pump(tester, event);

      await _openAdjust(tester);

      final warning = programmeEndClearedWarning(event);
      expect(warning, isNotNull);
      expect(
        warning,
        contains(programmeEndDayFormat.format(programmeEndDay(event)!)),
      );
      expect(find.text(warning!), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 38: a programme with no end date gets no end-date warning',
    (tester) async {
      final event = programmeFixture();
      await _pump(tester, event);

      await _openAdjust(tester);

      expect(programmeEndClearedWarning(event), isNull);
      expect(find.textContaining('clears that end date'), findsNothing);
    },
  );

  testWidgets('Issue 54: a refusal about a field shows on that field of the '
      'Adjust Schedule form, and Save can be tried again', (tester) async {
    final events = await _pump(tester, programmeFixture());
    events.error = const ServerException(
      statusCode: 404,
      code: SdkErrorCode.venueNotFound,
      message: 'raw server text',
    );

    await _openAdjust(tester);
    await _pickTuesdayAndSaturday(tester);
    await _save(tester);

    expect(
      find.descendant(
        of: find.byType(EventVenueSelectField),
        matching: find.textContaining('That venue no longer exists'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('raw server text'), findsNothing);
    expect(find.byType(ProgrammeAdjustScheduleDialog), findsOneWidget);

    expect(events.futureUpdates, hasLength(1), reason: 'the refused attempt');

    events.error = null;
    await _save(tester);
    expect(events.futureUpdates, hasLength(2), reason: 'the second attempt');
    expect(find.byType(ProgrammeAdjustScheduleDialog), findsNothing);
  });

  test('Issue 54: programmeScheduleAdjustValueOf reads the form values', () {
    final schedule = buildProgrammeScheduleInitialValues(programmeFixture());
    final from = DateTime.utc(2030, 5, 14, 12);

    final value = programmeScheduleAdjustValueOf({
      ProgrammeScheduleAdjustFormFields.fromId: from,
      ProgrammeScheduleAdjustFormFields.scheduleId: schedule,
      ProgrammeScheduleAdjustFormFields.venueId: 9,
    });

    expect(value.from, from);
    expect(value.schedule, schedule);
    expect(value.venueId, 9);
  });
}
