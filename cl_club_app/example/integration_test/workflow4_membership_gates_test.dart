// workflow4: integration coverage for the MembershipShim UI gates, on the
// redesigned enrolment and dashboard surfaces.
//
// The shim's default resolver treats every authenticated user as a member, so
// each test installs a resolver that answers [_actingIsMember], set before
// each login, so both gate branches run. The server has no `member` role to
// grant any more (club_server#400), so membership cannot come from roles.
//
// Gates:
//   1. The dashboard's Public Events panel shows the "Enroll" action for a
//      member and hides it for a non-member — the occurrence row resolves its
//      trailing action through EnrollmentActionButtons / UserOccurrenceActions,
//      which gate on `MembershipShim.isMember`.
//   3. A non-member WITH an enrollment still reaches the expanded MyEvents
//      body.
//   4. A fresh non-member with no events collapses the MyEvents body.
//
// (The original gate 2 — "admin invite picker filters non-members" — is
// retired. The redesigned invite picker reads the server's authoritative
// eligible-users list with its client-side role filter disabled, so it no
// longer branches on MembershipShim; the admin invite affordance itself is
// covered by workflow5.)
//
// Fixtures (all prefixed `workflow4_` per the integration-test naming rule):
//   * workflow4_member    — active user the resolver treats as a member.
//   * workflow4_nonmember — active user, no roles (negative branch of gate 1).
//   * workflow4_enrolled  — active user, no roles (gate 3 enrolment).
//   * workflow4_venue     — venue carrying every test event.
//
// Events are created per test (not in setUpAll) so gate 4 can run against a
// world with zero public events — a single public event auto-populates
// `clMyEventsMasterProvider` for every user and would mask the gate.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//       workflow4_membership_gates_test.dart

import 'package:cl_member_zone/src/providers/selected_day.dart'
    show selectedDayProvider;
import 'package:cl_member_zone/src/widgets/panels/my_events_panel_body.dart'
    show MyEventsPanelBody;
import 'package:cl_member_zone/src/widgets/panels/public_events_panel_body.dart'
    show PublicEventsPanelBody;
import 'package:cl_member_zone/src/widgets/panels/shared/day_occurrences_list.dart'
    show DayOccurrencesList;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import '_helpers/auth.dart';
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

const _kMember = 'workflow4_member';
const _kNonmember = 'workflow4_nonmember';
const _kEnrolled = 'workflow4_enrolled';
const _kPwd = 'Workflow4Pwd!2024';

/// What the installed resolver answers for whoever is logged in.
var _actingIsMember = false;

late int _venueId;

Future<SecureClient> _adminClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

/// Creates a one-off event starting an hour from now, and returns its id and
/// the local day it falls on.
///
/// The dashboard panels show a single day, today. Late in the evening an
/// hour from now is already tomorrow (club_core#87), so a gate pins the
/// panels to that day with [_dayOverride] rather than assume today.
Future<({int id, DateTime day})> _createEvent({
  required SecureClient client,
  required String title,
  required Visibility visibility,
}) async {
  final start = DateTime.now().toUtc().add(const Duration(hours: 1));
  final event = await client.events.createEvent(
    title: title,
    description: 'Workflow4 test event',
    type: EventType.oneOff,
    visibility: visibility,
    venueId: _venueId,
    startTimeUtc: start,
    endTimeUtc: start.add(const Duration(hours: 2)),
  );
  final local = start.toLocal();
  return (id: event.id, day: DateTime(local.year, local.month, local.day));
}

