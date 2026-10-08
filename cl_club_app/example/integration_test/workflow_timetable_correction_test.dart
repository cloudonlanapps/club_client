// workflow_timetable: an admin corrects the timetable of a camp and of a
// programme that have already started (club_core#85).
//
// A timetable is how each occurrence is split into named sessions. The
// server lets it be corrected at any time, since a correction moves no date
// (club_server#423): a camp's through updateEvent(sessions:), a
// programme's through correctionOnEvent(sessions:, scheduleId:). Before
// #85 the camp editor sent every change through rescheduleEvent, which
// the server refuses once the camp has started.
//
// Setup (SDK, as the suite does for time-dependent fixtures): an admin, a
// venue, a 5-day camp whose first day was yesterday and a daily programme
// whose first session was ten days ago, each two hours long.
//
// Steps (UI), for the camp and then the programme:
//  1. The admin opens the event from its staff list; the Schedule section
//     offers the timetable editor (for the camp, with a note that its dates
//     are fixed).
//  2. They split the day into "Warm-up" (30 min) and "Drills" (90 min) and
//     save.
// Then the server is asked for the event: the sessions are corrected, the
// dates did not move, and the programme was corrected in place, not split.
//
// Runs on both confs:
//   just app-test-one app_test_server1.conf \
//       workflow_timetable_correction_test.dart
//   just app-test-one app_test_server2.conf \
//       workflow_timetable_correction_test.dart

import 'package:cl_club_events/cl_club_events.dart' show EventDetailsView;
import 'package:cl_club_events/src/models/camp_schedule_form_helpers.dart'
    show campStartedMessage;
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventTimetableForm,
        EventTimetableFormFields,
        EventTimetableFormState,
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

const _kPwd = 'WorkflowTimetablePwd!2026';
const _kAdmin = 'workflow_timetable_admin';
const _kVenue = 'workflow_timetable_venue';
const _kCamp = 'workflow_timetable_camp';
const _kProgramme = 'workflow_timetable_programme';

/// Each occurrence's length, which the corrected sessions add up to.
const _kOccurrence = Duration(hours: 2);

/// The corrected split: 30 + 90 minutes.
const List<SessionInput> _kSplit = [
  SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '06:30'),
  SessionInput(name: 'Drills', startTime: '06:30', endTime: '08:00'),
];

Future<SecureClient> _sudoClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

late int _venueId;
late Event _camp;
late Event _programme;

