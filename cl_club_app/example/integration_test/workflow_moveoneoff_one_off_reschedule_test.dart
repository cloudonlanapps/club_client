// workflow_moveoneoff: an admin moves a one-off to another day, time and
// venue from its Schedule block (club_client#37).
//
// A one-off is a single occurrence with no recurrence rule. Before it starts
// the server moves it in place (POST …/reschedule, later only, at least 30
// minutes ahead); once it has started only its timetable can be corrected.
//
// Setup (SDK, as the suite does for time-dependent fixtures): an admin, two
// venues, a two-hour one-off three days ahead and one that started an hour
// ago.
//
// Steps (UI):
//  1. The admin opens the upcoming one-off from the One-off Events list and
//     opens the Schedule block's editor: the one-off schedule form.
//  2. They move it two days later and an hour later in the day, to the other
//     venue, split into "Warm-up" (30 min) and "Match" (90 min), and save.
//  3. They open the started one-off: its Schedule block says its date and
//     times are fixed, and its editor is the timetable correction.
// Then the server is asked for the moved event and its occurrence: both
// moved, the venue and sessions changed, and it still has no rrule.
//
//   just app-test-one app_test_server1.conf \
//       workflow_moveoneoff_one_off_reschedule_test.dart

import 'package:cl_club_events/cl_club_events.dart' show EventDetailsView;
import 'package:cl_club_events/src/models/one_off_schedule_form_helpers.dart'
    show oneOffStartedMessage;
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventTimetableForm,
        OneOffScheduleData,
        OneOffScheduleForm,
        OneOffScheduleFormFields,
        OneOffScheduleFormState,
        SessionInput;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Event, EventType, Gender, SecureClient, Visibility;
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EntityCard;

import '_helpers/auth.dart';
import '_helpers/editors.dart';
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

const _kPwd = 'WorkflowMoveOneOffPwd!2026';
const _kAdmin = 'workflow_moveoneoff_admin';
const _kVenue = 'workflow_moveoneoff_venue';
const _kOtherVenue = 'workflow_moveoneoff_other_venue';
const _kUpcoming = 'workflow_moveoneoff_upcoming';
const _kStarted = 'workflow_moveoneoff_started';

/// The one-off's length, which the sessions add up to.
const _kLength = Duration(hours: 2);

/// The local hour the upcoming one-off starts at, and the one it moves to.
const _kStartHour = 10;
const _kMovedHour = 11;

/// The split the admin gives the moved one-off: 30 + 90 minutes.
const List<SessionInput> _kSplit = [
  SessionInput(name: 'Warm-up', startTime: '11:00', endTime: '11:30'),
  SessionInput(name: 'Match', startTime: '11:30', endTime: '13:00'),
];

/// Local [hour] o'clock, [days] from today.
DateTime _localDay(int days, int hour) {
  final t = DateTime.now().add(Duration(days: days));
  return DateTime(t.year, t.month, t.day, hour);
}

Future<SecureClient> _sudoClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

