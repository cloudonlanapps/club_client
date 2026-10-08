// Issue 108: while its save is in flight, the Save button of each dialog
// here is off and its label says what is happening.
import 'dart:async';
import 'dart:io';

import 'package:cl_club_events/src/models/event_cancellation_messages.dart';
import 'package:cl_club_events/src/models/programme_schedule_form_helpers.dart';
import 'package:cl_club_events/src/widgets/cards/actions/occurrence_reschedule_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_cancellation_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_adjust_schedule_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_end_date_dialog.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        OccurrenceRescheduleForm,
        OccurrenceRescheduleFormFields,
        OccurrenceRescheduleFormState,
        OneOffScheduleData,
        ProgrammeEndDateForm,
        ProgrammeEndDateFormFields,
        ProgrammeEndDateFormState,
        ProgrammeScheduleAdjustForm,
        ProgrammeScheduleAdjustFormFields,
        ProgrammeScheduleAdjustFormState,
        ProgrammeScheduleData;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEventsMasterNotifier,
        clEventsMasterProvider,
        clOccurrencesProvider,
        clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/programme_fixtures.dart';

/// An events master whose every change waits on [held] before it answers.
class _HeldEvents extends ClEventsMasterNotifier {
  _HeldEvents(this.event, this.held);

  final Event event;
  final Completer<void> held;

  /// The changes asked for, by name.
  final List<String> calls = [];

  @override
  Future<Map<int, Event>> build() async => {event.id: event};

  Future<Event> answer(String call) async {
    calls.add(call);
    await held.future;
    return event;
  }

  @override
  Future<Event> terminate(
    int eventId, {
    required String reason,
    required DateTime cutoffTimeUtc,
  }) => answer('terminate');

  @override
  Future<Event> updateEventForAllFuture(
    int eventId, {
    required DateTime effectiveDateTimeUtc,
    int? version,
    int? venueId,
    String? organizerName,
    List<String>? Function()? coachNames,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    String? rrule,
    List<EventSession>? Function()? sessions,
  }) => answer('adjust');

  @override
  Future<Event> cancelSeries(
    int eventId, {
    required String reason,
    required DateTime effectiveDateTimeUtc,
  }) => answer('cancel');

  @override
  Future<Event> drop(
    int eventId, {
    required int version,
    required String reason,
  }) => answer('drop');

  @override
  Future<void> rescheduleOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
    DateTime? newStartTimeUtc,
    int? newDurationMinutes,
    int? newVenueId,
  }) => answer('reschedule');
}

