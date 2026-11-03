// workflow_staffcal: what the staff Club Calendar draws for a day's
// sessions.
//
//  * A cancelled session is drawn striped in the week view, apart from a
//    live one, and can still be selected; a day whose only sessions are
//    cancelled has no highlight in the month view (club_client#419).
//  * Overlapping sessions sit side by side in the week view, each in the
//    same lane in every cell it covers and each selectable; a session that
//    overlaps nothing has the full width (club_client#420).
//  * The Attendance button and the month view's day cell show ◐ once some
//    members are marked and ✓ once all are, and nothing before
//    (club_client#414).
//  * A session that runs past midnight shows whole on the day it starts and
//    nothing of it on the next day (club_client#435).
//
// Setup (SDK, as the suite does for time-dependent fixtures): an admin who
// organizes four camps, two members, and a venue.
//
//  * The register camp runs one day, today, starting 10-25 minutes from now
//    on a quarter hour, so its register is open (30 minutes ahead); both
//    members are assigned to it before it starts.
//  * The lane camp runs next week's Tuesday, 10:00-11:00 local. The
//    cancelled camp runs next week's Tuesday and Wednesday, 10:30-11:30, so
//    the two overlap; both of its days are cancelled.
//  * The midnight camp runs next week's Thursday, 23:30 to Friday 00:30.
//
// Only the register camp depends on the time of day; the others sit at
// fixed local times next week so they never run into the day after.
//
// Runs on both confs:
//   just app-test-one app_test_server1.conf \
//       workflow_staffcal_staff_calendar_sessions_test.dart
//   just app-test-one app_test_server2.conf \
//       workflow_staffcal_staff_calendar_sessions_test.dart

import 'package:cl_club_events/src/models/attendance_progress.dart'
    show AttendanceProgress;
import 'package:cl_club_events/src/providers/selected_occurrence.dart'
    show selectedOccurrenceProvider;
import 'package:cl_club_events/src/widgets/attendance_progress_icon.dart'
    show AttendanceProgressIcon;
import 'package:cl_club_events/src/widgets/calendar_day_view.dart'
    show CalendarDayView;
import 'package:cl_club_events/src/widgets/calendar_grid.dart'
    show CalendarGrid;
import 'package:cl_club_events/src/widgets/calendar_session_block.dart'
    show CalendarSessionBlock;
import 'package:cl_club_events/src/widgets/calendar_slot_view.dart'
    show CalendarSlotView;
import 'package:cl_club_events/src/widgets/cards/occurrence_card.dart'
    show OccurrenceCard;
import 'package:cl_member_zone/cl_member_zone.dart' show EventsCalendarScreen;
import 'package:club_sdk_2/club_sdk_2.dart'
    show AttendanceStatus, EventType, Gender, SecureClient, Visibility;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart'
    show LucideIcons, ShadButton, ShadTheme;
import 'package:ui_lib/ui_lib.dart' show FilmRollColorsExtension;

import '_helpers/actions.dart';
import '_helpers/attendance.dart';
import '_helpers/auth.dart';
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

const _kPwd = 'WorkflowStaffcalPwd!2026';
const _kAdmin = 'workflow_staffcal_admin';
const _kM1 = 'workflow_staffcal_m1';
const _kM2 = 'workflow_staffcal_m2';
const _kVenue = 'workflow_staffcal_venue';
const _kLiveCamp = 'workflow_staffcal_live';
const _kLaneCamp = 'workflow_staffcal_lanes';
const _kCancelledCamp = 'workflow_staffcal_cancelled';
const _kMidnightCamp = 'workflow_staffcal_midnight';

const List<String> _kCast = [_kAdmin, _kM1, _kM2];

/// At most how far ahead of setup the register session starts: inside the
/// 30-minute register lead-in.
const _kSessionLead = Duration(minutes: 25);

/// How long each session runs.
const _kSessionLength = Duration(hours: 1);

/// How much later than the lane session the cancelled one starts.
const _kCancelledOffset = Duration(minutes: 30);

const _kHalfHour = Duration(minutes: 30);