late int _venueId;
late int _otherVenueId;
late Event _upcoming;
late Event _started;

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
      firstName: 'WMoveOneOff',
      lastName: 'admin',
      phone: '7400543210',
      email: '$_kAdmin@example.com',
      gender: Gender.preferNotToSay,
      dateOfBirthUtc: DateTime.utc(2000, 1, 1),
    );
    await client.users.assignRole(_kAdmin, 'admin');
    _venueId = (await client.venues.createVenue(name: _kVenue)).id;
    _otherVenueId = (await client.venues.createVenue(name: _kOtherVenue)).id;
    final upcomingStart = _localDay(3, _kStartHour).toUtc();
    _upcoming = await client.events.createEvent(
      title: _kUpcoming,
      description: 'workflow_moveoneoff upcoming one-off',
      type: EventType.oneOff,
      visibility: Visibility.public,
      venueId: _venueId,
      startTimeUtc: upcomingStart,
      endTimeUtc: upcomingStart.add(_kLength),
      organizerName: _kAdmin,
    );
    final now = DateTime.now().toUtc();
    final startedStart = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
    ).subtract(const Duration(hours: 1));
    _started = await client.events.createEvent(
      title: _kStarted,
      description: 'workflow_moveoneoff started one-off',
      type: EventType.oneOff,
      visibility: Visibility.public,
      venueId: _venueId,
      startTimeUtc: startedStart,
      endTimeUtc: startedStart.add(_kLength),
      organizerName: _kAdmin,
    );
    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _sudoClient();
    for (final id in [_upcoming.id, _started.id]) {
      try {
        await client.events.deleteEvent(id);
      } on Object catch (_) {}
    }
    // A leftover venue pushes later tests' venues down the lazy list.
    for (final id in [_venueId, _otherVenueId]) {
      try {
        await client.venues.deleteVenue(id);
      } on Object catch (_) {}
    }
    try {
      await client.users.deleteUser(_kAdmin);
    } on Object catch (_) {}
    await client.auth.logout();
  });

  testWidgets(
    'Issue 37: an admin moves an upcoming one-off to another day, time and '
    'venue; a started one-off keeps its date and corrects its timetable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kAdmin, _kPwd);

      // ─── 1. The upcoming one-off opens its whole schedule ─────────────
      await _openDetail(tester, title: _kUpcoming);
      await tapSectionPencil(tester, _scheduleCard);
      await waitFor(
        tester,
        () => find.byType(OneOffScheduleForm).evaluate().isNotEmpty,
        description: 'the one-off schedule editor',
      );
      expect(
        find.text('Days of Week'),
        findsNothing,
        reason: 'a one-off has no recurrence to edit',
      );

      // ─── 2. Two days later, an hour later, the other venue, split ─────
      final moved = _localDay(5, _kMovedHour);
      tester
            .state<OneOffScheduleFormState>(find.byType(OneOffScheduleForm))
            .formKey
            .currentState!
        ..setFieldValue<OneOffScheduleData>(
          OneOffScheduleFormFields.scheduleId,
          OneOffScheduleData(
            date: DateTime(moved.year, moved.month, moved.day),
            startTime: const ShadTimeOfDay(
              hour: _kMovedHour,
              minute: 0,
              second: 0,
            ),
            durationMinutes: _kLength.inMinutes,
          ),
        )
        ..setFieldValue<int>(OneOffScheduleFormFields.venueId, _otherVenueId)
        ..setFieldValue<List<SessionInput>>(
          OneOffScheduleFormFields.sessionsId,
          _kSplit,
        );
      await tester.pump();
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () => find.byType(OneOffScheduleForm).evaluate().isEmpty,
        description: 'the schedule editor to close after saving',
      );
      await waitFor(
        tester,
        () =>
            container(tester)
                .read(clEventsMasterProvider)
                .valueOrNull?[_upcoming.id]
                ?.startTimeUtc ==
            moved.toUtc(),
        description: 'the moved one-off in the events master',
      );

      // ─── 3. The started one-off: locked, timetable only ───────────────
      await _openDetail(tester, title: _kStarted);
      expect(
        find.text(oneOffStartedMessage),
        findsOneWidget,
        reason: 'the Schedule block says why the date and times are fixed',
      );
      await tapSectionPencil(tester, _scheduleCard);
      await waitFor(
        tester,
        () => find.byType(EventTimetableForm).evaluate().isNotEmpty,
        description: 'the timetable editor of the started one-off',
      );
      expect(find.byType(OneOffScheduleForm), findsNothing);
      await cancelInlineEditor(tester);
      await logout(tester);

      // ─── The server moved the event and its single occurrence ─────────
      final client = await _sudoClient();
      final event = await client.events.getEvent(_upcoming.id);
      final occurrence = await client.occurrences.getOccurrence(
        _upcoming.id,
        moved.toUtc(),
      );
      await client.auth.logout();

      expect(event.startTimeUtc, moved.toUtc());
      expect(event.endTimeUtc, moved.toUtc().add(_kLength));
      expect(event.venueId, _otherVenueId);
      expect(event.rrule, isNull, reason: 'a one-off does not recur');
      expect(event.sessions?.map((s) => (s.name, s.periodMinutes)), [
        ('Warm-up', 30),
        ('Match', 90),
      ]);
      expect(event.version, greaterThan(_upcoming.version));
      expect(occurrence.actualStartTimeUtc, moved.toUtc());
      expect(occurrence.venueId, _otherVenueId);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// The Schedule block's card on the open detail page.
final Finder _scheduleCard = find.ancestor(
  of: find.text('Schedule'),
  matching: find.byType(ShadCard),
);

/// Opens the one-off titled [title] from the One-off Events list, as an
/// admin does.
Future<void> _openDetail(WidgetTester tester, {required String title}) async {
  await go(tester, '/memberzone/events/one-off');
  final card = find.byWidgetPredicate(
    (w) => w is EntityCard && w.title == title,
  );
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: '"$title" on the One-off Events list',
  );
  tester.widget<EntityCard>(card.first).onTap!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(EventDetailsView).evaluate().isNotEmpty,
    description: 'the detail page of "$title"',
  );
}
