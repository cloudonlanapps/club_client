// workflow_createoneoff: one-off events for staff, per club (club_core#122).
//
// The example app's club.json runs camps, programmes and one-off events, so
// staff see a One-Off Events list. This drives the one-off side:
//
//   * an admin (the super-admin `sudo`) creates a one-off event through the
//     One-Off Events list's "+ New Event" form (the schedule keeps its
//     seeded default: the next hour);
//   * the event is listed under One-Off Events, and its enrollment screen
//     opens from the card and resolves it by id.
//
// Cleanup: the event is soft-deleted via the master notifier (the create
// flow has no delete UI).
//
// Recommended run (from the club_core root):
//   just app-test-one app_test_server1.conf \
//       workflow_createoneoff_one_off_create_test.dart

import 'package:cl_club_events/src/views/event_enrolments_view.dart'
    show EventEnrolmentsView;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers/auth.dart';
import '_helpers/enrollments.dart';
import '_helpers/events.dart';
import '_helpers/pump.dart';
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

const _kVenueName = 'workflow_createoneoff_venue';
const _kOneOff = 'workflow_createoneoff_event';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  testWidgets(
    'an admin creates a one-off event via the UI and reaches its '
    'enrollments from One-Off Events',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await createVenueViaUi(tester, name: _kVenueName);
      final venueId = await waitForVenueId(tester, _kVenueName);

      // ─── The admin creates a one-off event via the UI ──────────────────
      await createEventViaUi(
        tester,
        type: EventType.oneOff,
        title: _kOneOff,
        venueId: venueId,
      );
      final oneOff = await waitForEvent(tester, _kOneOff);
      expect(oneOff.type, EventType.oneOff);
      expect(oneOff.venueId, venueId);
      expect(oneOff.rrule, isNull, reason: 'a one-off does not recur');

      // ─── Its enrollment screen opens from One-Off Events ───────────────
      await navigateToEnrollmentManagementViaUi(
        tester,
        eventTitle: _kOneOff,
        eventTypeSegment: 'one-off',
      );
      expect(
        find.descendant(
          of: find.byType(EventEnrolmentsView),
          matching: find.text(_kOneOff),
        ),
        findsOneWidget,
        reason: 'the enrollment screen resolves the one-off by id',
      );

      // ─── Cleanup ───────────────────────────────────────────────────────
      await container(
        tester,
      ).read(clEventsMasterProvider.notifier).deleteEvent(oneOff.id);
      await waitFor(
        tester,
        () {
          final map = container(
            tester,
          ).read(clEventsMasterProvider).valueOrNull;
          final row = map?[oneOff.id];
          return map != null && (row == null || !row.isActive);
        },
        description: 'the one-off event to be soft-deleted',
      );
      await logout(tester);
    },
  );
}
