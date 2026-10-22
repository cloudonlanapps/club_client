import 'package:cl_club_events/src/models/schedule_clash_gate.dart';
import 'package:cl_club_events/src/widgets/cards/actions/occurrence_reschedule_dialog.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        OccurrenceRescheduleForm,
        OccurrenceRescheduleFormFields,
        OccurrenceRescheduleFormState,
        OneOffScheduleData;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, clEventsMasterProvider, clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/schedule_clash_fixtures.dart';

final DateTime _start = DateTime.now().toUtc().add(const Duration(days: 3));

final Occurrence _occurrence = Occurrence(
  eventId: 1,
  originalStartTimeUtc: _start,
  actualStartTimeUtc: _start,
  actualEndTimeUtc: _start.add(const Duration(hours: 1)),
  status: OccurrenceStatus.scheduled,
  venueId: 7,
  version: 2,
);

/// The duration the tests move the session to.
const int _newDuration = 90;

/// Records each occurrence reschedule and its `acceptConflicts`, refusing
/// one that does not accept while [writes] holds a clash.
class _ClashingEvents extends ClEventsMasterNotifier {
  final ClashingWrites writes = ClashingWrites();
  final List<int?> durations = [];

  @override
  Future<Map<int, Event>> build() async => {};

  @override
  Future<void> rescheduleOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
    DateTime? newStartTimeUtc,
    int? newDurationMinutes,
    int? newVenueId,
    bool acceptConflicts = false,
  }) async {
    durations.add(newDurationMinutes);
    writes.record(acceptConflicts: acceptConflicts);
  }
}

class _Host {
  final _ClashingEvents events = _ClashingEvents();
  final List<bool?> popped = [];
}

OccurrenceRescheduleFormState _form(WidgetTester tester) =>
    tester.state<OccurrenceRescheduleFormState>(
      find.byType(OccurrenceRescheduleForm),
    );

/// Opens the dialog over a page and makes the session longer.
Future<_Host> _openEdited(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final host = _Host();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => host.events),
        clVenuesProvider.overrideWith(
          (ref, key) async => [
            Venue(
              id: 7,
              name: 'Main rink',
              isDefault: true,
              createdAtUtc: DateTime.utc(2025),
              updatedAtUtc: DateTime.utc(2025),
            ),
          ],
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ShadButton(
              onPressed: () async => host.popped.add(
                await showShadDialog<bool>(
                  context: context,
                  builder: (_) =>
                      OccurrenceRescheduleDialog(occurrence: _occurrence),
                ),
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
  final form = _form(tester).formKey.currentState!;
  final schedule =
      form.value[OccurrenceRescheduleFormFields.scheduleId]
          as OneOffScheduleData;
  form.setFieldValue<OneOffScheduleData>(
    OccurrenceRescheduleFormFields.scheduleId,
    OneOffScheduleData(
      date: schedule.date,
      startTime: schedule.startTime,
      durationMinutes: _newDuration,
    ),
  );
  await tester.pumpAndSettle();
  return host;
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 278: rescheduling a session that clashes', () {
    testWidgets('Issue 278: no clash moves it at once', (tester) async {
      final host = await _openEdited(tester);

      await _save(tester);

      expect(clashDialog, findsNothing);
      expect(host.events.writes.accepts, [false]);
      expect(host.popped, [true]);
    });

    testWidgets('Issue 278: Save anyway re-sends the same move with '
        'acceptConflicts', (tester) async {
      final host = await _openEdited(tester);
      host.events.writes.clash = venueClash();

      await _save(tester);
      expect(clashDialog, findsOneWidget);
      expect(find.text(ScheduleClashGate.venue.label), findsOneWidget);

      await saveAnyway(tester);

      expect(host.events.writes.accepts, [false, true]);
      expect(host.events.durations, [_newDuration, _newDuration]);
      expect(host.popped, [true]);
      expect(find.byType(OccurrenceRescheduleDialog), findsNothing);
    });

    testWidgets('Issue 278: Cancel goes back to the dialog with the move '
        'kept, and nothing moves', (tester) async {
      final host = await _openEdited(tester);
      host.events.writes.clash = coachOnlyClash();

      await _save(tester);
      expect(find.text(ScheduleClashGate.coach.label), findsOneWidget);
      await cancelClash(tester);

      expect(host.events.writes.accepts, [false]);
      expect(host.popped, isEmpty);
      expect(find.byType(OccurrenceRescheduleDialog), findsOneWidget);
      expect(
        tester
            .widget<OccurrenceRescheduleForm>(
              find.byType(OccurrenceRescheduleForm),
            )
            .enabled,
        isTrue,
      );
      final schedule =
          _form(
                tester,
              ).formKey.currentState!.value[OccurrenceRescheduleFormFields
                  .scheduleId]
              as OneOffScheduleData;
      expect(schedule.durationMinutes, _newDuration);
    });
  });
}
