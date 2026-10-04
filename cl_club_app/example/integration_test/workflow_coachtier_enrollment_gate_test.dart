// workflow_coachtier: the event-coach tier is attendance only
// (club_core#136).
//
// A coach assigned to an event may mark attendance and decide leave on it,
// and may read its enrollment list, but enrollment itself (assign, invite,
// approve, reject, remove, withdrawal decisions) is the organizer's or an
// admin's (club_server attendance R7b, enrollment R10 and R18). A coach not
// on the event gets neither.
//
// Setup (SDK, as the suite does for time-dependent fixtures): an admin who
// organizes a one-off event, a coach assigned to it, a coach who is not,
// and a member assigned to it. The event starts ~25 minutes from now, so
// its register is open (30 minutes ahead).
//
// Steps (UI):
//  1. The assigned coach opens the register from the Club Calendar, then
//     the event's enrollment list from its card: the member is listed,
//     with no Assign / Invite bar and no enrollment action on its row
//     (Add Review only, for a coach).
//  2. The coach not on the event sees the event's card without the
//     Enrollments entry, and its occurrence without the Attendance action.
//  3. The organizer (admin) sees the Assign / Invite bar and the member's
//     Remove action on the same list.
//
// Runs on both confs:
//   just app-test-one app_test_server1.conf \
//       workflow_coachtier_enrollment_gate_test.dart
//   just app-test-one app_test_server2.conf \
//       workflow_coachtier_enrollment_gate_test.dart

import 'package:cl_club_events/src/widgets/cards/event_card.dart'
    show EventCard;
import 'package:cl_club_events/src/widgets/cards/occurrence_card.dart'
    show OccurrenceCard;
import 'package:cl_club_events/src/widgets/enrollment_tile.dart'
    show EnrollmentTile;
import 'package:club_sdk_2/club_sdk_2.dart'
    show EventType, Gender, SecureClient, Visibility;
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, ActionGroup;

import '_helpers/attendance.dart';
import '_helpers/auth.dart';
import '_helpers/enrollments.dart';
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

const _kPwd = 'WorkflowCoachtierPwd!2026';
const _kAddReview = 'Add Review';
const _kAdmin = 'workflow_coachtier_admin';
const _kCoach = 'workflow_coachtier_coach';
const _kOtherCoach = 'workflow_coachtier_othercoach';
const _kMember = 'workflow_coachtier_member';
const _kVenue = 'workflow_coachtier_venue';
const _kEvent = 'workflow_coachtier_event';

const List<String> _kCast = [_kAdmin, _kCoach, _kOtherCoach, _kMember];

/// The events list segment for one-off events.
const _kOneOffSegment = 'one-off';

/// How far ahead of setup the event starts: inside the 30-minute register
/// lead-in.
const _kSessionLead = Duration(minutes: 25);

Future<SecureClient> _sudoClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

late int _eventId;
late int _venueId;

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
        firstName: 'WCoach',
        lastName: u.substring('workflow_coachtier_'.length),
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
    final soon = DateTime.now().toUtc().add(_kSessionLead);
    final start = DateTime.utc(
      soon.year,
      soon.month,
      soon.day,
      soon.hour,
      soon.minute,
    );
    final event = await client.events.createEvent(
      title: _kEvent,
      description: 'workflow_coachtier one-off event',
      type: EventType.oneOff,
      visibility: Visibility.public,
      venueId: venue.id,
      startTimeUtc: start,
      endTimeUtc: start.add(const Duration(hours: 1)),
      organizerName: _kAdmin,
      coachNames: const [_kCoach],
    );
    _eventId = event.id;
    await client.enrollments.assign(_eventId, _kMember);
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
    'Issue 136: an assigned coach takes attendance and reads enrollments '
    'without enrollment actions; a coach not on the event gets neither',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── 1. The assigned coach: attendance, and a read-only list ──────
      await loginViaUi(tester, _kCoach, _kPwd);
      await openRegisterViaCalendarViaUi(tester, eventTitle: _kEvent);
      await registerTile(tester, _kMember);

      await navigateToEnrollmentManagementViaUi(
        tester,
        eventTitle: _kEvent,
        eventTypeSegment: _kOneOffSegment,
      );
      await _memberRow(tester);
      await settle(tester);
      expect(find.text('Assign More…'), findsNothing);
      expect(find.text('Invite More…'), findsNothing);
      // A coach's row may offer Add Review (club_core#174), never an
      // enrollment action.
      final rowActions = [
        for (final g in tester.widgetList<ActionGroup>(
          find.descendant(
            of: find.byType(EnrollmentTile),
            matching: find.byType(ActionGroup),
          ),
        ))
          for (final a in g.actions) a.label,
      ];
      expect(
        rowActions.where((l) => l != _kAddReview),
        isEmpty,
        reason: 'an assigned coach may not change enrollment',
      );
      await logout(tester);

      // ─── 2. The coach not on the event ────────────────────────────────
      await loginViaUi(tester, _kOtherCoach, _kPwd);
      final eventCard = await _eventCard(tester);
      expect(
        find.descendant(
          of: eventCard,
          matching: find.widgetWithText(ActionButton, 'Enrollments'),
        ),
        findsNothing,
        reason: 'a coach not on the event has no Enrollments entry',
      );

      await go(tester, '/memberzone/events/calendar');
      final occurrence = find.ancestor(
        of: find.textContaining(_kEvent),
        matching: find.byType(OccurrenceCard),
      );
      await waitFor(
        tester,
        () => occurrence.evaluate().isNotEmpty,
        description: 'the "$_kEvent" occurrence on the Club Calendar',
      );
      await settle(tester);
      expect(
        find.descendant(
          of: occurrence.first,
          matching: find.widgetWithText(ActionButton, 'Attendance'),
        ),
        findsNothing,
        reason: 'a coach not on the event may not take attendance',
      );
      await logout(tester);

      // ─── 3. The organizer: every enrollment action ────────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await navigateToEnrollmentManagementViaUi(
        tester,
        eventTitle: _kEvent,
        eventTypeSegment: _kOneOffSegment,
      );
      await _memberRow(tester);
      await waitFor(
        tester,
        () => find.text('Assign More…').evaluate().isNotEmpty,
        description: 'the Assign / Invite bar for the organizer',
      );
      expect(find.text('Invite More…'), findsOneWidget);
      final remove = find.descendant(
        of: find.byType(EnrollmentTile),
        matching: find.text('Remove'),
      );
      await waitFor(
        tester,
        () => remove.evaluate().isNotEmpty,
        description: "Remove on the member's row for the organizer",
      );
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// The member's row on the open enrollment list, once it is there.
Future<void> _memberRow(WidgetTester tester) async {
  await waitFor(
    tester,
    () => find
        .byWidgetPredicate((w) => w is EnrollmentTile && w.username == _kMember)
        .evaluate()
        .isNotEmpty,
    description: '$_kMember on the enrollment list',
  );
}

/// The event's card on the one-off events list, once it is there.
Future<Finder> _eventCard(WidgetTester tester) async {
  await go(tester, '/memberzone/events/$_kOneOffSegment');
  final card = find.ancestor(
    of: find.text(_kEvent),
    matching: find.byType(EventCard),
  );
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: 'the "$_kEvent" card on the one-off events list',
  );
  await settle(tester);
  return card;
}
