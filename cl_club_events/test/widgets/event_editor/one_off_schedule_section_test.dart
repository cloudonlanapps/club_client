import 'package:cl_club_events/src/models/one_off_schedule_form_helpers.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_schedule_section.dart';
import 'package:cl_club_events/src/widgets/event_editor/one_off_reschedule_section.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventTimetableForm,
        OneOffScheduleData,
        OneOffScheduleForm,
        OneOffScheduleFormState,
        OneOffScheduleFormValidators,
        SessionInput;
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

import '../../support/recording_schedule_events.dart';

/// [hours] from now, on the local hour.
DateTime _hoursFromNow(int hours) {
  final t = DateTime.now().add(Duration(hours: hours));
  return DateTime(t.year, t.month, t.day, t.hour);
}

Event _oneOff({required DateTime startLocal}) => Event(
  id: 1,
  version: 4,
  title: 'workflow_moveoneoff',
  description: '',
  type: EventType.oneOff,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: startLocal.toUtc(),
  endTimeUtc: startLocal.toUtc().add(const Duration(hours: 2)),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

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
  OccurrenceStatus occurrenceStatus = OccurrenceStatus.scheduled,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
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
            status: occurrenceStatus,
            venueId: 7,
          ),
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

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.byType(SectionEditButton));
  await tester.pumpAndSettle();
}

OneOffScheduleFormState _form(WidgetTester tester) =>
    tester.state<OneOffScheduleFormState>(find.byType(OneOffScheduleForm));

/// Moves the open editor's start to [startLocal], keeping the duration.
Future<void> _moveTo(WidgetTester tester, DateTime startLocal) async {
  _form(tester).formKey.currentState!.setFieldValue<OneOffScheduleData>(
    OneOffScheduleForm.scheduleId,
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

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Issue 37: a one-off not yet started moves its date, time, venue and '
    'sessions in one reschedule with no rrule',
    (tester) async {
      final start = _hoursFromNow(48);
      final events = await _pump(tester, _oneOff(startLocal: start));

      await _openEditor(tester);
      expect(find.byType(OneOffScheduleForm), findsOneWidget);
      expect(find.byType(EventTimetableForm), findsNothing);

      final moved = start.add(const Duration(days: 1));
      await _moveTo(tester, moved);
      final form = _form(tester).formKey.currentState!
        ..setFieldValue<int>(OneOffScheduleForm.venueId, 9);
      final hour = moved.hour.toString().padLeft(2, '0');
      final mid = (moved.hour + 1).toString().padLeft(2, '0');
      final end = (moved.hour + 2).toString().padLeft(2, '0');
      form.setFieldValue<List<SessionInput>>(OneOffScheduleForm.sessionsId, [
        SessionInput(
          name: 'Warm-up',
          startTime: '$hour:00',
          endTime: '$mid:00',
        ),
        SessionInput(name: 'Match', startTime: '$mid:00', endTime: '$end:00'),
      ]);
      await tester.pump();
      await _save(tester);

      final call = events.reschedules.single;
      expect(call.version, 4);
      expect(call.startTimeUtc, moved.toUtc());
      expect(call.endTimeUtc, moved.toUtc().add(const Duration(hours: 2)));
      expect(call.venueId, 9);
      expect(call.sessions?.map((s) => s.periodMinutes), [60, 60]);
      expect(call.rrule, isNull);
      expect(find.text(oneOffScheduleUpdatedMessage), findsOneWidget);
      expect(find.byType(OneOffScheduleForm), findsNothing);
    },
    // The split is typed against hours of the same day.
    skip: _hoursFromNow(48).hour > 21,
  );

  testWidgets('Issue 37: saving an unedited one-off schedule sends nothing', (
    tester,
  ) async {
    final events = await _pump(
      tester,
      _oneOff(startLocal: _hoursFromNow(48)),
    );

    await _openEditor(tester);
    await _save(tester);

    expect(events.reschedules, isEmpty);
    expect(find.byType(OneOffScheduleForm), findsNothing);
  });

  testWidgets(
    'Issue 37: a one-off cannot be moved earlier than it is now',
    (tester) async {
      final start = _hoursFromNow(48);
      final events = await _pump(tester, _oneOff(startLocal: start));

      await _openEditor(tester);
      await _moveTo(tester, start.subtract(const Duration(hours: 3)));
      await _save(tester);

      expect(
        find.text(OneOffScheduleFormValidators.postponeOnlyMessage),
        findsOneWidget,
      );
      expect(events.reschedules, isEmpty);
      expect(find.byType(OneOffScheduleForm), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 37: a started one-off shows its date and times locked with the '
    'reason, and its timetable can still be corrected',
    (tester) async {
      final events = await _pump(
        tester,
        _oneOff(startLocal: _hoursFromNow(-1)),
      );

      expect(find.text(oneOffStartedMessage), findsOneWidget);
      await _openEditor(tester);
      expect(find.byType(OneOffScheduleForm), findsNothing);
      expect(find.byType(EventTimetableForm), findsOneWidget);
      expect(events.reschedules, isEmpty);
    },
  );

  testWidgets(
    'Issue 37: a called-off one-off shows its schedule locked with the '
    'reason',
    (tester) async {
      await _pump(
        tester,
        _oneOff(startLocal: _hoursFromNow(48)),
        occurrenceStatus: OccurrenceStatus.cancelled,
      );

      expect(find.text(oneOffCalledOffMessage), findsOneWidget);
      await _openEditor(tester);
      expect(find.byType(OneOffScheduleForm), findsNothing);
      expect(find.byType(EventTimetableForm), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 37: a stale version closes the editor on the reloaded one-off '
    'and says who changed it',
    (tester) async {
      final start = _hoursFromNow(48);
      final events = await _pump(tester, _oneOff(startLocal: start));
      events.error = StaleVersionException(
        message: 'stale',
        version: 5,
        updatedBy: 'coach_a',
        updatedAtUtc: DateTime.utc(2026, 9, 1, 10),
      );

      await _openEditor(tester);
      await _moveTo(tester, start.add(const Duration(days: 1)));
      await _save(tester);

      expect(find.textContaining('changed by coach_a'), findsOneWidget);
      expect(find.textContaining('check it and try again'), findsOneWidget);
      expect(find.byType(OneOffScheduleForm), findsNothing);
    },
  );

  testWidgets('Issue 37: a refusal past the scheduling horizon is readable', (
    tester,
  ) async {
    final start = _hoursFromNow(48);
    final events = await _pump(tester, _oneOff(startLocal: start));
    events.error = const ServerException(
      statusCode: 422,
      code: SdkErrorCode.beyondSchedulingHorizon,
      message: 'raw server text',
    );

    await _openEditor(tester);
    await _moveTo(tester, start.add(const Duration(days: 1)));
    await _save(tester);

    expect(find.textContaining('further ahead'), findsOneWidget);
    expect(find.textContaining('raw server text'), findsNothing);
    expect(find.byType(OneOffScheduleForm), findsOneWidget);
  });

  testWidgets('Issue 37: a viewer who may not edit sees no pencil', (
    tester,
  ) async {
    await _pump(
      tester,
      _oneOff(startLocal: _hoursFromNow(48)),
      canEdit: false,
    );

    expect(find.byType(SectionEditButton), findsNothing);
    expect(find.text(oneOffStartedMessage), findsNothing);
  });
}
