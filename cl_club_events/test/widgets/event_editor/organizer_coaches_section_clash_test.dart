import 'package:cl_club_events/src/models/camp_event_form_helpers.dart'
    show EventFormSubmit;
import 'package:cl_club_events/src/models/schedule_clash_gate.dart';
import 'package:cl_club_events/src/widgets/event_editor/organizer_coaches_section.dart'
    show OrganizerCoachesSection;
import 'package:cl_club_forms/cl_club_forms.dart'
    show EventFormFields, EventStaffForm, EventStaffFormState;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEventsMasterNotifier,
        ClUsersMasterNotifier,
        clEventsMasterProvider,
        clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/schedule_clash_fixtures.dart';

Event _event(EventType type) => Event(
  id: 1,
  version: 4,
  title: 'test_staff_clash',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: DateTime.utc(2030, 6, 15, 6),
  endTimeUtc: DateTime.utc(2030, 6, 15, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  organizerName: 'org',
  coachNames: const ['coach_a'],
);

/// Records each staff write (a camp's update, a programme's split) and its
/// `acceptConflicts`, refusing one that does not accept while [writes]
/// holds a clash.
class _ClashingStaffEvents extends ClEventsMasterNotifier {
  _ClashingStaffEvents(this.event);

  final Event event;
  final ClashingWrites writes = ClashingWrites();
  final List<String> verbs = [];

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
    List<Gender> Function()? genders,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
    bool acceptConflicts = false,
  }) async {
    verbs.add('update');
    writes.record(acceptConflicts: acceptConflicts);
    return event;
  }

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
    bool acceptConflicts = false,
  }) async {
    verbs.add('split');
    writes.record(acceptConflicts: acceptConflicts);
    return event;
  }
}

class _NoUsers extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => {};
}

/// Pumps the section of a camp, opens its editor and removes the one coach,
/// so there is a staff change to save.
Future<_ClashingStaffEvents> _pumpEditing(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final event = _event(EventType.camp);
  final events = _ClashingStaffEvents(event);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        clUsersMasterProvider.overrideWith(_NoUsers.new),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: SingleChildScrollView(
              child: OrganizerCoachesSection(event: event),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(LucideIcons.pencil));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x));
  await tester.pumpAndSettle();
  return events;
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

EventStaffFormState _editor(WidgetTester tester) =>
    tester.state<EventStaffFormState>(find.byType(EventStaffForm));

void main() {
  group('Issue 278: a staff change that clashes', () {
    testWidgets('Issue 278: no clash saves at once, without the dialog', (
      tester,
    ) async {
      final events = await _pumpEditing(tester);

      await _save(tester);

      expect(clashDialog, findsNothing);
      expect(events.writes.accepts, [false]);
      expect(find.text('Organizer & coaches updated.'), findsOneWidget);
      expect(find.byType(EventStaffForm), findsNothing);
    });

    testWidgets('Issue 278: a coach-only clash lists the coach, and Save '
        'anyway re-sends with acceptConflicts', (tester) async {
      final events = await _pumpEditing(tester);
      events.writes.clash = coachOnlyClash();

      await _save(tester);

      expect(clashDialog, findsOneWidget);
      expect(find.text(ScheduleClashGate.coach.label), findsOneWidget);
      expect(find.text(ScheduleClashGate.venue.label), findsNothing);
      expect(find.text(ScheduleClashGate.organizer.label), findsNothing);
      expect(find.text('Evening squad · Programme'), findsOneWidget);

      await saveAnyway(tester);

      expect(events.verbs, ['update', 'update']);
      expect(events.writes.accepts, [false, true]);
      expect(find.text('Organizer & coaches updated.'), findsOneWidget);
      expect(find.byType(EventStaffForm), findsNothing);
    });

    testWidgets('Issue 278: Cancel keeps the editor open with the staged '
        'staff, and nothing more is sent', (tester) async {
      final events = await _pumpEditing(tester);
      events.writes.clash = coachOnlyClash();

      await _save(tester);
      await cancelClash(tester);

      expect(clashDialog, findsNothing);
      expect(events.writes.accepts, [false]);
      expect(find.text('Organizer & coaches updated.'), findsNothing);
      expect(find.byType(EventStaffForm), findsOneWidget);
      // The removed coach is still removed: the change waits to be saved.
      expect(_editor(tester).isDirty, isTrue);
    });
  });

  group("Issue 278: a programme's staff split forwards acceptConflicts", () {
    final programme = _event(EventType.programme);
    final values = <String, dynamic>{
      EventFormFields.organizerNameId: 'org',
      EventFormFields.coachNamesId: const <String>['coach_b'],
      EventFormFields.effectiveFromId: DateTime.utc(2030, 6, 22, 6),
    };

    for (final accept in [false, true]) {
      test('Issue 278: acceptConflicts $accept reaches the split', () async {
        final events = _ClashingStaffEvents(programme);

        await EventFormSubmit.updateOrganizer(
          event: programme,
          values: values,
          notifier: events,
          acceptConflicts: accept,
        );

        expect(events.verbs, ['split']);
        expect(events.writes.accepts, [accept]);
      });
    }
  });
}
