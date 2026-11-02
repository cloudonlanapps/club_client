// workflow_attendance: attendance management end to end — staff mark a
// session's register, and the member sees it on My Calendar.
//
// Setup (SDK, as the suite does for time-dependent fixtures): an admin
// (the events' organizer), two members and a venue, and these events, each
// with a session at a fixed local hour every day from three days ago:
//   * the main programme (10:00), public: both members assigned;
//   * the second programme (12:00), public: the first member assigned;
//   * the open programme (14:00), public, open to all: no one enrolled;
//   * the moved programme, private and weekly from six days ago (16:00),
//     whose first session the super-admin moves to the next day.
// For tomorrow the first member has leave requested on the main programme
// and leave approved on the second (sudo files and approves it).
// Credit-funded where the credit system is on, valid from before the first
// session. The members are assigned now, after the past sessions, so only
// a super-admin can mark those (club_server: a member counts for the
// sessions after enrolling); the super-admin is the staff member here.
//
// Steps (UI):
//  1. (Issue 413) The super-admin opens, from the Club Calendar, the moved
//     session's register on its new day: the header names that day. Then
//     yesterday's register of the main programme, marking the first member
//     present and the second absent, and the second programme's, marking
//     the first member late; each header names yesterday.
//  2. (Issue 415) The first member's My Calendar: on yesterday, the two
//     marked sessions show their badges (P green, L orange) with no
//     caption, and the open programme's session reads "You are not
//     enrolled"; on the day before, the unmarked enrolled sessions read
//     "Attendance not recorded". The second member sees A in red.
//  3. (Issue 416) The first member's month view: yesterday's cell shows a
//     pie of a green and an orange slice, tomorrow's an amber and a blue
//     one; the day before yesterday's, with nothing marked, shows none.
//
// Runs on both confs:
//   just app-test-one app_test_server1.conf \
//       workflow_attendance_attendance_management_test.dart
//   just app-test-one app_test_server2.conf \
//       workflow_attendance_attendance_management_test.dart

import 'package:cl_club_events/src/views/event_occurences_attendance_view.dart'
    show EventOccurencesAttendanceView;
import 'package:cl_club_events/src/widgets/attendance_pie.dart'
    show AttendancePie;
import 'package:cl_club_events/src/widgets/cards/attendance_badge.dart'
    show AttendanceBadge;
import 'package:cl_club_events/src/widgets/cards/occurrence_card.dart'
    show OccurrenceCard;
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        AttendanceStatus,
        Capabilities,
        EventType,
        Gender,
        SecureClient,
        Visibility;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show DateFormat;

import '_helpers/attendance.dart';
import '_helpers/auth.dart';
import '_helpers/calendar.dart';
import '_helpers/capabilities.dart';
import '_helpers/pump.dart';
import '_helpers/surface.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

const _kPwd = 'WorkflowAttendancePwd!2026';
const _kAdmin = 'workflow_attendance_admin';
const _kMember = 'workflow_attendance_member';
const _kOther = 'workflow_attendance_other';
const _kVenue = 'workflow_attendance_venue';
const _kMain = 'workflow_attendance_main';
const _kSecond = 'workflow_attendance_second';
const _kMoved = 'workflow_attendance_moved';
const _kOpen = 'workflow_attendance_open';

const List<String> _kCast = [_kAdmin, _kMember, _kOther];
const List<String> _kWeekdays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// The attendance screen's day format (club_client#413).
final DateFormat _kDayFormat = DateFormat('EEE d MMM y');

