// workflow_endprog: an admin sets, moves and clears a programme's end date
// from its Schedule block (club_client#39).
//
// A programme runs with no end until it is given one. The server keeps the
// end as a cutoff, a session start from which sessions no longer occur
// (terminate sets it, extend moves it, extend-indefinitely removes it). The
// admin picks the last day instead, and the app turns it into the cutoff:
// the first session start after the end of that day.
//
// Setup (SDK, as the suite does for time-dependent fixtures): an admin, a
// venue, and a one-hour programme held every day at local noon since ten
// days ago.
//
// Steps (UI):
//  1. The admin opens the programme: its Schedule block reads "No end
//     date". Adjust end date opens the dialog; they pick the day five days
//     ahead, read the last session it gives, type a reason and save. The
//     block shows the end date, and the programme is still on the Programmes
//     list.
//  2. They move the end to a later day, then to an earlier one.
//  3. They clear it: the block reads "No end date" again.
// After each step the server is asked for the programme and its sessions:
// sessions from the cutoff on no longer occur, and occur again once the end
// is cleared.
//
//   just app-test-one app_test_server1.conf \
//       workflow_endprog_programme_end_date_test.dart

import 'package:cl_club_events/cl_club_events.dart' show EventDetailsView;
import 'package:cl_club_events/src/utils/programme_end_date.dart'
    show programmeEndDayFormat, programmeNoEndDateLine;
import 'package:cl_club_events/src/widgets/event_editor/programme_end_date_dialog.dart'
    show ProgrammeEndDateDialog;
import 'package:cl_club_events/src/widgets/event_editor/programme_schedule_actions.dart'
    show ProgrammeScheduleActions;
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ProgrammeEndDateForm,
        ProgrammeEndDateFormFields,
        ProgrammeEndDateFormState;
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        Event,
        EventType,
        Gender,
        Occurrence,
        OccurrenceStatus,
        SecureClient,
        Visibility;
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EntityCard;

import '_helpers/auth.dart';
import '_helpers/forms.dart';
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

const _kPwd = 'WorkflowEndProgPwd!2026';
const _kAdmin = 'workflow_endprog_admin';
const _kVenue = 'workflow_endprog_venue';
const _kProgramme = 'workflow_endprog_programme';
const _kReason = 'workflow_endprog season over';

/// The local hour every session starts at.
const _kHour = 12;

/// The last day first set, the later day it moves to, then the earlier one,
/// in days from today.
const _kFirstLastDay = 5;
const _kLaterLastDay = 9;
const _kEarlierLastDay = 3;

/// How many days of sessions the server is asked for.
const _kWindowDays = 14;

/// Local [hour] o'clock, [days] from today.
DateTime _localDay(int days, [int hour = 0]) {
  final t = DateTime.now().add(Duration(days: days));
  return DateTime(t.year, t.month, t.day, hour);
}

/// The cutoff a last day [days] from today gives: the next day's session.
DateTime _cutoffAfter(int days) => _localDay(days + 1, _kHour).toUtc();

Future<SecureClient> _sudoClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

