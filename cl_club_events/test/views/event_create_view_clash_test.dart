import 'package:cl_club_events/src/models/schedule_clash_gate.dart';
import 'package:cl_club_events/src/views/event_create_view.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventCreateForm,
        EventCreateFormFields,
        EventCreateFormState,
        EventFormType;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, clEventsMasterProvider, clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/schedule_clash_fixtures.dart';

/// An events master that records each create and its `acceptConflicts`,
/// refusing one that does not accept while [writes] holds a clash.
class _ClashingEvents extends ClEventsMasterNotifier {
  final ClashingWrites writes = ClashingWrites();
  final List<String> created = [];

  @override
  Future<Map<int, Event>> build() async => const {};

  @override
  Future<Event> createEvent({
    required String title,
    required String description,
    required EventType type,
    required Visibility visibility,
    required int venueId,
    required DateTime startTimeUtc,
    required DateTime endTimeUtc,
    String? organizerName,
    List<String>? coachNames,
    String? rrule,
    List<Gender>? genders,
    Age? minAge,
    Age? maxAge,
    bool? strictAge,
    bool isFeatured = false,
    List<String>? galleryUris,
    List<EventSession>? sessions,
    bool acceptConflicts = false,
  }) async {
    writes.record(acceptConflicts: acceptConflicts);
    created.add(title);
    return Event(
      id: 1,
      version: 1,
      title: title,
      description: description,
      type: type,
      visibility: visibility,
      venueId: venueId,
      startTimeUtc: startTimeUtc,
      endTimeUtc: endTimeUtc,
      createdAtUtc: DateTime.utc(2026),
      updatedAtUtc: DateTime.utc(2026),
    );
  }
}

class _Host {
  _Host(this.events);

  final _ClashingEvents events;
  int createdCalls = 0;
}

Future<_Host> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final host = _Host(_ClashingEvents());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => host.events),
        clVenuesProvider.overrideWith(
          (ref, key) async => [
            Venue(
              id: 7,
              name: 'North Rink',
              createdAtUtc: DateTime.utc(2026),
              updatedAtUtc: DateTime.utc(2026),
            ),
          ],
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: EventCreateView(
            eventType: EventFormType.oneOff,
            onCreated: () => host.createdCalls++,
            onCancel: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return host;
}

EventCreateFormState _form(WidgetTester tester) =>
    tester.state<EventCreateFormState>(find.byType(EventCreateForm));

/// Fills the title and picks the venue, so the form is valid.
Future<void> _fill(WidgetTester tester) async {
  _form(tester).formKey.currentState!
    ..setFieldValue<String>(EventCreateFormFields.titleId, 'Open day')
    ..setFieldValue<int>(EventCreateFormFields.venueId, 7);
  await tester.pumpAndSettle();
}

Future<void> _create(WidgetTester tester) async {
  await tester.tap(find.text('Create one-off'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 278: creating an event that clashes', () {
    testWidgets('Issue 278: no clash creates at once, without the dialog', (
      tester,
    ) async {
      final host = await _pump(tester);
      await _fill(tester);

      await _create(tester);

      expect(clashDialog, findsNothing);
      expect(host.events.writes.accepts, [false]);
      expect(host.createdCalls, 1);
      expect(find.text('One-off "Open day" created.'), findsOneWidget);
    });

    testWidgets('Issue 278: a clash shows the dialog and nothing is created '
        'yet', (tester) async {
      final host = await _pump(tester);
      await _fill(tester);
      host.events.writes.clash = venueClash();

      await _create(tester);

      expect(clashDialog, findsOneWidget);
      expect(find.text(ScheduleClashGate.venue.label), findsOneWidget);
      expect(find.text('Summer camp · Camp'), findsOneWidget);
      expect(host.events.created, isEmpty);
      expect(host.createdCalls, 0);
    });

    testWidgets('Issue 278: Save anyway re-sends the create with '
        'acceptConflicts and moves on', (tester) async {
      final host = await _pump(tester);
      await _fill(tester);
      host.events.writes.clash = venueClash();

      await _create(tester);
      await saveAnyway(tester);

      expect(host.events.writes.accepts, [false, true]);
      expect(host.events.created, ['Open day']);
      expect(host.createdCalls, 1);
      expect(find.text('One-off "Open day" created.'), findsOneWidget);
    });

    testWidgets('Issue 278: Cancel goes back to the form with the input '
        'kept and nothing created', (tester) async {
      final host = await _pump(tester);
      await _fill(tester);
      host.events.writes.clash = venueClash();

      await _create(tester);
      await cancelClash(tester);

      expect(clashDialog, findsNothing);
      expect(host.events.writes.accepts, [false]);
      expect(host.events.created, isEmpty);
      expect(host.createdCalls, 0);
      final fields = _form(tester).formKey.currentState!.value;
      expect(fields[EventCreateFormFields.titleId], 'Open day');
      expect(fields[EventCreateFormFields.venueId], 7);
      // The form is on again, so the organizer can change it and retry.
      host.events.writes.clash = null;
      await _create(tester);
      expect(host.events.writes.accepts, [false, false]);
      expect(host.createdCalls, 1);
    });

    testWidgets('Issue 278: a coach-only clash lists the coach group alone, '
        'and Save anyway creates', (tester) async {
      final host = await _pump(tester);
      await _fill(tester);
      host.events.writes.clash = coachOnlyClash();

      await _create(tester);

      expect(find.text(ScheduleClashGate.coach.label), findsOneWidget);
      expect(find.text(ScheduleClashGate.venue.label), findsNothing);
      expect(find.text(ScheduleClashGate.organizer.label), findsNothing);
      expect(find.text('Evening squad · Programme'), findsOneWidget);

      await saveAnyway(tester);

      expect(host.events.writes.accepts, [false, true]);
      expect(host.createdCalls, 1);
    });
  });
}
