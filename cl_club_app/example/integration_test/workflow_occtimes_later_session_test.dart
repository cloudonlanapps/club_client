// workflow_occtimes: attendance and leave on a later session of a recurring
// programme send real occurrence times (club_core#129).
//
// The server refuses attendance and leave at a time that is not a real
// session of the event (422, club_server#470), so a timezone or rounding
// slip in the app would show up here. The credit workflow only ever marks a
// programme's first session; this one marks the second and declares leave
// on the third.
//
// Setup (SDK, as the suite does for time-dependent fixtures): the cast, a
// venue, and a daily programme whose first session was yesterday, at the
// time of day ~25 minutes from now. So today's session is its second, with
// the register open (30 minutes ahead), and tomorrow's is its third, well
// before the 2-hour leave cutoff. The member is assigned now, before
// today's session: a member counts only for sessions after enrolling. Where
// the credit system is on, the member is funded first, bound to the
// programme. A second member, the leaver, is assigned and funded the same
// way, and sudo files leave for them on today's session with a reason
// (club_core#137): the app's Apply Leave takes no reason, and only sudo may
// file leave inside the 2-hour cutoff, where the register is open.
//
// Steps (UI):
//  1. The coach opens today's register from the Club Calendar and marks
//     the member present.
//  2. The member opens My Calendar, picks tomorrow, and applies for leave
//     on the programme's session; the card turns to cancelling it.
// Then the server is asked for both records at the sessions' own times.
//  3. (Issue 137) The coach opens today's register, sees the leaver's
//     pending request with its reason, and approves it.
//
// Runs on both confs:
//   just app-test-one app_test_server1.conf \
//       workflow_occtimes_later_session_test.dart
//   just app-test-one app_test_server2.conf \
//       workflow_occtimes_later_session_test.dart

import 'package:cl_club_events/src/widgets/calendar_day_view.dart'
    show CalendarDayView;
import 'package:cl_club_events/src/widgets/calendar_grid.dart'
    show CalendarGrid;
import 'package:cl_club_events/src/widgets/cards/occurrence_card.dart'
    show OccurrenceCard;
import 'package:cl_club_events/src/widgets/leave_request_tile.dart'
    show LeaveRequestTile;
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        AttendanceStatus,
        Capabilities,
        EventType,
        Gender,
        SecureClient,
        Visibility;
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show ActionGroup, ActionItem;

import '_helpers/attendance.dart';
import '_helpers/auth.dart';
import '_helpers/capabilities.dart';
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

const _kPwd = 'WorkflowOcctimesPwd!2026';
const _kAdmin = 'workflow_occtimes_admin';
const _kCoach = 'workflow_occtimes_coach';
const _kMember = 'workflow_occtimes_member';
const _kLeaver = 'workflow_occtimes_leaver';
const _kLeaveReason = 'workflow_occtimes: away at a family wedding';
const _kVenue = 'workflow_occtimes_venue';
const _kProgramme = 'workflow_occtimes_programme';

const List<String> _kCast = [_kAdmin, _kCoach, _kMember, _kLeaver];

/// How far ahead of setup today's session starts: inside the 30-minute
/// register lead-in, with room to enroll the member before it begins.
const _kSessionLead = Duration(minutes: 25);

Future<SecureClient> _sudoClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

late int _programmeId;
late int _venueId;