late int _venueId;
late Event _programme;

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
    await client.users.createUser(
      username: _kAdmin,
      passwordHash: _kPwd,
      firstName: 'WEndProg',
      lastName: 'admin',
      phone: '9876543210',
      email: '$_kAdmin@example.com',
      gender: Gender.preferNotToSay,
      dateOfBirthUtc: DateTime.utc(2000, 1, 1),
    );
    await client.users.assignRole(_kAdmin, 'admin');
    _venueId = (await client.venues.createVenue(name: _kVenue)).id;
    final start = _localDay(-10, _kHour).toUtc();
    _programme = await client.events.createEvent(
      title: _kProgramme,
      description: 'workflow_endprog programme',
      type: EventType.programme,
      visibility: Visibility.public,
      venueId: _venueId,
      startTimeUtc: start,
      endTimeUtc: start.add(const Duration(hours: 1)),
      organizerName: _kAdmin,
      rrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU',
    );
    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _sudoClient();
    try {
      await client.events.deleteEvent(_programme.id);
    } on Object catch (_) {}
    // A leftover venue pushes later tests' venues down the lazy list.
    try {
      await client.venues.deleteVenue(_venueId);
    } on Object catch (_) {}
    try {
      await client.users.deleteUser(_kAdmin);
    } on Object catch (_) {}
    await client.auth.logout();
  });

  testWidgets(
    'Issue 39: an admin sets an end date on a programme with a reason, '
    'moves it later and earlier, and clears it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kAdmin, _kPwd);

      // ─── 1. No end date; set one with a reason ────────────────────────
      await _openDetail(tester);
      await waitFor(
        tester,
        () => find.text(programmeNoEndDateLine).evaluate().isNotEmpty,
        description: '"No end date" in the Schedule block',
      );
      await _openEndDateDialog(tester);
      expect(
        find.widgetWithText(ShadButton, ProgrammeEndDateDialog.clearLabel),
        findsNothing,
        reason: 'there is no end date to clear yet',
      );
      await _pickLastDay(tester, _kFirstLastDay);
      await enterTextById(
        tester,
        ProgrammeEndDateFormFields.reasonId,
        _kReason,
      );
      await _saveEndDate(tester);
      await _expectEndDateShown(tester, _kFirstLastDay);
      var state = await _serverState();
      expect(state.event.untilTimeUtc, _cutoffAfter(_kFirstLastDay));
      _expectSessionsStopAt(state.sessions, _cutoffAfter(_kFirstLastDay));

      // The programme is still on the Programmes list.
      await _openDetail(tester);

      // ─── 2. Later, then earlier ───────────────────────────────────────
      await _openEndDateDialog(tester);
      await _pickLastDay(tester, _kLaterLastDay);
      await _saveEndDate(tester);
      await _expectEndDateShown(tester, _kLaterLastDay);
      state = await _serverState();
      expect(state.event.untilTimeUtc, _cutoffAfter(_kLaterLastDay));

      await _openEndDateDialog(tester);
      await _pickLastDay(tester, _kEarlierLastDay);
      await _saveEndDate(tester);
      await _expectEndDateShown(tester, _kEarlierLastDay);
      state = await _serverState();
      expect(state.event.untilTimeUtc, _cutoffAfter(_kEarlierLastDay));
      _expectSessionsStopAt(state.sessions, _cutoffAfter(_kEarlierLastDay));

      // ─── 3. Clear it ──────────────────────────────────────────────────
      await _openEndDateDialog(tester);
      invokeShadButton(
        tester,
        find.widgetWithText(ShadButton, ProgrammeEndDateDialog.clearLabel),
        reason: 'Clear end date',
      );
      await settle(tester);
      await _waitForDialogToClose(tester);
      await waitFor(
        tester,
        () => find.text(programmeNoEndDateLine).evaluate().isNotEmpty,
        description: '"No end date" after clearing',
      );
      await logout(tester);

      state = await _serverState();
      expect(state.event.untilTimeUtc, isNull);
      expect(
        state.sessions.where((o) => o.status == OccurrenceStatus.cancelled),
        isEmpty,
        reason: 'sessions continue once the end is cleared',
      );
      expect(
        state.sessions.where(
          (o) => !o.originalStartTimeUtc.isBefore(
            _cutoffAfter(_kEarlierLastDay),
          ),
        ),
        isNotEmpty,
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// The programme and its sessions over the next [_kWindowDays] days, as the
/// server has them now.
Future<({Event event, List<Occurrence> sessions})> _serverState() async {
  final client = await _sudoClient();
  final event = await client.events.getEvent(_programme.id);
  final sessions = (await client.occurrences.listOccurrences(
    fromTimeUtc: DateTime.now().toUtc(),
    toTimeUtc: _localDay(_kWindowDays).toUtc(),
    eventType: EventType.programme,
  )).where((o) => o.eventId == _programme.id).toList();
  await client.auth.logout();
  return (event: event, sessions: sessions);
}

/// Sessions before [cutoff] occur; those from it on do not.
void _expectSessionsStopAt(List<Occurrence> sessions, DateTime cutoff) {
  final before = sessions.where(
    (o) => o.originalStartTimeUtc.isBefore(cutoff),
  );
  final after = sessions.where((o) => !o.originalStartTimeUtc.isBefore(cutoff));
  expect(before, isNotEmpty, reason: 'sessions up to the end still occur');
  for (final o in before) {
    expect(o.status, isNot(OccurrenceStatus.cancelled));
  }
  for (final o in after) {
    expect(
      o.status,
      OccurrenceStatus.cancelled,
      reason: 'a session from the cutoff on does not occur',
    );
  }
}

/// Opens the programme from the Programmes list, as an admin does.
Future<void> _openDetail(WidgetTester tester) async {
  await go(tester, '/memberzone/events/programmes');
  final card = find.byWidgetPredicate(
    (w) => w is EntityCard && w.title == _kProgramme,
  );
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: '"$_kProgramme" on the Programmes list',
  );
  tester.widget<EntityCard>(card.first).onTap!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(EventDetailsView).evaluate().isNotEmpty,
    description: 'the detail page of "$_kProgramme"',
  );
}

