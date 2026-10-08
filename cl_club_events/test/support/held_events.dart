// The in-flight scaffolding of the dialogs that save while open: an events
// master that holds every change, and what each dialog needs typed before
// its action can be pressed.
import 'dart:async';

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

import 'programme_fixtures.dart';

/// An events master whose every change waits on [held] before it answers.
class HeldEvents extends ClEventsMasterNotifier {
  HeldEvents(this.event, this.held);

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

Venue heldVenue(int id, String name) => Venue(
  id: id,
  name: name,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

Occurrence heldOccurrence(DateTime start) => Occurrence(
  eventId: 1,
  originalStartTimeUtc: start,
  actualStartTimeUtc: start,
  actualEndTimeUtc: start.add(const Duration(hours: 1)),
  status: OccurrenceStatus.scheduled,
  venueId: 7,
  version: 6,
);

Event heldEvent(EventType type) {
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
Future<HeldEvents> openOverHeldEvents(
  WidgetTester tester,
  Event event,
  Widget dialog,
) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final events = HeldEvents(event, Completer<void>());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        clVenuesProvider.overrideWith(
          (ref, key) async => [
            heldVenue(7, 'North Rink'),
            heldVenue(9, 'Hall'),
          ],
        ),
        clOccurrencesProvider.overrideWith(
          (ref, key) async => [
            for (final days in [10, 11, 12])
              heldOccurrence(localNoon(days).toUtc()),
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

/// Opens the occurrence reschedule dialog with a longer duration typed.
Future<HeldEvents> openHeldReschedule(WidgetTester tester) async {
  final occurrence = heldOccurrence(localNoon(10).toUtc());
  final events = await openOverHeldEvents(
    tester,
    heldEvent(EventType.camp),
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
  return events;
}

/// Opens the cancellation dialog of an event of [type] with a reason typed:
/// Cancel camp for a camp, Call off for a one-off.
Future<HeldEvents> openHeldCancellation(
  WidgetTester tester,
  EventType type,
) async {
  final event = heldEvent(type);
  final events = await openOverHeldEvents(
    tester,
    event,
    EventCancellationDialog(
      event: event,
      occurrenceVersion: type == EventType.camp ? null : 6,
    ),
  );
  await tester.enterText(find.byType(EditableText), 'The rink is closed');
  await tester.pump();
  return events;
}

/// Opens the programme end date dialog with a last day and a reason typed.
Future<HeldEvents> openHeldEndDate(WidgetTester tester) async {
  final event = programmeFixture();
  final events = await openOverHeldEvents(
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
  return events;
}

/// Opens the Adjust Schedule dialog with other weekdays picked.
Future<HeldEvents> openHeldAdjustSchedule(WidgetTester tester) async {
  final event = programmeFixture();
  final events = await openOverHeldEvents(
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
  return events;
}