Venue _venue(int id, String name) => Venue(
  id: id,
  name: name,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

Occurrence _occurrence(DateTime start) => Occurrence(
  eventId: 1,
  originalStartTimeUtc: start,
  actualStartTimeUtc: start,
  actualEndTimeUtc: start.add(const Duration(hours: 1)),
  status: OccurrenceStatus.scheduled,
  venueId: 7,
  version: 6,
);

Event _event(EventType type) {
  final start = localNoon(10).toUtc();
  return Event(
    id: 1,
    version: 3,
    title: 'workflow_label_${type.name}',
    description: '',
    type: type,
    visibility: Visibility.public,
    venueId: 7,
    rrule: type == EventType.camp ? 'FREQ=DAILY;COUNT=3' : null,
    startTimeUtc: start,
    endTimeUtc: start.add(const Duration(hours: 1)),
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
  );
}

/// Opens [dialog] over a master that holds every change of [event].
Future<_HeldEvents> _open(
  WidgetTester tester,
  Event event,
  Widget dialog,
) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final events = _HeldEvents(event, Completer<void>());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        clVenuesProvider.overrideWith(
          (ref, key) async => [_venue(7, 'North Rink'), _venue(9, 'Hall')],
        ),
        clOccurrencesProvider.overrideWith(
          (ref, key) async => [
            for (final days in [10, 11, 12])
              _occurrence(localNoon(days).toUtc()),
          ],
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ShadButton(
              onPressed: () => showShadDialog<void>(
                context: context,
                builder: (_) => dialog,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return events;
}

ShadButton _button(WidgetTester tester, String label) =>
    tester.widget<ShadButton>(find.widgetWithText(ShadButton, label).last);

/// Presses [label], and checks that the button then reads [inFlight] and is
/// off until the held change answers, when the dialog [dialog] closes.
Future<void> _expectInFlight(
  WidgetTester tester,
  _HeldEvents events, {
  required String label,
  required String inFlight,
  required String call,
  required Type dialog,
}) async {
  expect(_button(tester, label).onPressed, isNotNull);
  expect(find.text(inFlight), findsNothing);

  await tester.tap(find.widgetWithText(ShadButton, label).last);
  await tester.pump();

  expect(events.calls, [call]);
  expect(find.widgetWithText(ShadButton, label), findsNothing);
  expect(_button(tester, inFlight).onPressed, isNull);
  expect(find.byType(CircularProgressIndicator), findsNothing);

  events.held.complete();
  await tester.pumpAndSettle();
  expect(find.byType(dialog), findsNothing);
}

void main() {
  group('Issue 108: a Save in flight says so', () {
    testWidgets('Issue 108: the occurrence reschedule dialog reads '
        '"Saving…", with no spinner', (tester) async {
      final occurrence = _occurrence(localNoon(10).toUtc());
      final events = await _open(
        tester,
        _event(EventType.camp),
        OccurrenceRescheduleDialog(occurrence: occurrence),
      );
      final form = tester.state<OccurrenceRescheduleFormState>(
        find.byType(OccurrenceRescheduleForm),
      );
      final schedule =
          form.widget.initialValues[OccurrenceRescheduleFormFields.scheduleId]
              as OneOffScheduleData;
      form.formKey.currentState!.setFieldValue<OneOffScheduleData>(
        OccurrenceRescheduleFormFields.scheduleId,
        schedule.copyWith(durationMinutes: 90),
      );
      await tester.pump();

      await _expectInFlight(
        tester,
        events,
        label: 'Save',
        inFlight: 'Saving…',
        call: 'reschedule',
        dialog: OccurrenceRescheduleDialog,
      );
    });

    testWidgets('Issue 108: Cancel camp reads "Cancelling…"', (tester) async {
      final event = _event(EventType.camp);
      final events = await _open(
        tester,
        event,
        EventCancellationDialog(event: event),
      );
      await tester.enterText(find.byType(EditableText), 'The rink is closed');
      await tester.pump();

      await _expectInFlight(
        tester,
        events,
        label: EventCancellationMessages.cancelCamp,
        inFlight: 'Cancelling…',
        call: 'cancel',
        dialog: EventCancellationDialog,
      );
    });

    testWidgets('Issue 108: Call off reads "Calling off…"', (tester) async {
      final event = _event(EventType.oneOff);
      final events = await _open(
        tester,
        event,
        EventCancellationDialog(event: event, occurrenceVersion: 6),
      );
      await tester.enterText(find.byType(EditableText), 'The rink is closed');
      await tester.pump();

      await _expectInFlight(
        tester,
        events,
        label: EventCancellationMessages.callOff,
        inFlight: 'Calling off…',
        call: 'drop',
        dialog: EventCancellationDialog,
      );
    });

    testWidgets('Issue 108: the programme end date dialog reads "Saving…"', (
      tester,
    ) async {
      final event = programmeFixture();
      final events = await _open(
        tester,
        event,
        ProgrammeEndDateDialog(event: event),
      );
      final day = localNoon(5);
      tester
          .state<ProgrammeEndDateFormState>(find.byType(ProgrammeEndDateForm))
          .formKey
          .currentState!
          .setFieldValue<DateTime?>(
            ProgrammeEndDateFormFields.lastDayId,
            DateTime(day.year, day.month, day.day),
          );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(ProgrammeEndDateForm),
          matching: find.byType(EditableText),
        ),
        'Season over',
      );
      await tester.pump();

      await _expectInFlight(
        tester,
        events,
        label: 'Save',
        inFlight: 'Saving…',
        call: 'terminate',
        dialog: ProgrammeEndDateDialog,
      );
    });

    testWidgets('Issue 108: the Adjust Schedule dialog reads "Saving…"', (
      tester,
    ) async {
      final event = programmeFixture();
      final events = await _open(
        tester,
        event,
        ProgrammeAdjustScheduleDialog(
          event: event,
          fromOptions: programmeAdjustFromOptions(event),
        ),
      );
      final form = tester.state<ProgrammeScheduleAdjustFormState>(
        find.byType(ProgrammeScheduleAdjustForm),
      );
      form.formKey.currentState!.setFieldValue<ProgrammeScheduleData>(
        ProgrammeScheduleAdjustFormFields.scheduleId,
        form.widget.initialValue.schedule.copyWith(
          weekdays: {DateTime.tuesday, DateTime.saturday},
        ),
      );
      await tester.pump();

      await _expectInFlight(
        tester,
        events,
        label: 'Save',
        inFlight: 'Saving…',
        call: 'adjust',
        dialog: ProgrammeAdjustScheduleDialog,
      );
    });

    test('Issue 108: Create event writes its in-flight label with one '
        'character, not three dots', () {
      final source = File(
        'lib/src/views/event_create_view.dart',
      ).readAsStringSync();
      expect(source, contains("'Creating…'"));
      expect(source, isNot(contains("'Creating...'")));
    });
  });
}