Future<SecureClient> _sudoClient() async {
  final c = await createTestClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

/// Local midnight today, when the run started.
final DateTime _today = DateUtils.dateOnly(DateTime.now());

/// The local day [offset] days from today.
DateTime _day(int offset) =>
    DateTime(_today.year, _today.month, _today.day + offset);

/// [hour] o'clock local on the day [offset] days from today, in UTC.
DateTime _at(int offset, int hour) =>
    DateTime(_today.year, _today.month, _today.day + offset, hour).toUtc();

final List<int> _eventIds = [];
late int _venueId;
late int _mainId;
late int _secondId;
late int _openId;

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
        firstName: 'WAtt',
        lastName: u.substring('workflow_attendance_'.length),
        phone: '7400643210',
        email: '$u@example.com',
        gender: Gender.preferNotToSay,
        dateOfBirthUtc: DateTime.utc(2000, 1, 1),
      );
    }
    await client.users.assignRole(_kAdmin, 'admin');
    final venue = await client.venues.createVenue(name: _kVenue);
    _venueId = venue.id;

    Future<int> programme(
      String title, {
      required DateTime firstUtc,
      required Visibility visibility,
      String rrule = 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU',
    }) async {
      final event = await client.events.createEvent(
        acceptConflicts: true,
        title: title,
        description: '$title programme',
        type: EventType.programme,
        visibility: visibility,
        venueId: venue.id,
        startTimeUtc: firstUtc,
        endTimeUtc: firstUtc.add(const Duration(hours: 1)),
        organizerName: _kAdmin,
        rrule: rrule,
      );
      _eventIds.add(event.id);
      return event.id;
    }

    Future<void> enrol(int eventId, String member) async {
      if (caps.creditSystem) {
        await client.credits.openAccount(
          membername: member,
          credits: 10,
          validFromUtc: _at(-7, 0),
          validUntilUtc: _at(60, 0),
          reason: 'workflow_attendance package',
          eventId: eventId,
        );
      }
      await client.enrollments.assign(eventId, member);
    }

    final main = await programme(
      _kMain,
      firstUtc: _at(-3, 10),
      visibility: Visibility.public,
    );
    final second = await programme(
      _kSecond,
      firstUtc: _at(-3, 12),
      visibility: Visibility.public,
    );
    _openId = await programme(
      _kOpen,
      firstUtc: _at(-3, 14),
      visibility: Visibility.public,
    );
    _mainId = main;
    _secondId = second;
    await enrol(main, _kMember);
    await enrol(main, _kOther);
    await enrol(second, _kMember);
    await client.myEvents.requestLeave(_kMember, main, _at(1, 10));
    await client.myEvents.requestLeave(_kMember, second, _at(1, 12));
    await client.attendance.approveLeave(second, _kMember, _at(1, 12));

    // A weekly session six days ago, moved by the super-admin to the next
    // day: its register must name the day it moved to.
    final movedFrom = _at(-6, 16);
    final moved = await programme(
      _kMoved,
      firstUtc: movedFrom,
      visibility: Visibility.private,
      rrule: 'FREQ=WEEKLY;BYDAY=${_kWeekdays[movedFrom.weekday - 1]}',
    );
    final session = await client.occurrences.getOccurrence(moved, movedFrom);
    await client.occurrences.rescheduleOccurrence(
      moved,
      movedFrom,
      version: session.version,
      newStartTimeUtc: _at(-5, 16),
      acceptConflicts: true,
    );
    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _sudoClient();
    for (final id in _eventIds) {
      try {
        await client.events.deleteEvent(id);
      } on Object catch (_) {}
    }
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
    "Issue 413: staff mark past sessions on registers that name the session's "
    'day, a moved one its new day',
    (tester) async {
      await useTestSurface(tester, const Size(1600, 3000));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);

      // The moved session, on the day it moved to.
      await openRegisterViaCalendarViaUi(
        tester,
        eventTitle: _kMoved,
        day: _day(-5),
      );
      await _expectRegisterDay(tester, _day(-5));

      // Yesterday's sessions: the main programme, then the second.
      await openRegisterViaCalendarViaUi(
        tester,
        eventTitle: _kMain,
        day: _day(-1),
      );
      await _expectRegisterDay(tester, _day(-1));
      await markInRegisterViaUi(tester, _kMember, AttendanceStatus.present);
      await markInRegisterViaUi(tester, _kOther, AttendanceStatus.absent);

      await openRegisterViaCalendarViaUi(
        tester,
        eventTitle: _kSecond,
        day: _day(-1),
      );
      await _expectRegisterDay(tester, _day(-1));
      await markInRegisterViaUi(tester, _kMember, AttendanceStatus.late);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  testWidgets(
    'Issue 415: My Calendar shows a marked past session by its badge alone, '
    'in the staff colours, and tells "not enrolled" from "not recorded"',
    (tester) async {
      await useTestSurface(tester, const Size(1600, 3000));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      await loginViaUi(tester, _kMember, _kPwd);
      await go(tester, '/memberzone/my-events/$_kMember/calendar');

      // Yesterday: marked by staff in step 1.
      await selectCalendarDayViaUi(tester, _day(-1));
      await _expectBadge(tester, _mainId, 'P', Colors.green);
      await _expectBadge(tester, _secondId, 'L', Colors.orange);
      await _expectCaption(tester, _openId, 'You are not enrolled');

      // The day before: nothing marked.
      await selectCalendarDayViaUi(tester, _day(-2));
      await _expectCaption(tester, _mainId, 'Attendance not recorded');
      await _expectCaption(tester, _secondId, 'Attendance not recorded');
      await _expectCaption(tester, _openId, 'You are not enrolled');
      await logout(tester);

      await loginViaUi(tester, _kOther, _kPwd);
      await go(tester, '/memberzone/my-events/$_kOther/calendar');
      await selectCalendarDayViaUi(tester, _day(-1));
      await _expectBadge(tester, _mainId, 'A', Colors.red);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  testWidgets(
    "Issue 416: the member's month view shows a pie of each day's recorded "
    'attendance, and none on a day with nothing recorded',
    (tester) async {
      await useTestSurface(tester, const Size(1600, 3000));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      await loginViaUi(tester, _kMember, _kPwd);
      await go(tester, '/memberzone/my-events/$_kMember/calendar');

      // Yesterday: present at 10:00, late at 12:00 (step 1).
      await selectCalendarDayViaUi(tester, _day(-1));
      await _expectPie(tester, _day(-1), [Colors.green, Colors.orange]);

      // The day before: sessions, none marked.
      await selectCalendarDayViaUi(tester, _day(-2));
      await _expectCaption(tester, _mainId, 'Attendance not recorded');
      expect(
        find.descendant(
          of: calendarDayCell(_day(-2)),
          matching: find.byType(AttendancePie),
        ),
        findsNothing,
        reason: 'a day with nothing recorded shows no pie',
      );

      // Tomorrow: leave requested at 10:00, leave approved at 12:00.
      await selectCalendarDayViaUi(tester, _day(1));
      await _expectPie(tester, _day(1), [Colors.amber, Colors.blue]);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// Waits for the local [day]'s cell to show a pie of [colors], clockwise
/// from the top.
Future<void> _expectPie(
  WidgetTester tester,
  DateTime day,
  List<Color> colors,
) async {
  final pie = find.descendant(
    of: calendarDayCell(day),
    matching: find.byType(AttendancePie),
  );
  await waitFor(
    tester,
    () => pie.evaluate().isNotEmpty,
    description: 'the pie on ${_kDayFormat.format(day)}',
  );
  expect(tester.widget<AttendancePie>(pie).sliceColors, colors);
}

/// The selected day's card of the event [eventId] on My Calendar.
Finder _card(int eventId) =>
    find.byWidgetPredicate((w) => w is OccurrenceCard && w.eventId == eventId);

/// The past session captions a card can carry.
const List<String> _kPastCaptions = [
  'You attended',
  'You were absent',
  'You were late',
  'You were on leave',
  'Leave was pending',
  'Attendance not recorded',
  'You are not enrolled',
];

/// Waits for [eventId]'s card to read [caption], and no badge.
Future<void> _expectCaption(
  WidgetTester tester,
  int eventId,
  String caption,
) async {
  final text = find.descendant(
    of: _card(eventId),
    matching: find.text(caption),
  );
  await waitFor(
    tester,
    () => text.evaluate().isNotEmpty,
    description: 'event $eventId\'s card to read "$caption"',
  );
  expect(
    find.descendant(of: _card(eventId), matching: find.byType(AttendanceBadge)),
    findsNothing,
  );
}

/// Waits for [eventId]'s card to show the badge [code] in [color], with no
/// caption beside it.
Future<void> _expectBadge(
  WidgetTester tester,
  int eventId,
  String code,
  Color color,
) async {
  final badge = find.descendant(
    of: _card(eventId),
    matching: find.byType(AttendanceBadge),
  );
  await waitFor(
    tester,
    () => badge.evaluate().isNotEmpty,
    description: 'the "$code" badge on event $eventId\'s card',
  );
  final codeText = tester.widget<Text>(
    find.descendant(of: badge, matching: find.text(code)),
  );
  expect(codeText.style?.color, color, reason: 'the "$code" badge colour');
  for (final caption in _kPastCaptions) {
    expect(
      find.descendant(of: _card(eventId), matching: find.text(caption)),
      findsNothing,
      reason: 'no "$caption" beside the "$code" badge',
    );
  }
}

/// Waits for the open register's header to name the local [day], as
/// `Attendance · Sat 1 Nov 2026`.
Future<void> _expectRegisterDay(WidgetTester tester, DateTime day) async {
  final header = find.descendant(
    of: find.byType(EventOccurencesAttendanceView),
    matching: find.text('Attendance · ${_kDayFormat.format(day)}'),
  );
  await waitFor(
    tester,
    () => header.evaluate().isNotEmpty,
    description: 'the register header naming ${_kDayFormat.format(day)}',
  );
}
