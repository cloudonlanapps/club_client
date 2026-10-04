// workflow_createcamp: end-to-end coverage for the reintroduced camp create
// flow. Drives the create UI for two actors and asserts the
// server behavior the feature commits to:
//
//   * an admin (here the super-admin `sudo`) can create a camp via the UI;
//   * a coach can create a camp via the UI, and — since the create call sends
//     no organizer — the server makes the creator the organizer. So the
//     coach-created camp's `organizerName` is the coach. This is the
//     "creator becomes organizer" rule the app builds against: a coach
//     can manage (edit/enroll/attend) only the events they organize.
//
// The create affordance exercised is the camps-list "+ New Camp" button
// (`createEventViaUi`); the programme flow is workflow_createprog.
//
// Cleanup: both camps are soft-deleted via the master notifier (the create
// flow exposes no delete affordance) and the coach actor via the admin UI.
//
// Recommended run (from the club_core root):
//   just app-test-one app_test_server1.conf \
//       workflow_createcamp_camp_create_test.dart

import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Event, EventType, Role, Visibility;
import 'package:flutter/material.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers/auth.dart';
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

const _kPwd = 'workflow_createcamp_pwd_1';
const _kCoach = 'workflow_createcamp_coach';
const _kVenueName = 'workflow_createcamp_venue';
const _kAdminCamp = 'workflow_createcamp_admincamp';
const _kCoachCamp = 'workflow_createcamp_coachcamp';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  testWidgets(
    'admin and coach create a camp via the UI; the creator '
    'becomes the organizer',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── Phase 0: sudo creates a coach actor + a venue ─────────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await createUserViaUi(tester, username: _kCoach, password: _kPwd);
      await grantRolesViaCheckboxViaUi(
        tester,
        username: _kCoach,
        roles: {Role.coach},
      );
      await createVenueViaUi(tester, name: _kVenueName);
      final venueId = await waitForVenueId(tester, _kVenueName);

      // ─── Phase 1: super-admin creates a camp via the UI ────────────────
      await createEventViaUi(
        tester,
        type: EventType.camp,
        title: _kAdminCamp,
        venueId: venueId,
      );
      final adminCamp = await waitForEvent(tester, _kAdminCamp);
      expect(
        adminCamp.organizerName,
        _kSudoUsername,
        reason: 'creator (sudo) should be the default organizer',
      );
      // The form's fields must round-trip to the server, not just the title.
      _expectCampWired(adminCamp, venueId);
      await logout(tester);

      // ─── Phase 2: a coach creates a camp via the UI ────────────────────
      await loginViaUi(tester, _kCoach, _kPwd);
      await createEventViaUi(
        tester,
        type: EventType.camp,
        title: _kCoachCamp,
        venueId: venueId,
      );
      final coachCamp = await waitForEvent(tester, _kCoachCamp);
      expect(
        coachCamp.organizerName,
        _kCoach,
        reason: 'a coach who creates an event becomes its organizer',
      );
      _expectCampWired(coachCamp, venueId);
      await logout(tester);

      // ─── Phase 3: cleanup ──────────────────────────────────────────────
      // Super-admin can delete both camps (the create flow has no delete UI).
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      final notifier = container(tester).read(clEventsMasterProvider.notifier);
      await notifier.deleteEvent(adminCamp.id);
      await notifier.deleteEvent(coachCamp.id);
      await waitFor(
        tester,
        () {
          final map = container(
            tester,
          ).read(clEventsMasterProvider).valueOrNull;
          if (map == null) return false;
          final admin = map[adminCamp.id];
          final coach = map[coachCamp.id];
          return (admin == null || !admin.isActive) &&
              (coach == null || !coach.isActive);
        },
        description: 'both camps to be soft-deleted',
      );
      await softDeleteUserViaUi(tester, _kCoach);
    },
  );
}

/// Assert the form's non-title fields round-tripped to the server, so a
/// mis-mapping in the create adapter (venue, visibility, recurrence, duration)
/// is caught — not just the title. Values match the camp create seed:
/// 5 training days, 1.5h, public visibility.
void _expectCampWired(Event camp, int venueId) {
  expect(camp.type, EventType.camp, reason: 'type should be camp');
  expect(camp.venueId, venueId, reason: 'selected venue should round-trip');
  expect(
    camp.visibility,
    Visibility.public,
    reason: 'default visibility is public',
  );
  expect(camp.rrule, isNotNull, reason: 'a camp recurs');
  expect(
    camp.rrule,
    contains('FREQ=DAILY'),
    reason: 'camp recurrence is daily',
  );
  expect(
    camp.rrule,
    contains('COUNT=5'),
    reason: '5 training days, no rest days → COUNT=5',
  );
  expect(
    camp.endTimeUtc.difference(camp.startTimeUtc).inMinutes,
    90,
    reason: 'default duration is 1.5h',
  );
}
