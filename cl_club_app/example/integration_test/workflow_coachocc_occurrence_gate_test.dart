// workflow_coachocc: rescheduling and cancelling an occurrence is the
// organizer's or an admin's (club_core#146).
//
// The server refuses reschedule, cancel and undo-cancel on an occurrence to
// anyone but the event's organizer or an admin (club_server
// `routers/occurrences.py`, `require_organizer_or_admin`). A coach assigned
// to the event takes attendance on it, and nothing more.
//
// Setup (SDK, as the suite does for time-dependent fixtures): an admin who
// organizes a one-off event, a coach assigned to it and a coach who is not.
// The event is tomorrow at noon local time, well before the register opens,
// so its occurrence is in the schedule-management window.
//
// Steps (UI):
//  1. The organizer (admin) picks tomorrow on the Club Calendar: the
//     occurrence offers Reschedule and the cancel actions.
//  2. The assigned coach and the coach not on the event see the same
//     occurrence with none of them.
//
// Runs on both confs:
//   just app-test-one app_test_server1.conf \
//       workflow_coachocc_occurrence_gate_test.dart
//   just app-test-one app_test_server2.conf \
//       workflow_coachocc_occurrence_gate_test.dart

import 'package:cl_club_events/src/widgets/calendar_day_view.dart'
    show CalendarDayView;
import 'package:cl_club_events/src/widgets/calendar_grid.dart'
    show CalendarGrid;
import 'package:cl_club_events/src/widgets/cards/occurrence_card.dart'
    show OccurrenceCard;
import 'package:club_sdk_2/club_sdk_2.dart'
    show EventType, Gender, SecureClient, Visibility;
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show ActionGroup;

import '_helpers/auth.dart';
import '_helpers/pump.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

const _kPwd = 'WorkflowCoachoccPwd!2026';
const _kAdmin = 'workflow_coachocc_admin';
const _kCoach = 'workflow_coachocc_coach';
const _kOtherCoach = 'workflow_coachocc_othercoach';
const _kVenue = 'workflow_coachocc_venue';
const _kEvent = 'workflow_coachocc_event';

const List<String> _kCast = [_kAdmin, _kCoach, _kOtherCoach];

/// The occurrence actions the server keeps to the organizer or an admin.
const List<String> _kManaged = [
  'Reschedule',
  'Cancel this occurrence',
  'Cancel entire series',
];

Future<SecureClient> _sudoClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

late int _eventId;
late int _venueId;

/// Tomorrow at noon, local time: the day the occurrence falls on.
late DateTime _dayLocal;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  setUpAll(() async {
    final client = await _sudoClient();
    for (final u in _kCast) {
      await client.users.createUser(
        username: u,
        passwordHash: _kPwd,
        firstName: 'WCoachocc',
        lastName: u.substring('workflow_coachocc_'.length),
        phone: '9876543210',
        email: '$u@example.com',
        gender: Gender.preferNotToSay,
        dateOfBirthUtc: DateTime.utc(2000, 1, 1),
      );
    }
    await client.users.assignRole(_kAdmin, 'admin');
    await client.users.assignRole(_kCoach, 'coach');
    await client.users.assignRole(_kOtherCoach, 'coach');
    final venue = await client.venues.createVenue(name: _kVenue);
    _venueId = venue.id;
    final now = DateTime.now();
    _dayLocal = DateTime(now.year, now.month, now.day + 1, 12);
    final start = _dayLocal.toUtc();
    final event = await client.events.createEvent(
      title: _kEvent,
      description: 'workflow_coachocc one-off event',
      type: EventType.oneOff,
      visibility: Visibility.public,
      venueId: venue.id,
      startTimeUtc: start,
      endTimeUtc: start.add(const Duration(hours: 1)),
      organizerName: _kAdmin,
      coachNames: const [_kCoach],
    );
    _eventId = event.id;
    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _sudoClient();
    try {
      await client.events.deleteEvent(_eventId);
    } on Object catch (_) {}
    // A leftover venue pushes later tests' venues down the lazy list.
    try {
      await client.venues.deleteVenue(_venueId);
    } on Object catch (_) {}
    for (final u in _kCast) {
      try {
        await client.users.deleteUser(u);
      } on Object catch (_) {}
    }
    await client.auth.logout();
  });

  testWidgets(
    'Issue 146: only the organizer is offered Reschedule and Cancel on an '
    'occurrence; its coaches are not',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── 1. The organizer (admin): every management action ────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openOccurrence(tester);
      await waitFor(
        tester,
        () => _kManaged.every(_occurrenceLabels().contains),
        description: 'Reschedule and the cancel actions for the organizer',
      );
      await logout(tester);

      // ─── 2. The coaches: none of them ─────────────────────────────────
      for (final coach in const [_kCoach, _kOtherCoach]) {
        await loginViaUi(tester, coach, _kPwd);
        await _openOccurrence(tester);
        final offered = _occurrenceLabels();
        for (final label in _kManaged) {
          expect(
            offered,
            isNot(contains(label)),
            reason: '$coach is not the organizer and may not "$label"',
          );
        }
        await logout(tester);
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// Opens the Club Calendar on tomorrow and waits for the event's occurrence
/// card, titled from the events master its actions resolve against.
Future<void> _openOccurrence(WidgetTester tester) async {
  await go(tester, '/memberzone/events/calendar');
  await waitFor(
    tester,
    () => find.byType(CalendarGrid).evaluate().isNotEmpty,
    description: 'the Club Calendar grid',
  );
  if (_dayLocal.month != DateTime.now().month) {
    await tester.tap(
      find.descendant(
        of: find.byType(CalendarGrid),
        matching: find.byIcon(LucideIcons.chevronRight),
      ),
    );
    await settle(tester);
  }
  final cell = find.descendant(
    of: find.byType(CalendarGrid),
    matching: find.byWidgetPredicate(
      (w) => w is CalendarDayView && DateUtils.isSameDay(w.date, _dayLocal),
    ),
  );
  await waitFor(
    tester,
    () => cell.evaluate().isNotEmpty,
    description: 'the ${_dayLocal.month}/${_dayLocal.day} cell',
  );
  await tester.tap(cell.first);
  await settle(tester);
  final card = find.ancestor(
    of: find.textContaining(_kEvent),
    matching: find.byType(OccurrenceCard),
  );
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: 'the "$_kEvent" occurrence on the Club Calendar',
  );
  await settle(tester);
}

/// The labels of every action the event's occurrence card offers.
List<String> _occurrenceLabels() {
  final groups = find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is OccurrenceCard && w.eventId == _eventId,
    ),
    matching: find.byType(ActionGroup),
  );
  return [
    for (final element in groups.evaluate())
      for (final a in (element.widget as ActionGroup).actions) a.label,
  ];
}