Future<void> _openEndDateDialog(WidgetTester tester) async {
  final action = find.widgetWithText(
    ShadButton,
    ProgrammeScheduleActions.adjustEndDateLabel,
  );
  await waitFor(
    tester,
    () => action.evaluate().isNotEmpty,
    description: 'the Adjust end date action in the Schedule block',
  );
  invokeShadButton(tester, action, reason: 'Adjust end date');
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(ProgrammeEndDateForm).evaluate().isNotEmpty,
    description: 'the Adjust end date dialog',
  );
}

ProgrammeEndDateFormState _form(WidgetTester tester) =>
    tester.state<ProgrammeEndDateFormState>(find.byType(ProgrammeEndDateForm));

/// Picks the last day [days] from today and checks the dialog states the
/// last session it gives.
Future<void> _pickLastDay(WidgetTester tester, int days) async {
  _form(tester).formKey.currentState!.setFieldValue<DateTime?>(
    ProgrammeEndDateFormFields.lastDayId,
    _localDay(days),
  );
  await tester.pump();
  final lastSession = programmeEndDayFormat.format(_localDay(days));
  expect(
    find.text('Last session: $lastSession.'),
    findsOneWidget,
    reason: 'the dialog shows the last session before saving',
  );
}

Future<void> _saveEndDate(WidgetTester tester) async {
  invokeShadButton(
    tester,
    find.descendant(
      of: find.byType(ProgrammeEndDateDialog),
      matching: find.widgetWithText(ShadButton, 'Save'),
    ),
    reason: 'Adjust end date Save',
  );
  await settle(tester);
  await _waitForDialogToClose(tester);
}

Future<void> _waitForDialogToClose(WidgetTester tester) async {
  await waitFor(
    tester,
    () {
      if (find.byType(ProgrammeEndDateForm).evaluate().isEmpty) return true;
      final refusal = _form(tester).formError;
      if (refusal != null) {
        throw TestFailure('the end date change was refused: "$refusal"');
      }
      return false;
    },
    description: 'the Adjust end date dialog to close',
  );
}

/// Waits for the Schedule block to show the end date [days] from today.
Future<void> _expectEndDateShown(WidgetTester tester, int days) async {
  final line = 'End date: ${programmeEndDayFormat.format(_localDay(days))}';
  await waitFor(
    tester,
    () => find.text(line).evaluate().isNotEmpty,
    description: '"$line" in the Schedule block',
  );
}
