import 'package:cl_club_events/src/models/camp_schedule_form_helpers.dart'
    show campStartedMessage;
import 'package:cl_club_events/src/widgets/event_editor/event_schedule_section.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        CampScheduleForm,
        EventTimetableForm,
        EventTimetableFormState,
        EventTimetableFormValidators,
        SessionInput;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEventsMasterNotifier,
        clEventSchedulesProvider,
        clEventsMasterProvider,
        clOccurrencesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

Event _event(EventType type, {required DateTime startUtc}) => Event(
  id: 1,
  version: 4,
  title: 'workflow_timetable',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: startUtc,
  endTimeUtc: startUtc.add(const Duration(hours: 2)),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  rrule: type == EventType.oneOff ? null : 'FREQ=DAILY;COUNT=5',
);

DateTime _hoursFromNow(int hours) {
  final t = DateTime.now().toUtc().add(Duration(hours: hours));
  return DateTime.utc(t.year, t.month, t.day, t.hour);
}

/// Records the timetable corrections the section sends, or refuses them
/// with [error].
class _RecordingEvents extends ClEventsMasterNotifier {
  _RecordingEvents(this.event);

  final Event event;
  final List<String> calls = [];
  Exception? error;

  @override
  Future<Map<int, Event>> build() async => {event.id: event};

  @override
  Future<Event> updateEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    String? organizerName,
    List<String>? Function()? coachNames,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
  }) async {
    calls.add('update(v$version, ${sessions?.call()?.length})');
    if (error != null) throw error!;
    return event;
  }

  @override
  Future<Event> correctionOnEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
    int? scheduleId,
  }) async {
    calls.add(
      'correction(v$version, ${sessions?.call()?.length}, '
      'schedule $scheduleId)',
    );
    if (error != null) throw error!;
    return event;
  }
}

EventSchedule _schedule(int id, DateTime from, {DateTime? until}) =>
    EventSchedule(
      id: id,
      eventId: 1,
      effectiveFromUtc: from,
      effectiveUntilUtc: until,
      startTimeUtc: from,
      endTimeUtc: from.add(const Duration(hours: 2)),
      venueId: 7,
    );

Future<_RecordingEvents> _pump(
  WidgetTester tester,
  Event event, {
  List<EventSchedule> schedules = const [],
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final events = _RecordingEvents(event);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        clOccurrencesProvider.overrideWith((ref, key) async => const []),
        clEventSchedulesProvider.overrideWith((ref, id) async => schedules),
      ],
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventScheduleSection(event: event, canEdit: true),
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

/// Splits the day into two sessions in the open timetable editor.
Future<void> _splitDay(WidgetTester tester, {required int totalHours}) async {
  final state = tester.state<EventTimetableFormState>(
    find.byType(EventTimetableForm),
  );
  final end = '${(6 + totalHours).toString().padLeft(2, '0')}:00';
  state.formKey.currentState!.setFieldValue<List<SessionInput>>(
    EventTimetableForm.sessionsId,
    [
      const SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '07:00'),
      SessionInput(name: 'Drills', startTime: '07:00', endTime: end),
    ],
  );
  await tester.pump();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Issue 85: a camp not yet started edits its whole schedule', (
    tester,
  ) async {
    await _pump(tester, _event(EventType.camp, startUtc: _hoursFromNow(72)));

    expect(find.text(campStartedMessage), findsNothing);
    await _openEditor(tester);
    expect(find.byType(CampScheduleForm), findsOneWidget);
  });

  testWidgets(
    'Issue 85: a started camp says its dates are fixed and corrects its '
    'timetable through updateEvent',
    (tester) async {
      final events = await _pump(
        tester,
        _event(EventType.camp, startUtc: _hoursFromNow(-30)),
      );

      expect(find.text(campStartedMessage), findsOneWidget);
      await _openEditor(tester);
      expect(find.byType(CampScheduleForm), findsNothing);
      expect(find.byType(EventTimetableForm), findsOneWidget);

      await _splitDay(tester, totalHours: 2);
      await _save(tester);

      expect(events.calls, ['update(v4, 2)']);
      expect(find.text('Timetable corrected.'), findsOneWidget);
      expect(find.byType(EventTimetableForm), findsNothing);
    },
  );

  testWidgets("Issue 85: a one-off's sessions can be edited", (tester) async {
    // A started one-off: before it starts its whole schedule is edited
    // (club_client#37), and the timetable correction is what remains after.
    final events = await _pump(
      tester,
      _event(EventType.oneOff, startUtc: _hoursFromNow(-1)),
    );

    await _openEditor(tester);
    await _splitDay(tester, totalHours: 2);
    await _save(tester);

    expect(events.calls, ['update(v4, 2)']);
  });

  testWidgets(
    "Issue 85: a programme corrects its latest schedule's sessions in place",
    (tester) async {
      final from = _hoursFromNow(-24 * 20);
      final split = _hoursFromNow(-24 * 5);
      final events = await _pump(
        tester,
        _event(EventType.programme, startUtc: split),
        schedules: [
          _schedule(21, from, until: split),
          _schedule(22, split),
        ],
      );

      await _openEditor(tester);
      expect(find.text('Schedule'), findsWidgets, reason: 'the picker label');
      await _splitDay(tester, totalHours: 2);
      await _save(tester);

      expect(events.calls, ['correction(v4, 2, schedule 22)']);
    },
  );

  testWidgets(
    'Issue 85: a sessions total the server refuses shows against the form',
    (tester) async {
      final events = await _pump(
        tester,
        _event(EventType.camp, startUtc: _hoursFromNow(-30)),
      );
      events.error = const ServerException(
        statusCode: 422,
        code: SdkErrorCode.invalidSessionsTotal,
        message: 'sessions',
      );

      await _openEditor(tester);
      await _splitDay(tester, totalHours: 2);
      await _save(tester);

      expect(
        find.text(EventTimetableFormValidators.totalMismatchMessage),
        findsOneWidget,
      );
      expect(
        find.byType(EventTimetableForm),
        findsOneWidget,
        reason: 'the editor stays open for a retry',
      );
    },
  );

  testWidgets('Issue 85: a stale correction says who changed the event', (
    tester,
  ) async {
    final events = await _pump(
      tester,
      _event(EventType.oneOff, startUtc: _hoursFromNow(-1)),
    );
    events.error = StaleVersionException(
      message: 'stale',
      version: 5,
      updatedBy: 'coach_a',
      updatedAtUtc: DateTime.utc(2026, 9, 1, 10),
    );

    await _openEditor(tester);
    await _splitDay(tester, totalHours: 2);
    await _save(tester);

    expect(find.textContaining('changed by coach_a'), findsOneWidget);
    expect(find.byType(EventTimetableForm), findsNothing);
  });
}
