// workflow_createprog: programmes for staff, per club (club_core#115).
//
// The example app's club.json runs camps and programmes, so staff see a
// Programs list beside Camps. This drives the programme side end to end:
//
//   * an admin (the super-admin `sudo`) creates a programme through the
//     Programs list's "+ New Program" form, and its schedule round-trips;
//   * the programme is listed under Programs, and its enrollment screen
//     opens from the card and resolves the programme (its title, not a bare
//     id) — the screen credit gating lives on;
//   * a coach sees the programme in Programs and its sessions in the staff
//     occurrence feed (Today / Club Calendar).
//
// Cleanup: the programme is soft-deleted via the master notifier (the create
// flow has no delete UI) and the coach via the admin UI.
//
// Recommended run (from the club_core root):
//   just app-test-one app_test_server1.conf \
//       workflow_createprog_programme_create_test.dart

import 'package:cl_club_events/src/views/event_enrolments_view.dart'
    show EventEnrolmentsView;
import 'package:cl_club_events/src/widgets/cards/event_card.dart'
    show EventCard;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider, clOccurrencesProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show EventType, Role;
import 'package:flutter/material.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers/auth.dart';
import '_helpers/enrollments.dart';
import '_helpers/events.dart';
import '_helpers/pump.dart';
import '_helpers/users.dart';
import '_helpers/venues.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

const _kPwd = 'workflow_createprog_pwd_1';
const _kCoach = 'workflow_createprog_coach';
const _kVenueName = 'workflow_createprog_venue';
const _kProgramme = 'workflow_createprog_programme';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  testWidgets(
    'an admin creates a programme via the UI; staff reach it from Programs, '
    'its enrollments and the occurrence feed',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── Phase 0: sudo creates a coach and a venue ─────────────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await createUserViaUi(tester, username: _kCoach, password: _kPwd);
      await grantRolesViaCheckboxViaUi(
        tester,
        username: _kCoach,
        roles: {Role.coach},
      );
      await createVenueViaUi(tester, name: _kVenueName);
      final venueId = await waitForVenueId(tester, _kVenueName);

      // ─── Phase 1: the admin creates a programme via the UI ─────────────
      await createEventViaUi(
        tester,
        type: EventType.programme,
        title: _kProgramme,
        venueId: venueId,
        weekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final programme = await waitForEvent(tester, _kProgramme);
      expect(programme.type, EventType.programme);
      expect(programme.venueId, venueId);
      expect(programme.rrule, contains('FREQ=WEEKLY'));
      expect(programme.rrule, contains('BYDAY=MO,TU,WE,TH,FR,SA,SU'));
      expect(
        programme.endTimeUtc.difference(programme.startTimeUtc).inMinutes,
        60,
        reason: 'the default session length is an hour',
      );
      expect(
        programme.startTimeUtc.isAfter(DateTime.now().toUtc()),
        isTrue,
        reason: 'the default start is the next whole hour',
      );

      // ─── Phase 2: its enrollment screen opens from the Programs list ───
      await navigateToEnrollmentManagementViaUi(
        tester,
        eventTitle: _kProgramme,
        eventTypeSegment: 'programmes',
      );
      expect(
        find.descendant(
          of: find.byType(EventEnrolmentsView),
          matching: find.text(_kProgramme),
        ),
        findsOneWidget,
        reason: 'the enrollment screen resolves the programme by id',
      );
      await logout(tester);

      // ─── Phase 3: a coach sees it in Programs and the occurrence feed ──
      await loginViaUi(tester, _kCoach, _kPwd);
      await go(tester, '/memberzone/events/programmes');
      await waitFor(
        tester,
        () => find
            .ancestor(
              of: find.text(_kProgramme),
              matching: find.byType(EventCard),
            )
            .evaluate()
            .isNotEmpty,
        description: "the programme on the coach's Programs list",
      );
      final key = (
        from: programme.startTimeUtc.subtract(const Duration(minutes: 1)),
        to: programme.startTimeUtc.add(const Duration(days: 1)),
      );
      final sub = container(
        tester,
      ).listen(clOccurrencesProvider(key), (_, _) {});
      addTearDown(sub.close);
      await waitFor(
        tester,
        () =>
            container(tester)
                .read(clOccurrencesProvider(key))
                .valueOrNull
                ?.any((o) => o.eventId == programme.id) ??
            false,
        description: "the programme's first session in the staff feed",
      );
      await logout(tester);

      // ─── Phase 4: cleanup ──────────────────────────────────────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await container(
        tester,
      ).read(clEventsMasterProvider.notifier).deleteEvent(programme.id);
      await waitFor(
        tester,
        () {
          final map = container(
            tester,
          ).read(clEventsMasterProvider).valueOrNull;
          final row = map?[programme.id];
          return map != null && (row == null || !row.isActive);
        },
        description: 'the programme to be soft-deleted',
      );
      await softDeleteUserViaUi(tester, _kCoach);
    },
  );
}
