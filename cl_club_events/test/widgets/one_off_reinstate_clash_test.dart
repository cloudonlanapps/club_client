import 'package:cl_club_events/src/models/event_cancellation_messages.dart';
import 'package:cl_club_events/src/models/schedule_clash_gate.dart';
import 'package:cl_club_events/src/widgets/cards/actions/admin_occurrence_actions.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_management_section.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEventsMasterNotifier,
        clEventsMasterProvider,
        clOccurrencesProvider,
        clSingleOccurrenceProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem;

import '../support/schedule_clash_fixtures.dart';

const int _eventId = 1;
const int _occurrenceVersion = 6;

final DateTime _start = DateTime.now().toUtc().add(const Duration(days: 3));

final Event _oneOff = Event(
  id: _eventId,
  version: 3,
  title: 'test_reinstate_clash',
  description: '',
  type: EventType.oneOff,
  visibility: Visibility.public,
  venueId: 7,
  organizerName: 'the_organizer',
  startTimeUtc: _start,
  endTimeUtc: _start.add(const Duration(hours: 2)),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

final Occurrence _calledOff = Occurrence(
  eventId: _eventId,
  originalStartTimeUtc: _start,
  actualStartTimeUtc: _start,
  actualEndTimeUtc: _start.add(const Duration(hours: 2)),
  status: OccurrenceStatus.cancelled,
  venueId: 7,
  version: _occurrenceVersion,
);

final UserPrivate _admin = UserPrivate(
  username: 'an_admin',
  displayName: 'an_admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

/// Records each reinstate and its `acceptConflicts`, refusing one that does
/// not accept while [writes] holds a clash.
class _ClashingEvents extends ClEventsMasterNotifier {
  final ClashingWrites writes = ClashingWrites();
  final List<int> versions = [];

  @override
  Future<Map<int, Event>> build() async => {_eventId: _oneOff};

  @override
  Future<Event> reinstate(
    int eventId, {
    required int version,
    bool acceptConflicts = false,
  }) async {
    versions.add(version);
    writes.record(acceptConflicts: acceptConflicts);
    return _oneOff;
  }
}

class _StaticAuth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => _admin;
}

void _bigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Pumps the one-off's event page section, as an admin.
Future<_ClashingEvents> _pumpEventPage(WidgetTester tester) async {
  _bigView(tester);
  final events = _ClashingEvents();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        clSingleOccurrenceProvider.overrideWith((ref, key) async => _calledOff),
        clOccurrencesProvider.overrideWith((ref, key) async => [_calledOff]),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: SingleChildScrollView(
              child: EventManagementSection(
                event: _oneOff,
                currentUser: _admin,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

/// Presses Reinstate on the event page, then confirms it.
Future<void> _reinstateOnEventPage(WidgetTester tester) async {
  for (var press = 0; press < 2; press++) {
    await tester.tap(
      find.widgetWithText(ShadButton, EventCancellationMessages.reinstate).last,
    );
    await tester.pumpAndSettle();
  }
}

/// Pumps the occurrence card's admin actions and returns them.
Future<(_ClashingEvents, List<ActionItem>)> _pumpCard(
  WidgetTester tester,
) async {
  _bigView(tester);
  final events = _ClashingEvents();
  late List<ActionItem> actions;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        authStateProvider.overrideWith(_StaticAuth.new),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: AdminOccurrenceActions(
              occurrence: _calledOff,
              onMarkAttendance: (_, _) {},
              builder: (context, resolved) {
                actions = resolved;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return (events, actions);
}

/// Presses the card's Reinstate action, then confirms it.
Future<void> _reinstateOnCard(
  WidgetTester tester,
  List<ActionItem> actions,
) async {
  actions
      .singleWhere((a) => a.label == EventCancellationMessages.reinstate)
      .onPressed!();
  await tester.pumpAndSettle();
  await tester.tap(
    find.widgetWithText(ShadButton, EventCancellationMessages.reinstate),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 278: reinstating a one-off on its event page', () {
    testWidgets('Issue 278: no clash reinstates at once', (tester) async {
      final events = await _pumpEventPage(tester);

      await _reinstateOnEventPage(tester);

      expect(clashDialog, findsNothing);
      expect(events.writes.accepts, [false]);
      expect(find.text(EventCancellationMessages.reinstated), findsOneWidget);
    });

    testWidgets('Issue 278: a clash, then Save anyway, reinstates with '
        'acceptConflicts', (tester) async {
      final events = await _pumpEventPage(tester);
      events.writes.clash = venueClash();

      await _reinstateOnEventPage(tester);
      expect(clashDialog, findsOneWidget);
      expect(find.text(ScheduleClashGate.venue.label), findsOneWidget);
      expect(find.text(EventCancellationMessages.reinstated), findsNothing);

      await saveAnyway(tester);

      expect(events.writes.accepts, [false, true]);
      expect(events.versions, [_occurrenceVersion, _occurrenceVersion]);
      expect(find.text(EventCancellationMessages.reinstated), findsOneWidget);
    });

    testWidgets('Issue 278: a clash, then Cancel, reinstates nothing and '
        'says nothing failed', (tester) async {
      final events = await _pumpEventPage(tester);
      events.writes.clash = coachOnlyClash();

      await _reinstateOnEventPage(tester);
      await cancelClash(tester);

      expect(events.writes.accepts, [false]);
      expect(find.text(EventCancellationMessages.reinstated), findsNothing);
      expect(
        find.text(EventCancellationMessages.reinstateFailed),
        findsNothing,
      );
    });
  });

  group("Issue 278: reinstating a one-off from its session's card", () {
    testWidgets('Issue 278: a clash, then Save anyway, reinstates with '
        'acceptConflicts', (tester) async {
      final (events, actions) = await _pumpCard(tester);
      events.writes.clash = scheduleClash(
        organizer: [clashingEvent('Coaching clinic', type: 'oneOff')],
      );

      await _reinstateOnCard(tester, actions);
      expect(find.text(ScheduleClashGate.organizer.label), findsOneWidget);
      await saveAnyway(tester);

      expect(events.writes.accepts, [false, true]);
      expect(find.text(EventCancellationMessages.reinstated), findsOneWidget);
    });

    testWidgets('Issue 278: a clash, then Cancel, reinstates nothing', (
      tester,
    ) async {
      final (events, actions) = await _pumpCard(tester);
      events.writes.clash = coachOnlyClash();

      await _reinstateOnCard(tester, actions);
      await cancelClash(tester);

      expect(events.writes.accepts, [false]);
      expect(find.text(EventCancellationMessages.reinstated), findsNothing);
    });
  });
}
