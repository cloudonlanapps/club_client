// workflow_adjustprog: an admin adjusts a running programme's schedule from
// a chosen upcoming session onward (club_client#38).
//
// The server changes a programme's schedule by splitting it at a session
// start (PATCH …/future): the terms up to then stand, and new terms apply
// from then on.
//
// Setup (SDK, as the suite does for time-dependent fixtures): an admin, two
// venues, and a one-hour programme held every day at local noon since ten
// days ago.
//
// Steps (UI):
//  1. The admin opens the programme from the Programmes list and taps Adjust
//     Schedule in its Schedule block: the editor opens on the present
//     schedule, from the next session.
//  2. They pick the third upcoming session as From, change the days to
//     Tuesday and Saturday, the start to 14:00 and the venue, and save.
//  3. The Schedule block says when the new schedule starts.
// Then the server is asked for the programme's schedules and sessions: the
// sessions before From kept their day, time and venue, and the sessions
// from it follow the new schedule.
//
//   just app-test-one app_test_server1.conf \
//       workflow_adjustprog_programme_adjust_schedule_test.dart

import 'package:cl_club_events/cl_club_events.dart' show EventDetailsView;
import 'package:cl_club_events/src/widgets/event_editor/programme_adjust_schedule_dialog.dart'
    show ProgrammeAdjustScheduleDialog;
import 'package:cl_club_events/src/widgets/event_editor/programme_schedule_actions.dart'
    show ProgrammeScheduleActions;
import 'package:cl_club_events/src/widgets/event_editor/programme_schedule_read.dart'
    show programmeNextScheduleLine;
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ProgrammeScheduleAdjustForm,
        ProgrammeScheduleAdjustFormFields,
        ProgrammeScheduleAdjustFormState,
        ProgrammeScheduleData;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Event, EventType, Gender, SecureClient, Visibility;
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

const _kPwd = 'WorkflowAdjustProgPwd!2026';
const _kAdmin = 'workflow_adjustprog_admin';
const _kVenue = 'workflow_adjustprog_venue';
const _kOtherVenue = 'workflow_adjustprog_other_venue';
const _kProgramme = 'workflow_adjustprog_programme';

/// The local hour of a session before and after the adjustment.
const _kHour = 12;
const _kNewHour = 14;

/// The days the adjusted schedule runs on.
const Set<int> _kNewDays = {DateTime.tuesday, DateTime.saturday};

/// Which upcoming session the new schedule starts from (the third).
const _kFromIndex = 2;

Future<SecureClient> _sudoClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

