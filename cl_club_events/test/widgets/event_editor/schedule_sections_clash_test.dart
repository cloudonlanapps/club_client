import 'package:cl_club_events/src/models/camp_schedule_form_helpers.dart';
import 'package:cl_club_events/src/models/one_off_schedule_form_helpers.dart'
    show OneOffScheduleFormSubmit;
import 'package:cl_club_events/src/models/schedule_clash_gate.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_schedule_section.dart';
import 'package:cl_club_events/src/widgets/event_editor/one_off_reschedule_section.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_adjust_schedule_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_schedule_actions.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        CampScheduleData,
        OneOffScheduleData,
        OneOffScheduleForm,
        OneOffScheduleFormFields,
        OneOffScheduleFormState,
        OneOffScheduleValue,
        ProgrammeScheduleAdjustForm,
        ProgrammeScheduleAdjustFormFields,
        ProgrammeScheduleAdjustFormState,
        ProgrammeScheduleData;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEventSchedulesProvider,
        clEventsMasterProvider,
        clSingleOccurrenceProvider,
        clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

import '../../support/programme_fixtures.dart';
import '../../support/recording_schedule_events.dart';
import '../../support/schedule_clash_fixtures.dart';

Venue _venue(int id, String name) => Venue(
  id: id,
  name: name,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

/// [hours] from now, on the local hour.
DateTime _hoursFromNow(int hours) {
  final t = DateTime.now().add(Duration(hours: hours));
  return DateTime(t.year, t.month, t.day, t.hour);
}

Event _oneOff(DateTime startLocal) => Event(
  id: 1,
  version: 4,
  title: 'test_clash_oneoff',
  description: '',
  type: EventType.oneOff,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: startLocal.toUtc(),
  endTimeUtc: startLocal.toUtc().add(const Duration(hours: 2)),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

/// Pumps the Schedule block of [event] for an editor.
Future<RecordingScheduleEvents> _pump(WidgetTester tester, Event event) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final events = RecordingScheduleEvents(event);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        clEventSchedulesProvider.overrideWith((ref, id) async => const []),
        clVenuesProvider.overrideWith(
          (ref, key) async => [_venue(7, 'North Rink'), _venue(9, 'Hall')],
        ),
        clSingleOccurrenceProvider.overrideWith(
          (ref, key) async => Occurrence(
            eventId: key.eventId,
            originalStartTimeUtc: key.occurrenceTimeUtc,
            actualStartTimeUtc: key.occurrenceTimeUtc,
            actualEndTimeUtc: key.occurrenceTimeUtc.add(
              const Duration(hours: 2),
            ),
            status: OccurrenceStatus.scheduled,
            venueId: 7,
          ),
        ),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: SingleChildScrollView(
              child: EventScheduleSection(event: event, canEdit: true),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

ProgrammeScheduleAdjustFormState _adjustForm(WidgetTester tester) =>
    tester.state<ProgrammeScheduleAdjustFormState>(
      find.byType(ProgrammeScheduleAdjustForm),
    );

/// The days the Adjust Schedule tests move the programme to.
const Set<int> _newDays = {DateTime.tuesday, DateTime.saturday};

/// Opens Adjust Schedule and moves the programme to [_newDays].
Future<void> _adjustDays(WidgetTester tester) async {
  await tester.tap(find.text(ProgrammeScheduleActions.adjustScheduleLabel));
  await tester.pumpAndSettle();
  final form = _adjustForm(tester);
  form.formKey.currentState!.setFieldValue<ProgrammeScheduleData>(
    ProgrammeScheduleAdjustFormFields.scheduleId,
    form.widget.initialValue.schedule.copyWith(weekdays: _newDays),
  );
  await tester.pump();
}

OneOffScheduleFormState _oneOffForm(WidgetTester tester) =>
    tester.state<OneOffScheduleFormState>(find.byType(OneOffScheduleForm));

/// Opens the one-off's editor and moves it to [startLocal].
Future<void> _moveOneOff(WidgetTester tester, DateTime startLocal) async {
  await tester.tap(find.byType(SectionEditButton));
  await tester.pumpAndSettle();
  _oneOffForm(tester).formKey.currentState!.setFieldValue<OneOffScheduleData>(
    OneOffScheduleFormFields.scheduleId,
    OneOffScheduleData(
      date: DateTime(startLocal.year, startLocal.month, startLocal.day),
      startTime: ShadTimeOfDay(
        hour: startLocal.hour,
        minute: startLocal.minute,
        second: 0,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('Issue 278: Adjust Schedule with a clash', () {
    testWidgets('Issue 278: Save anyway re-sends the split with '
        'acceptConflicts and closes', (tester) async {
      final events = await _pump(tester, programmeFixture());
      events.clash = venueClash();

      await _adjustDays(tester);
      await _save(tester);
      expect(clashDialog, findsOneWidget);
      expect(find.text(ScheduleClashGate.venue.label), findsOneWidget);

      await saveAnyway(tester);

      expect(events.futureUpdates.map((c) => c.acceptConflicts), [
        false,
        true,
      ]);
      // The same split both times.
      expect(
        events.futureUpdates.map((c) => c.rrule).toSet(),
        hasLength(1),
      );
      expect(find.byType(ProgrammeAdjustScheduleDialog), findsNothing);
      expect(find.text(programmeScheduleAdjustedMessage), findsOneWidget);
    });

    testWidgets('Issue 278: Cancel goes back to the dialog with the new '
        'days kept', (tester) async {
      final events = await _pump(tester, programmeFixture());
      events.clash = coachOnlyClash();

      await _adjustDays(tester);
      await _save(tester);
      await cancelClash(tester);

      expect(events.futureUpdates.map((c) => c.acceptConflicts), [false]);
      expect(find.byType(ProgrammeAdjustScheduleDialog), findsOneWidget);
      expect(_adjustForm(tester).currentValue.schedule.weekdays, _newDays);
      expect(
        tester
            .widget<ShadButton>(find.widgetWithText(ShadButton, 'Save'))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('Issue 278: moving a one-off with a clash', () {
    testWidgets('Issue 278: Save anyway re-sends the move with '
        'acceptConflicts and closes the editor', (tester) async {
      final start = _hoursFromNow(48);
      final events = await _pump(tester, _oneOff(start));
      events.clash = venueClash();
      final moved = start.add(const Duration(days: 1));

      await _moveOneOff(tester, moved);
      await _save(tester);
      expect(clashDialog, findsOneWidget);
      await saveAnyway(tester);

      expect(events.reschedules.map((c) => c.acceptConflicts), [false, true]);
      expect(events.reschedules.map((c) => c.startTimeUtc), [
        moved.toUtc(),
        moved.toUtc(),
      ]);
      expect(find.text(oneOffScheduleUpdatedMessage), findsOneWidget);
      expect(find.byType(OneOffScheduleForm), findsNothing);
    });

    testWidgets('Issue 278: Cancel keeps the editor open on the new time, '
        'and nothing moves', (tester) async {
      final start = _hoursFromNow(48);
      final events = await _pump(tester, _oneOff(start));
      events.clash = coachOnlyClash();
      final moved = start.add(const Duration(days: 1));

      await _moveOneOff(tester, moved);
      await _save(tester);
      await cancelClash(tester);

      expect(events.reschedules.map((c) => c.acceptConflicts), [false]);
      expect(find.text(oneOffScheduleUpdatedMessage), findsNothing);
      expect(find.byType(OneOffScheduleForm), findsOneWidget);
      final schedule =
          _oneOffForm(
                tester,
              ).formKey.currentState!.value[OneOffScheduleFormFields.scheduleId]
              as OneOffScheduleData;
      expect(schedule.date, DateTime(moved.year, moved.month, moved.day));
    });
  });

  group('Issue 278: the camp and one-off adapters forward acceptConflicts', () {
    final camp = CampScheduleData(
      startDate: DateTime(2030, 8, 1),
      trainingDays: 5,
      sessionStartTime: const ShadTimeOfDay(hour: 6, minute: 0, second: 0),
      durationMinutes: 120,
    );
    Event campEvent() {
      final assembled = assembleCampSchedule(camp);
      return Event(
        id: 1,
        version: 3,
        title: 'test_clash_camp',
        description: '',
        type: EventType.camp,
        visibility: Visibility.public,
        venueId: 7,
        startTimeUtc: assembled.startUtc,
        endTimeUtc: assembled.endUtc,
        rrule: assembled.rrule,
        createdAtUtc: DateTime.utc(2026),
        updatedAtUtc: DateTime.utc(2026),
      );
    }

    for (final accept in [false, true]) {
      test("Issue 278: a camp's moved window sends acceptConflicts "
          '$accept', () async {
        final event = campEvent();
        final events = RecordingScheduleEvents(event);

        await CampScheduleFormSubmit.updateSchedule(
          event: event,
          data: camp.copyWith(trainingDays: 7),
          notifier: events,
          acceptConflicts: accept,
        );

        expect(events.reschedules.single.acceptConflicts, accept);
      });
    }

    test("Issue 278: a camp's clash on a moved window is rethrown for the "
        'dialog', () async {
      final event = campEvent();
      final events = RecordingScheduleEvents(event)..clash = venueClash();

      await expectLater(
        CampScheduleFormSubmit.updateSchedule(
          event: event,
          data: camp.copyWith(trainingDays: 7),
          notifier: events,
        ),
        throwsA(isA<ScheduleConflictException>()),
      );
    });

    test(
      'Issue 278: a one-off move sends acceptConflicts true when asked',
      () async {
        final start = _hoursFromNow(48);
        final event = _oneOff(start);
        final events = RecordingScheduleEvents(event);
        final moved = start.add(const Duration(days: 1));

        await OneOffScheduleFormSubmit.updateSchedule(
          event: event,
          value: OneOffScheduleValue(
            schedule: OneOffScheduleData(
              date: DateTime(moved.year, moved.month, moved.day),
              startTime: ShadTimeOfDay(hour: moved.hour, minute: 0, second: 0),
            ),
            sessions: const [],
          ),
          notifier: events,
          acceptConflicts: true,
        );

        expect(events.reschedules.single.acceptConflicts, isTrue);
      },
    );
  });
}