/// Shows the dashboard panels for [day] instead of today.
Override _dayOverride(DateTime day) =>
    selectedDayProvider.overrideWithValue(day);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env). '
      'Source: `pass club/dev/bootstrap/sudo`.',
    );
  }

  setUpAll(() async {
    final client = await _adminClient();

    final venue = await client.venues.createVenue(
      name: 'workflow4_venue',
      address: 'Workflow 4 Test Rink',
    );
    _venueId = venue.id;

    for (final u in [_kMember, _kNonmember, _kEnrolled]) {
      await client.users.createUser(
        username: u,
        passwordHash: _kPwd,
        firstName: 'WF4',
        lastName: u.substring('workflow4_'.length),
        phone: '9876543210',
        email: '$u@example.com',
        gender: Gender.preferNotToSay,
        dateOfBirthUtc: DateTime.utc(1990, 1, 1),
      );
    }
    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _adminClient();
    for (final u in [_kMember, _kNonmember, _kEnrolled]) {
      try {
        await client.users.deleteUser(u);
      } on Object catch (_) {
        /* best-effort */
      }
    }
    try {
      await client.venues.deleteVenue(_venueId);
    } on Object catch (_) {}
    await client.auth.logout();
  });

  setUp(() {
    _actingIsMember = false;
    MembershipShim.overrideResolver((_) => _actingIsMember);
  });

  tearDown(() {
    MembershipShim.overrideResolver(null);
  });

  // -------------------------------------------------------------------------
  // Gate 4 runs first: with no events anywhere, the fresh non-member's
  // `clMyEventsMasterProvider` is guaranteed empty. (The server's
  // `list_user_events` returns "enrolled OR public" — a single public event
  // would silently populate the panel for every user and mask the gate.)
  // -------------------------------------------------------------------------
  testWidgets(
    'gate 4: fresh non-member collapses MyEventsPanelBody',
    (tester) async {
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      await loginViaUi(tester, _kNonmember, _kPwd);
      expect(currentUser(tester), isNotNull);

      container(tester).read(clMyEventsMasterProvider(_kNonmember));
      await go(tester, '/memberzone');

      await waitFor(
        tester,
        () => !container(
          tester,
        ).read(clMyEventsMasterProvider(_kNonmember)).isLoading,
        description: 'clMyEventsMasterProvider to settle for fresh non-member',
      );

      final master = container(
        tester,
      ).read(clMyEventsMasterProvider(_kNonmember));
      expect(
        master.valueOrNull ?? const <Event>[],
        isEmpty,
        reason: 'fresh non-member must not have any enrollments',
      );

      // With `MembershipShim.isMember` false AND zero events the body
      // collapses to SizedBox.shrink — so MyEventsPanelBody must NOT have a
      // DayOccurrencesList descendant.
      expect(
        find.byType(MyEventsPanelBody),
        findsOneWidget,
        reason: 'My Events panel widget must be on the dashboard',
      );
      expect(
        find.descendant(
          of: find.byType(MyEventsPanelBody),
          matching: find.byType(DayOccurrencesList),
        ),
        findsNothing,
        reason:
            'fresh non-member should see MyEvents body collapse to '
            'SizedBox.shrink — no DayOccurrencesList inside MyEventsPanelBody',
      );

      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  testWidgets(
    'gate 3: non-member with enrollments still sees MyEventsPanelBody',
    (tester) async {
      // Per-test event: private (not public) so its existence doesn't bleed
      // into other gates' assumptions.
      final admin = await _adminClient();
      final event = await _createEvent(
        client: admin,
        title: 'workflow4_event_g3',
        visibility: Visibility.private,
      );
      await admin.enrollments.assign(event.id, _kEnrolled);
      await admin.auth.logout();

      try {
        await pumpApp(
          tester,
          apiBaseUrl: _kApiBaseUrl,
          extraOverrides: [_dayOverride(event.day)],
        );
        await ensureLoggedOut(tester);
        await loginViaUi(tester, _kEnrolled, _kPwd);

        container(tester).read(clMyEventsMasterProvider(_kEnrolled));
        await go(tester, '/memberzone');

        await waitFor(
          tester,
          () {
            final m = container(
              tester,
            ).read(clMyEventsMasterProvider(_kEnrolled));
            final v = m.valueOrNull;
            return v != null && v.isNotEmpty;
          },
          description: 'clMyEventsMasterProvider to load with the enrollment',
        );

        // Non-member-with-enrollments path reaches the expanded body, which
        // means a DayOccurrencesList descendant of MyEventsPanelBody.
        expect(find.byType(MyEventsPanelBody), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(MyEventsPanelBody),
            matching: find.byType(DayOccurrencesList),
          ),
          findsOneWidget,
          reason:
              'non-member with enrollments should see the expanded '
              'MyEvents body (DayOccurrencesList rendered), not '
              'SizedBox.shrink',
        );

        await logout(tester);
      } finally {
        final cleanup = await _adminClient();
        try {
          await cleanup.events.deleteEvent(event.id);
        } on Object catch (_) {}
        await cleanup.auth.logout();
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  testWidgets(
    'gate 1: member sees the Enroll action on the public panel, non-member '
    'does not',
    (tester) async {
      final admin = await _adminClient();
      final event = await _createEvent(
        client: admin,
        title: 'workflow4_event_g1',
        visibility: Visibility.public,
      );
      await admin.auth.logout();

      try {
        // --- member branch (positive control) ---
        await pumpApp(
          tester,
          apiBaseUrl: _kApiBaseUrl,
          extraOverrides: [_dayOverride(event.day)],
        );
        await ensureLoggedOut(tester);
        _actingIsMember = true;
        await loginViaUi(tester, _kMember, _kPwd);

        // The public event surfaces in the dashboard's Public Events panel,
        // whose occurrence row resolves its trailing action through
        // UserOccurrenceActions — which renders the "Enroll" action only when
        // MembershipShim.isMember is true. A member therefore sees it.
        await go(tester, '/memberzone');
        await _waitForPublicEventRow(tester, eventTitle: 'workflow4_event_g1');
        await waitFor(
          tester,
          () => _enrollActionInPublicPanel().evaluate().isNotEmpty,
          description: '"Enroll" action to render for the member',
          timeout: const Duration(seconds: 30),
        );

        // --- non-member branch ---
        await logout(tester);
        _actingIsMember = false;
        await loginViaUi(tester, _kNonmember, _kPwd);
        await go(tester, '/memberzone');
        await _waitForPublicEventRow(tester, eventTitle: 'workflow4_event_g1');
        // Let the row's action area resolve (it renders nothing while the
        // enrollment/event providers load) before asserting the action is
        // absent.
        await tester.pump(const Duration(seconds: 2));
        await settle(tester);
        expect(
          _enrollActionInPublicPanel(),
          findsNothing,
          reason:
              'UserOccurrenceActions must hide the "Enroll" action for a '
              'non-member',
        );

        await logout(tester);
      } finally {
        final cleanup = await _adminClient();
        try {
          await cleanup.events.deleteEvent(event.id);
        } on Object catch (_) {}
        await cleanup.auth.logout();
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

/// Finder for the "Enroll" action scoped to the dashboard's Public Events
/// panel (the occurrence row resolves it via UserOccurrenceActions). Scoping
/// guards against unrelated buttons elsewhere on the dashboard.
Finder _enrollActionInPublicPanel() => find.descendant(
  of: find.byType(PublicEventsPanelBody),
  matching: find.widgetWithText(ActionButton, 'Enroll'),
);

/// Waits for the Public Events panel to mount and render the row for
/// [eventTitle] (the master state may still be loading on first paint).
Future<void> _waitForPublicEventRow(
  WidgetTester tester, {
  required String eventTitle,
}) async {
  await waitFor(
    tester,
    () => find.byType(PublicEventsPanelBody).evaluate().isNotEmpty,
    description: 'Public Events panel to mount on dashboard',
  );
  await waitFor(
    tester,
    () => find
        .descendant(
          of: find.byType(PublicEventsPanelBody),
          matching: find.textContaining(eventTitle),
        )
        .evaluate()
        .isNotEmpty,
    description: 'event "$eventTitle" to appear in the Public Events panel',
    timeout: const Duration(seconds: 30),
  );
}