late int _venueId;
late int _otherVenueId;
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
      firstName: 'WAdjustProg',
      lastName: 'admin',
      phone: '7400543210',
      email: '$_kAdmin@example.com',
      gender: Gender.preferNotToSay,
      dateOfBirthUtc: DateTime.utc(2000, 1, 1),
    );
    await client.users.assignRole(_kAdmin, 'admin');
    _venueId = (await client.venues.createVenue(name: _kVenue)).id;
    _otherVenueId = (await client.venues.createVenue(name: _kOtherVenue)).id;
    final day = DateTime.now().subtract(const Duration(days: 10));
    final start = DateTime(day.year, day.month, day.day, _kHour).toUtc();
    _programme = await client.events.createEvent(
      title: _kProgramme,
      description: 'workflow_adjustprog programme',
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
    "Issue 38: an admin adjusts a programme's days, time and venue from a "
    'chosen upcoming session; earlier sessions keep the present schedule',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kAdmin, _kPwd);

      // ─── 1. Adjust Schedule opens on the present schedule ─────────────
      await _openDetail(tester, title: _kProgramme);
      final action = find.widgetWithText(
        ShadButton,
        ProgrammeScheduleActions.adjustScheduleLabel,
      );
      await waitFor(
        tester,
        () => action.evaluate().isNotEmpty,
        description: 'the Adjust Schedule action in the Schedule block',
      );
      invokeShadButton(tester, action, reason: 'Adjust Schedule');
      await settle(tester);
      await waitFor(
        tester,
        () => find.byType(ProgrammeScheduleAdjustForm).evaluate().isNotEmpty,
        description: 'the Adjust Schedule dialog',
      );
      final form = tester.state<ProgrammeScheduleAdjustFormState>(
        find.byType(ProgrammeScheduleAdjustForm),
      );
      final options = form.widget.fromOptions;
      expect(
        options.length,
        greaterThan(_kFromIndex),
        reason: 'a daily programme has upcoming sessions to start from',
      );
      for (final option in options) {
        expect(
          option.toLocal().hour,
          _kHour,
          reason: 'only session starts of the present schedule are offered',
        );
      }
      expect(form.currentValue.from, options.first);
      expect(form.currentValue.schedule.weekdays, hasLength(7));
      expect(form.currentValue.venueId, _venueId);

      // ─── 2. From the third session: Tue + Sat, 14:00, the other venue ─
      final from = options[_kFromIndex];
      form.formKey.currentState!
        ..setFieldValue<DateTime>(
          ProgrammeScheduleAdjustFormFields.fromId,
          from,
        )
        ..setFieldValue<ProgrammeScheduleData>(
          ProgrammeScheduleAdjustFormFields.scheduleId,
          form.widget.initialValue.schedule.copyWith(
            weekdays: _kNewDays,
            sessionStartTime: () =>
                const ShadTimeOfDay(hour: _kNewHour, minute: 0, second: 0),
          ),
        )
        ..setFieldValue<int>(
          ProgrammeScheduleAdjustFormFields.venueId,
          _otherVenueId,
        );
      await tester.pump();
      expect(
        find.text(ProgrammeScheduleAdjustForm.effectLine(from)),
        findsOneWidget,
        reason: 'the dialog says what saving does',
      );
      invokeShadButton(
        tester,
        find.descendant(
          of: find.byType(ProgrammeAdjustScheduleDialog),
          matching: find.widgetWithText(ShadButton, 'Save'),
        ),
        reason: 'Adjust Schedule Save',
      );
      await settle(tester);
      await waitFor(
        tester,
        () {
          final open = find.byType(ProgrammeScheduleAdjustForm).evaluate();
          if (open.isEmpty) return true;
          final refusal = tester
              .state<ProgrammeScheduleAdjustFormState>(
                find.byType(ProgrammeScheduleAdjustForm),
              )
              .formError;
          if (refusal != null) {
            throw TestFailure('the adjustment was refused: "$refusal"');
          }
          return false;
        },
        description: 'the Adjust Schedule dialog to close after saving',
      );

      // ─── 3. The block says when the new schedule starts ───────────────
      await waitFor(
        tester,
        () => find.text(programmeNextScheduleLine(from)).evaluate().isNotEmpty,
        description: 'the pending-change line in the Schedule block',
      );
      await logout(tester);

      // ─── The server split the programme at From ───────────────────────
      final client = await _sudoClient();
      final schedules = await client.events.listSchedules(_programme.id);
      final sessions = (await client.occurrences.listOccurrences(
        fromTimeUtc: DateTime.now().toUtc(),
        toTimeUtc: from.add(const Duration(days: 14)),
        eventType: EventType.programme,
      )).where((o) => o.eventId == _programme.id).toList();
      await client.auth.logout();

      expect(schedules, hasLength(2), reason: 'one split');
      expect(schedules.first.effectiveUntilUtc, from);
      expect(schedules.last.effectiveFromUtc, from);
      expect(schedules.last.venueId, _otherVenueId);

      final before = sessions.where(
        (o) => o.originalStartTimeUtc.isBefore(from),
      );
      final after = sessions.where(
        (o) => !o.originalStartTimeUtc.isBefore(from),
      );
      expect(
        before,
        isNotEmpty,
        reason: 'sessions before From are still in the calendar',
      );
      for (final o in before) {
        expect(o.originalStartTimeUtc.toLocal().hour, _kHour);
        expect(o.venueId, _venueId, reason: 'unchanged before From');
      }
      expect(after, isNotEmpty, reason: 'sessions follow the new schedule');
      for (final o in after) {
        final local = o.originalStartTimeUtc.toLocal();
        expect(local.hour, _kNewHour);
        expect(_kNewDays, contains(local.weekday));
        expect(o.venueId, _otherVenueId);
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// Opens the programme titled [title] from the Programmes list, as an admin
/// does.
Future<void> _openDetail(WidgetTester tester, {required String title}) async {
  await go(tester, '/memberzone/events/programmes');
  final card = find.byWidgetPredicate(
    (w) => w is EntityCard && w.title == title,
  );
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: '"$title" on the Programmes list',
  );
  tester.widget<EntityCard>(card.first).onTap!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(EventDetailsView).evaluate().isNotEmpty,
    description: 'the detail page of "$title"',
  );
}
