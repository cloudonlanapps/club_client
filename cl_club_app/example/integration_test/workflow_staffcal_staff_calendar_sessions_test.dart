// workflow_staffcal: what the staff Club Calendar draws for a day's
// sessions.
//
//  * A cancelled session is drawn striped in the week view, apart from a
//    live one, and can still be selected; a day whose only sessions are
//    cancelled has no highlight in the month view (club_client#419).
//
// Setup (SDK, as the suite does for time-dependent fixtures): an admin who
// organizes two camps, and a venue. The live camp runs one day, today,
// starting ~25 minutes from now. The cancelled camp runs today and
// tomorrow, starting half an hour after the live one, so the two overlap;
// both of its days are cancelled.
//
// Runs on both confs:
//   just app-test-one app_test_server1.conf \
//       workflow_staffcal_staff_calendar_sessions_test.dart
//   just app-test-one app_test_server2.conf \
//       workflow_staffcal_staff_calendar_sessions_test.dart

import 'package:cl_club_events/src/providers/selected_occurrence.dart'
    show selectedOccurrenceProvider;
import 'package:cl_club_events/src/widgets/calendar_day_view.dart'
    show CalendarDayView;
import 'package:cl_club_events/src/widgets/calendar_grid.dart'
    show CalendarGrid;
import 'package:cl_club_events/src/widgets/calendar_session_block.dart'
    show CalendarSessionBlock;
import 'package:cl_club_events/src/widgets/calendar_slot_view.dart'
    show CalendarSlotView;
import 'package:club_sdk_2/club_sdk_2.dart'
    show EventType, Gender, SecureClient, Visibility;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons, ShadTheme;
import 'package:ui_lib/ui_lib.dart' show FilmRollColorsExtension;

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
const _kVenue = 'workflow_staffcal_venue';
const _kLiveCamp = 'workflow_staffcal_live';
const _kCancelledCamp = 'workflow_staffcal_cancelled';

const List<String> _kCast = [_kAdmin];

/// How far ahead of setup the live session starts: inside the 30-minute
/// register lead-in.
const _kSessionLead = Duration(minutes: 25);

/// How long each session runs.
const _kSessionLength = Duration(hours: 1);

/// How much later than the live session the cancelled one starts.
const _kCancelledOffset = Duration(minutes: 30);

Future<SecureClient> _sudoClient() async {
  final c = await createTestClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

late int _venueId;
late int _liveId;
late int _cancelledId;

/// Today's live session, and the cancelled camp's today session.
late DateTime _liveStartUtc;
late DateTime _cancelledStartUtc;

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
      soon.minute,
    );
    _cancelledStartUtc = _liveStartUtc.add(_kCancelledOffset);
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
    for (final id in [_liveId, _cancelledId]) {
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
        () => _dayCellColour(tester, _dayCell(_liveStartUtc.toLocal())) != null,
        description: "today's cell drawn",
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
      await _showWeek(tester);
      // The last half-hour cell of the cancelled session is past the live
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
      final liveCell = _slotCell(_slotOf(_liveStartUtc));
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

/// Scrolls the week view to [block] and taps it.
Future<void> _tapBlock(WidgetTester tester, Finder block) async {
  await Scrollable.ensureVisible(tester.element(block.first));
  await tester.pump();
  await tester.tap(block.first);
  await settle(tester);
}