/// Today's session: the programme's second.
late DateTime _todayUtc;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  late Capabilities caps;

  setUpAll(() async {
    caps = await stackCapabilities(
      baseUrl: _kApiBaseUrl,
      username: _kSudoUsername,
      password: _kSudoPassword,
    );
    final client = await _sudoClient();
    for (final u in _kCast) {
      await client.users.createUser(
        username: u,
        passwordHash: _kPwd,
        firstName: 'WOcc',
        lastName: u.substring('workflow_occtimes_'.length),
        phone: '9876543210',
        email: '$u@example.com',
        gender: Gender.preferNotToSay,
        dateOfBirthUtc: DateTime.utc(2000, 1, 1),
      );
    }
    await client.users.assignRole(_kAdmin, 'admin');
    await client.users.assignRole(_kCoach, 'coach');
    final venue = await client.venues.createVenue(name: _kVenue);
    _venueId = venue.id;
    final soon = DateTime.now().toUtc().add(_kSessionLead);
    _todayUtc = DateTime.utc(
      soon.year,
      soon.month,
      soon.day,
      soon.hour,
      soon.minute,
    );
    final first = _todayUtc.subtract(const Duration(days: 1));
    final programme = await client.events.createEvent(
      title: _kProgramme,
      description: 'workflow_occtimes programme',
      type: EventType.programme,
      visibility: Visibility.public,
      venueId: venue.id,
      startTimeUtc: first,
      endTimeUtc: first.add(const Duration(hours: 1)),
      organizerName: _kAdmin,
      coachNames: const [_kCoach],
      rrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU',
    );
    _programmeId = programme.id;
    for (final member in const [_kMember, _kLeaver]) {
      if (caps.creditSystem) {
        await client.credits.openAccount(
          membername: member,
          credits: 5,
          validFromUtc: first.subtract(const Duration(days: 1)),
          validUntilUtc: _todayUtc.add(const Duration(days: 60)),
          reason: 'workflow_occtimes package',
          eventId: _programmeId,
        );
      }
      await client.enrollments.assign(_programmeId, member);
    }
    await client.myEvents.requestLeave(
      _kLeaver,
      _programmeId,
      _todayUtc,
      reason: _kLeaveReason,
    );
    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _sudoClient();
    try {
      await client.events.deleteEvent(_programmeId);
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
    'Issue 129: attendance on a later programme session and leave on the '
    'one after send real occurrence times',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── 1. The coach marks today's session: the programme's second ────
      await loginViaUi(tester, _kCoach, _kPwd);
      await openRegisterViaCalendarViaUi(tester, eventTitle: _kProgramme);
      await markInRegisterViaUi(tester, _kMember, AttendanceStatus.present);
      await logout(tester);

      // ─── 2. The member applies for leave on tomorrow's session ────────
      await loginViaUi(tester, _kMember, _kPwd);
      await go(tester, '/memberzone/my-events/$_kMember/calendar');
      final tomorrow = _todayUtc.add(const Duration(days: 1)).toLocal();
      await _selectDay(tester, tomorrow);

      final apply = await _cardAction(tester, 'Apply Leave');
      apply.onPressed!();
      await settle(tester);
      await _cardAction(tester, 'Cancel Leave', prefix: true);
      await logout(tester);

      // ─── The server holds both at the sessions' own times ──────────────
      final client = await _sudoClient();
      final marked = await client.attendance.getAttendanceForOccurrence(
        _programmeId,
        _todayUtc,
      );
      final leave = await client.attendance.getAttendanceForOccurrence(
        _programmeId,
        _todayUtc.add(const Duration(days: 1)),
      );
      await client.auth.logout();
      expect(
        marked.where((r) => r.membername == _kMember).map((r) => r.status),
        [AttendanceStatus.present],
        reason: "today's mark is on the programme's second session",
      );
      expect(
        leave.where((r) => r.membername == _kMember).map((r) => r.status),
        anyOf(
          equals([AttendanceStatus.onLeaveRequested]),
          equals([AttendanceStatus.onLeave]),
        ),
        reason: "the leave is on tomorrow's session",
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  testWidgets(
    "Issue 137: staff see the member's leave reason on the register and "
    'decide the request',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      await loginViaUi(tester, _kCoach, _kPwd);
      await openRegisterViaCalendarViaUi(tester, eventTitle: _kProgramme);
      final request = find.byWidgetPredicate(
        (w) => w is LeaveRequestTile && w.username == _kLeaver,
      );
      await waitFor(
        tester,
        () => request.evaluate().isNotEmpty,
        description: "the leaver's pending leave request",
      );
      expect(
        find.descendant(of: request, matching: find.text(_kLeaveReason)),
        findsOneWidget,
        reason: 'the reason shows on the request before staff decide',
      );

      tester.widget<LeaveRequestTile>(request).onApprove();
      await waitFor(
        tester,
        () => request.evaluate().isEmpty,
        description: 'the approved request to leave the pending list',
      );
      await logout(tester);

      final client = await _sudoClient();
      final records = await client.attendance.getAttendanceForOccurrence(
        _programmeId,
        _todayUtc,
      );
      await client.auth.logout();
      final leave = records.singleWhere((r) => r.membername == _kLeaver);
      expect(leave.status, AttendanceStatus.onLeave);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// Picks [day] on the My Calendar grid, moving to its month if needed.
Future<void> _selectDay(WidgetTester tester, DateTime day) async {
  final cell = find.descendant(
    of: find.byType(CalendarGrid),
    matching: find.byWidgetPredicate(
      (w) => w is CalendarDayView && DateUtils.isSameDay(w.date, day),
    ),
  );
  await waitFor(
    tester,
    () => find.byType(CalendarGrid).evaluate().isNotEmpty,
    description: 'the My Calendar grid',
  );
  if (day.month != DateTime.now().month) {
    await tester.tap(
      find.descendant(
        of: find.byType(CalendarGrid),
        matching: find.byIcon(LucideIcons.chevronRight),
      ),
    );
    await settle(tester);
  }
  await waitFor(
    tester,
    () => cell.evaluate().isNotEmpty,
    description: 'the ${day.month}/${day.day} cell on My Calendar',
  );
  await tester.tap(cell.first);
  await settle(tester);
}

/// The programme card's action labelled [label] (or starting with it,
/// when [prefix]) on the selected day, once the card offers it.
Future<ActionItem> _cardAction(
  WidgetTester tester,
  String label, {
  bool prefix = false,
}) async {
  final group = find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is OccurrenceCard && w.eventId == _programmeId,
    ),
    matching: find.byType(ActionGroup),
  );
  bool matches(ActionItem a) =>
      prefix ? a.label.startsWith(label) : a.label == label;
  ActionItem? found() {
    for (final element in group.evaluate()) {
      final actions = (element.widget as ActionGroup).actions;
      for (final a in actions) {
        if (matches(a) && a.onPressed != null && !a.loading) return a;
      }
    }
    return null;
  }

  await waitFor(
    tester,
    () => found() != null,
    description: '"$label" on the programme card',
  );
  return found()!;
}