Future<SecureClient> _sudoClient() async {
  final c = await createTestClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

late int _venueId;
late int _liveId;
late int _laneId;
late int _cancelledId;
late int _midnightId;

/// Today's register session.
late DateTime _liveStartUtc;

/// Next week's Tuesday: the lane session and the cancelled camp's first day.
late DateTime _laneStartUtc;
late DateTime _cancelledStartUtc;

/// Next week's Thursday 23:30 local, running past midnight.
late DateTime _midnightStartUtc;

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
        firstName: 'WStaffcal',
        lastName: u.substring('workflow_staffcal_'.length),
        phone: '7400543210',
        email: '$u@example.com',
        gender: Gender.preferNotToSay,
        dateOfBirthUtc: DateTime.utc(2000, 1, 1),
      );
    }
    await client.users.assignRole(_kAdmin, 'admin');
    final venue = await client.venues.createVenue(name: _kVenue);
    _venueId = venue.id;
    final soon = DateTime.now().toUtc().add(_kSessionLead);
    _liveStartUtc = DateTime.utc(
      soon.year,
      soon.month,
      soon.day,
      soon.hour,
      soon.minute - soon.minute % 15,
    );
    final today = DateUtils.dateOnly(DateTime.now());
    final nextMonday = today.add(Duration(days: 8 - today.weekday));
    DateTime nextWeek(int day, int hour, int minute) => DateTime(
      nextMonday.year,
      nextMonday.month,
      nextMonday.day + day,
      hour,
      minute,
    ).toUtc();
    _laneStartUtc = nextWeek(1, 10, 0);
    _cancelledStartUtc = _laneStartUtc.add(_kCancelledOffset);
    _midnightStartUtc = nextWeek(3, 23, 30);
    final live = await client.events.createEvent(
      acceptConflicts: true,
      title: _kLiveCamp,
      description: 'workflow_staffcal live camp',
      type: EventType.camp,
      visibility: Visibility.public,
      venueId: venue.id,
      startTimeUtc: _liveStartUtc,
      endTimeUtc: _liveStartUtc.add(_kSessionLength),
      organizerName: _kAdmin,
      rrule: 'FREQ=DAILY;COUNT=1',
    );
    _liveId = live.id;
    for (final member in const [_kM1, _kM2]) {
      await client.enrollments.assign(_liveId, member);
    }
    final lane = await client.events.createEvent(
      acceptConflicts: true,
      title: _kLaneCamp,
      description: 'workflow_staffcal lane camp',
      type: EventType.camp,
      visibility: Visibility.public,
      venueId: venue.id,
      startTimeUtc: _laneStartUtc,
      endTimeUtc: _laneStartUtc.add(_kSessionLength),
      organizerName: _kAdmin,
      rrule: 'FREQ=DAILY;COUNT=1',
    );
    _laneId = lane.id;
    final midnight = await client.events.createEvent(
      acceptConflicts: true,
      title: _kMidnightCamp,
      description: 'workflow_staffcal midnight camp',
      type: EventType.camp,
      visibility: Visibility.public,
      venueId: venue.id,
      startTimeUtc: _midnightStartUtc,
      endTimeUtc: _midnightStartUtc.add(_kSessionLength),
      organizerName: _kAdmin,
      rrule: 'FREQ=DAILY;COUNT=1',
    );
    _midnightId = midnight.id;
    final cancelled = await client.events.createEvent(
      acceptConflicts: true,
      title: _kCancelledCamp,
      description: 'workflow_staffcal cancelled camp',
      type: EventType.camp,
      visibility: Visibility.public,
      venueId: venue.id,
      startTimeUtc: _cancelledStartUtc,
      endTimeUtc: _cancelledStartUtc.add(_kSessionLength),
      organizerName: _kAdmin,
      rrule: 'FREQ=DAILY;COUNT=2',
    );
    _cancelledId = cancelled.id;
    final sessions = await client.occurrences.listOccurrences(
      fromTimeUtc: _cancelledStartUtc.subtract(const Duration(hours: 1)),
      toTimeUtc: _cancelledStartUtc.add(const Duration(days: 2)),
      eventType: EventType.camp,
    );
    final days = sessions.where((o) => o.eventId == _cancelledId).toList();
    expect(days, hasLength(2), reason: 'the cancelled camp has two days');
    for (final day in days) {
      await client.occurrences.cancelOccurrence(
        _cancelledId,
        day.originalStartTimeUtc,
        version: day.version,
        reason: 'workflow_staffcal: called off',
      );
    }
    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _sudoClient();
    for (final id in [_liveId, _laneId, _cancelledId, _midnightId]) {
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
    'Issue 419: the week view draws a cancelled session striped and it can '
    'still be selected; a day of cancelled sessions only has no highlight',
    (tester) async {
      await useTestSurface(tester, const Size(1600, 3000));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kAdmin, _kPwd);

      // ─── Month view: tomorrow has only cancelled sessions ─────────────
      await _openCalendar(tester);
      final tomorrow = _cancelledStartUtc
          .add(const Duration(days: 1))
          .toLocal();
      await _showMonthOf(tester, tomorrow);
      final tomorrowCell = _dayCell(tomorrow);
      await waitFor(
        tester,
        () => tomorrowCell.evaluate().isNotEmpty,
        description: 'the ${tomorrow.month}/${tomorrow.day} cell',
      );
      // Give the month's sessions time to load before reading the colour.
      await waitFor(
        tester,
        () => _dayCellColour(tester, _dayCell(_laneStartUtc.toLocal())) != null,
        description: "the lane session's cell drawn",
      );
      await settle(tester);
      final highlight = ShadTheme.of(
        tester.element(tomorrowCell),
      ).colorScheme.specialEventHighlight;
      expect(
        _dayCellColour(tester, tomorrowCell),
        isNot(highlight),
        reason:
            'a day whose camp sessions are all cancelled is not '
            'highlighted',
      );

      // ─── Week view: the cancelled session, striped ────────────────────
      await _showWeekOf(tester, _cancelledStartUtc.toLocal());
      // The last half-hour cell of the cancelled session is past the lane
      // one's end, so it holds the cancelled session alone.
      final onlyCancelled = _slotCell(
        _slotOf(_cancelledStartUtc.add(_kSessionLength - _kMinute)),
      );
      await waitFor(
        tester,
        () => _blocksIn(tester, onlyCancelled).isNotEmpty,
        description: 'the cancelled session in the week view',
      );
      final block = _blocksIn(tester, onlyCancelled).single;
      expect(block.cancelled, isTrue, reason: 'drawn as cancelled');
      final liveCell = _slotCell(_slotOf(_laneStartUtc));
      expect(
        _blocksIn(tester, liveCell).map((b) => b.cancelled),
        contains(false),
        reason: 'the live session is drawn as live',
      );

      // ─── Tapping it selects it ────────────────────────────────────────
      await _tapBlock(
        tester,
        find.descendant(
          of: onlyCancelled,
          matching: find.byType(CalendarSessionBlock),
        ),
      );
      final selected = container(tester).read(selectedOccurrenceProvider);
      expect(selected?.eventId, _cancelledId);
      expect(selected?.originalStartTime, _cancelledStartUtc);
      expect(_blocksIn(tester, onlyCancelled).single.selected, isTrue);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  testWidgets(
    'Issue 420: two overlapping sessions show in two lanes in the week view, '
    'each keeping its lane and each selectable',
    (tester) async {
      await useTestSurface(tester, const Size(1600, 3000));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openCalendar(tester);
      await _showWeekOf(tester, _cancelledStartUtc.toLocal());

      // The cell where both run: the lane session left, the cancelled
      // one right, each half the width.
      final shared = _slotCell(_slotOf(_cancelledStartUtc));
      await waitFor(
        tester,
        () => _blocksIn(tester, shared).length == 2,
        description: 'both sessions in the shared cell',
      );
      final lanes = _laneRects(tester, shared);
      expect(lanes.map((l) => l.$1.cancelled), [false, true]);
      final half = _cellWidth(tester, shared) / 2;
      expect(lanes[0].$2.width, closeTo(half, 1));
      expect(lanes[1].$2.width, closeTo(half, 1));
      expect(lanes[1].$2.left, closeTo(lanes[0].$2.right, 1));

      // Each keeps its lane in a cell of its own.
      final liveOnly = _laneRects(tester, _slotCell(_slotOf(_laneStartUtc)));
      expect(liveOnly.map((l) => l.$1.cancelled), [false]);
      expect(liveOnly.single.$2.left, closeTo(lanes[0].$2.left, 1));
      expect(liveOnly.single.$2.width, closeTo(half, 1));
      final cancelledOnly = _laneRects(
        tester,
        _slotCell(_slotOf(_cancelledStartUtc.add(_kSessionLength - _kMinute))),
      );
      expect(cancelledOnly.map((l) => l.$1.cancelled), [true]);
      expect(cancelledOnly.single.$2.left, closeTo(lanes[1].$2.left, 1));

      // Each lane selects its own session.
      final blocks = find.descendant(
        of: shared,
        matching: find.byType(CalendarSessionBlock),
      );
      Finder lane({required bool cancelled}) => find.descendant(
        of: shared,
        matching: find.byWidgetPredicate(
          (w) => w is CalendarSessionBlock && w.cancelled == cancelled,
        ),
      );
      expect(blocks, findsNWidgets(2));
      await _tapBlock(tester, lane(cancelled: true));
      expect(
        container(tester).read(selectedOccurrenceProvider)?.eventId,
        _cancelledId,
      );
      await _tapBlock(tester, lane(cancelled: false));
      expect(
        container(tester).read(selectedOccurrenceProvider)?.eventId,
        _laneId,
      );

      // Wednesday's cancelled session overlaps nothing: the full width.
      final tomorrow = _cancelledStartUtc.add(const Duration(days: 1));
      final tomorrowCell = _slotCell(_slotOf(tomorrow));
      final alone = _laneRects(tester, tomorrowCell);
      expect(alone, hasLength(1));
      expect(
        alone.single.$2.width,
        closeTo(_cellWidth(tester, tomorrowCell), 1),
      );
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  testWidgets(
    'Issue 435: a session that runs past midnight shows whole on the day it '
    'starts and nothing of it on the next day',
    (tester) async {
      await useTestSurface(tester, const Size(1600, 3000));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openCalendar(tester);
      await _showWeekOf(tester, _midnightStartUtc.toLocal());

      // Thursday 23:30: the session, alone, the full width.
      final startCell = _slotCell(_slotOf(_midnightStartUtc));
      await waitFor(
        tester,
        () => _blocksIn(tester, startCell).isNotEmpty,
        description: 'the midnight session in its 23:30 cell',
      );
      final lanes = _laneRects(tester, startCell);
      expect(lanes.map((l) => l.$1.cancelled), [false]);
      expect(lanes.single.$2.width, closeTo(_cellWidth(tester, startCell), 1));

      // Friday 00:00: the session's last half hour, but not its day.
      final nextDayCell = _slotCell(_slotOf(_midnightStartUtc.add(_kHalfHour)));
      expect(nextDayCell, findsOneWidget, reason: 'Friday is in this week');
      expect(
        _blocksIn(tester, nextDayCell),
        isEmpty,
        reason: 'a session shows on the day it starts only',
      );

      // Tapping it selects it.
      await _tapBlock(
        tester,
        find.descendant(
          of: startCell,
          matching: find.byType(CalendarSessionBlock),
        ),
      );
      final selected = container(tester).read(selectedOccurrenceProvider);
      expect(selected?.eventId, _midnightId);
      expect(selected?.originalStartTime, _midnightStartUtc);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  testWidgets(
    'Issue 414: the Attendance button and the day cell show ◐ once some '
    'members are marked and ✓ once all are',
    (tester) async {
      await useTestSurface(tester, const Size(1600, 3000));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kAdmin, _kPwd);

      // ─── Nothing marked: no icon on the button or the day ─────────────
      await _expectMarks(tester, null);

      // ─── One of two marked: ◐ ─────────────────────────────────────────
      await openRegisterViaCalendarViaUi(tester, eventTitle: _kLiveCamp);
      await markInRegisterViaUi(tester, _kM1, AttendanceStatus.present);
      await _expectMarks(tester, AttendanceProgress.partial);

      // ─── Both marked: ✓ ───────────────────────────────────────────────
      await openRegisterViaCalendarViaUi(tester, eventTitle: _kLiveCamp);
      await markInRegisterViaUi(tester, _kM2, AttendanceStatus.absent);
      await _expectMarks(tester, AttendanceProgress.complete);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// Opens the Club Calendar on today and waits until the live camp's
/// Attendance button and today's cell both show [progress] (null: no mark).
Future<void> _expectMarks(
  WidgetTester tester,
  AttendanceProgress? progress,
) async {
  await _openCalendar(tester);
  final card = find.ancestor(
    of: find.textContaining(_kLiveCamp),
    matching: find.byType(OccurrenceCard),
  );
  await waitForInList(
    tester,
    card,
    within: find.byType(EventsCalendarScreen),
    description: 'the "$_kLiveCamp" occurrence on the Club Calendar',
  );
  await waitFor(
    tester,
    () => cardActions(tester, card.first).any((a) => a.label == 'Attendance'),
    description: 'the Attendance action on "$_kLiveCamp"',
  );
  AttendanceProgress? markIn(Finder within) {
    final found = find.descendant(
      of: within,
      matching: find.byType(AttendanceProgressIcon),
    );
    if (found.evaluate().isEmpty) return null;
    return tester.widget<AttendanceProgressIcon>(found.first).progress;
  }

  final button = find.ancestor(
    of: find.descendant(of: card.first, matching: find.text('Attendance')),
    matching: find.byType(ShadButton),
  );
  final today = _dayCell(DateTime.now());
  await waitFor(
    tester,
    () => markIn(button) == progress && markIn(today) == progress,
    description:
        "the Attendance button and today's cell marked "
        '${progress?.name ?? 'with nothing'}',
  );
  if (progress != null) {
    // Today is the selected day: the mark takes the selected text colour.
    final mark = tester.widget<AttendanceProgressIcon>(
      find.descendant(of: today, matching: find.byType(AttendanceProgressIcon)),
    );
    expect(
      mark.color,
      ShadTheme.of(tester.element(today)).colorScheme.primaryForeground,
    );
  }
}

const _kMinute = Duration(minutes: 1);

/// Opens the Club Calendar and waits for its grid.
Future<void> _openCalendar(WidgetTester tester) async {
  await go(tester, '/memberzone/events/calendar');
  await waitFor(
    tester,
    () => find.byType(CalendarGrid).evaluate().isNotEmpty,
    description: 'the Club Calendar grid',
  );
  await settle(tester);
}

/// Moves the month view on to [day]'s month when it is next month.
Future<void> _showMonthOf(WidgetTester tester, DateTime day) async {
  if (day.month == DateTime.now().month) return;
  await tester.tap(
    find.descendant(
      of: find.byType(CalendarGrid),
      matching: find.byIcon(LucideIcons.chevronRight),
    ),
  );
  await settle(tester);
}

/// Switches the calendar to its week view, with the header's M / W toggle
/// (cl_calendar's `ViewToggle`, which the package does not export).
Future<void> _showWeek(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byWidgetPredicate((w) => '${w.runtimeType}' == 'ViewToggle'),
      matching: find.text('W'),
    ),
  );
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(CalendarSlotView).evaluate().isNotEmpty,
    description: 'the week view',
  );
}

/// Switches to the week view and moves it to the week holding [day].
Future<void> _showWeekOf(WidgetTester tester, DateTime day) async {
  await _showWeek(tester);
  final target = DateUtils.dateOnly(day);
  for (var i = 0; i < 8; i++) {
    final shown = tester
        .widgetList<CalendarSlotView>(find.byType(CalendarSlotView))
        .map((v) => DateUtils.dateOnly(v.slotTime))
        .toSet();
    if (shown.contains(target)) return;
    final first = shown.reduce((a, b) => a.isBefore(b) ? a : b);
    await tester.tap(
      find.descendant(
        of: find.byType(CalendarGrid),
        matching: find.byIcon(
          target.isAfter(first)
              ? LucideIcons.chevronRight
              : LucideIcons.chevronLeft,
        ),
      ),
    );
    await settle(tester);
  }
  fail('the week view never showed the week of $target');
}

/// The month view's cell for [day].
Finder _dayCell(DateTime day) => find.descendant(
  of: find.byType(CalendarGrid),
  matching: find.byWidgetPredicate(
    (w) => w is CalendarDayView && DateUtils.isSameDay(w.date, day),
  ),
);

/// The background a month day cell is drawn with, or null when there is
/// no such cell.
Color? _dayCellColour(WidgetTester tester, Finder cell) {
  if (cell.evaluate().isEmpty) return null;
  final box = tester.widget<Container>(
    find
        .descendant(
          of: cell.first,
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.decoration is BoxDecoration,
          ),
        )
        .first,
  );
  return (box.decoration! as BoxDecoration).color;
}

/// The local start of the half-hour cell holding [instantUtc].
DateTime _slotOf(DateTime instantUtc) {
  final local = instantUtc.toLocal();
  return DateTime(
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute < 30 ? 0 : 30,
  );
}

/// The week view's half-hour cell starting at [slot] (local).
Finder _slotCell(DateTime slot) => find.byWidgetPredicate(
  (w) => w is CalendarSlotView && w.slotTime == slot,
  description: 'the $slot cell',
);

/// The sessions drawn in [cell].
List<CalendarSessionBlock> _blocksIn(WidgetTester tester, Finder cell) => tester
    .widgetList<CalendarSessionBlock>(
      find.descendant(of: cell, matching: find.byType(CalendarSessionBlock)),
    )
    .toList();

/// The width the week view gives [cell]'s sessions.
double _cellWidth(WidgetTester tester, Finder cell) =>
    tester.widget<CalendarSlotView>(cell).size.width;

/// The sessions drawn in [cell] with where they are, left to right.
List<(CalendarSessionBlock, Rect)> _laneRects(
  WidgetTester tester,
  Finder cell,
) {
  final found = find.descendant(
    of: cell,
    matching: find.byType(CalendarSessionBlock),
  );
  return [
    for (final e in found.evaluate())
      (
        e.widget as CalendarSessionBlock,
        tester.getRect(find.byWidget(e.widget)),
      ),
  ]..sort((a, b) => a.$2.left.compareTo(b.$2.left));
}

/// Scrolls the week view to [block] and taps it.
Future<void> _tapBlock(WidgetTester tester, Finder block) async {
  await Scrollable.ensureVisible(tester.element(block.first));
  await tester.pump();
  await tester.tap(block.first);
  await settle(tester);
}