/// [days] before now, on the hour, in UTC.
DateTime _daysAgo(int days) {
  final t = DateTime.now().toUtc().subtract(Duration(days: days));
  return DateTime.utc(t.year, t.month, t.day, t.hour);
}

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
      firstName: 'WTimetable',
      lastName: 'admin',
      phone: '7400543210',
      email: '$_kAdmin@example.com',
      gender: Gender.preferNotToSay,
      dateOfBirthUtc: DateTime.utc(2000, 1, 1),
    );
    await client.users.assignRole(_kAdmin, 'admin');
    final venue = await client.venues.createVenue(name: _kVenue);
    _venueId = venue.id;
    final campStart = _daysAgo(1);
    _camp = await client.events.createEvent(
      title: _kCamp,
      description: 'workflow_timetable camp',
      type: EventType.camp,
      visibility: Visibility.public,
      venueId: venue.id,
      startTimeUtc: campStart,
      endTimeUtc: campStart.add(_kOccurrence),
      organizerName: _kAdmin,
      rrule: 'FREQ=DAILY;COUNT=5',
    );
    final programmeStart = _daysAgo(10);
    _programme = await client.events.createEvent(
      title: _kProgramme,
      description: 'workflow_timetable programme',
      type: EventType.programme,
      visibility: Visibility.public,
      venueId: venue.id,
      startTimeUtc: programmeStart,
      endTimeUtc: programmeStart.add(_kOccurrence),
      organizerName: _kAdmin,
      rrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU',
    );
    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _sudoClient();
    for (final id in [_camp.id, _programme.id]) {
      try {
        await client.events.deleteEvent(id);
      } on Object catch (_) {}
    }
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
    'Issue 85: an admin corrects the timetable of a started camp and of a '
    'started programme, and no date moves',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kAdmin, _kPwd);

      // ─── 1. The started camp: its dates are fixed, its timetable is not ─
      await _openDetail(tester, list: 'camps', title: _kCamp);
      expect(
        find.text(campStartedMessage),
        findsOneWidget,
        reason: 'the Schedule section says only the timetable can change',
      );
      await _correctTimetable(tester);
      await waitFor(
        tester,
        () => _sessionsOf(tester, _camp.id) == '30,90',
        description: "the camp's corrected sessions in the events master",
      );

      // ─── 2. The started programme: corrected in place ─────────────────
      await _openDetail(tester, list: 'programmes', title: _kProgramme);
      await _correctTimetable(tester);
      await waitFor(
        tester,
        () => _sessionsOf(tester, _programme.id) == '30,90',
        description: "the programme's corrected sessions in the master",
      );
      await logout(tester);

      // ─── The server holds the corrections, and nothing moved ──────────
      final client = await _sudoClient();
      final camp = await client.events.getEvent(_camp.id);
      final programme = await client.events.getEvent(_programme.id);
      final schedules = await client.events.listSchedules(_programme.id);
      await client.auth.logout();

      for (final (before, after) in [(_camp, camp), (_programme, programme)]) {
        expect(after.sessions?.map((s) => (s.name, s.periodMinutes)), [
          ('Warm-up', 30),
          ('Drills', 90),
        ], reason: '${before.title} carries the corrected timetable');
        expect(after.startTimeUtc, before.startTimeUtc);
        expect(after.endTimeUtc, before.endTimeUtc);
        expect(after.rrule, before.rrule, reason: 'no date moved');
      }
      expect(
        schedules,
        hasLength(1),
        reason: 'the programme was corrected in place, not split',
      );
      expect(schedules.single.sessions?.length, 2);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// Opens the event titled [title] from the staff [list] (`camps`,
/// `programmes`), as an admin does.
Future<void> _openDetail(
  WidgetTester tester, {
  required String list,
  required String title,
}) async {
  await go(tester, '/memberzone/events/$list');
  final card = find.byWidgetPredicate(
    (w) => w is EntityCard && w.title == title,
  );
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: '"$title" on the $list list',
  );
  tester.widget<EntityCard>(card.first).onTap!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(EventDetailsView).evaluate().isNotEmpty,
    description: 'the detail page of "$title"',
  );
}

/// Opens the Schedule section's timetable editor, splits the day into
/// [_kSplit] and saves.
Future<void> _correctTimetable(WidgetTester tester) async {
  await tapSectionPencil(
    tester,
    find.ancestor(of: find.text('Schedule'), matching: find.byType(ShadCard)),
  );
  await waitFor(
    tester,
    () => find.byType(EventTimetableForm).evaluate().isNotEmpty,
    description: 'the timetable editor',
  );
  tester
      .state<EventTimetableFormState>(find.byType(EventTimetableForm))
      .formKey
      .currentState!
      .setFieldValue<List<SessionInput>>(
        EventTimetableFormFields.sessionsId,
        _kSplit,
      );
  await tester.pump();
  await saveInlineEditor(tester);
  await waitFor(
    tester,
    () => find.byType(EventTimetableForm).evaluate().isEmpty,
    description: 'the timetable editor to close after saving',
  );
}

/// The session lengths of event [id] in the events master, e.g. `30,90`.
String? _sessionsOf(WidgetTester tester, int id) => container(tester)
    .read(clEventsMasterProvider)
    .valueOrNull?[id]
    ?.sessions
    ?.map((s) => s.periodMinutes)
    .join(',');
