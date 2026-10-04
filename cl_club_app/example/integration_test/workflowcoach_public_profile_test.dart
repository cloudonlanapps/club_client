// workflowcoach: integration coverage for a coach's public profile
// (club_server#262).
//
// A logged-in member opening an event sees the Organizer & Coaches section
// and can tap a publicly-surfaced coach's name to open that coach's public
// profile (`/memberzone/profile/:publicId`), rendered from the unauthenticated
// `/public` API. A coach who is NOT surfaced (no display_order) renders as
// plain, non-tappable text.
//
// Fixtures (all `workflowcoach_` prefixed per the naming rule):
//   * workflowcoach_member  — the acting member.
//   * workflowcoach_coach   — surfaced coach (coach role + display_order +
//                             bio/achievements + public name).
//   * workflowcoach_venue   — venue anchor.
//   * workflowcoach_event   — public oneOff event coached by the coach.
//
// Seeded via the admin SDK in setUpAll (workflow365's pattern); everything
// past setUpAll is driven through the app UI.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//       workflowcoach_public_profile_test.dart

import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/widgets.dart' show Scrollable;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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

const _kMember = 'workflowcoach_member';
const _kMemberPwd = 'WorkflowCoachMemberPwd!2024';
const _kCoach = 'workflowcoach_coach';
const _kCoachPwd = 'WorkflowCoachCoachPwd!2024';
const _kVenue = 'workflowcoach_venue';
const _kCoachDisplayName = 'Surfaced Coach';
const _kCoachAchievements = 'National champion.';

late int _venueId;
late int _eventId;

Future<SecureClient> _adminClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
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
    final admin = await _adminClient();

    final venue = await admin.venues.createVenue(
      name: _kVenue,
      address: 'Workflow Coach Test Rink',
    );
    _venueId = venue.id;

    // Acting member.
    await admin.users.createUser(
      username: _kMember,
      passwordHash: _kMemberPwd,
      firstName: 'WorkflowCoach',
      lastName: 'Member',
      phone: '9876500001',
      email: '$_kMember@example.com',
      gender: Gender.preferNotToSay,
      dateOfBirthUtc: DateTime.utc(1990, 1, 1),
    );

    // A coach with a public name + bio; the coach opts into a public profile
    // themselves (admins cannot set is_public_profile).
    await admin.users.createUser(
      username: _kCoach,
      passwordHash: _kCoachPwd,
      firstName: 'Surfaced',
      lastName: 'Coach',
      phone: '9876500002',
      email: '$_kCoach@example.com',
      gender: Gender.preferNotToSay,
      dateOfBirthUtc: DateTime.utc(1985, 1, 1),
    );
    await admin.users.assignRole(_kCoach, 'coach');
    await admin.users.updateUser(
      _kCoach,
      bio: () => 'Loves hockey.',
      achievements: () => _kCoachAchievements,
    );
    final coach = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
    await coach.auth.login(_kCoach, _kCoachPwd);
    await coach.users.updateUser(
      _kCoach,
      useNamePublicly: true,
      isPublicProfile: true,
    );
    await coach.auth.logout();

    // Public event coached by the surfaced coach.
    final start = DateTime.now().toUtc().add(const Duration(hours: 1));
    final event = await admin.events.createEvent(
      title: 'workflowcoach_event',
      description: 'workflowcoach test event',
      type: EventType.oneOff,
      visibility: sdk.Visibility.public,
      venueId: _venueId,
      startTimeUtc: start,
      endTimeUtc: start.add(const Duration(minutes: 30)),
      coachNames: const [_kCoach],
    );
    _eventId = event.id;

    await admin.auth.logout();
  });

  tearDownAll(() async {
    final admin = await _adminClient();
    try {
      await admin.events.deleteEvent(_eventId);
      await admin.users.deleteUser(_kMember);
      await admin.users.deleteUser(_kCoach);
      await admin.venues.deleteVenue(_venueId);
    } finally {
      await admin.auth.logout();
    }
  });

  testWidgets(
    'a member taps a surfaced coach on an event and opens the public profile',
    (tester) async {
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await loginViaUi(tester, _kMember, _kMemberPwd);

      // Start point: the event detail (member's My Events view). From here
      // everything is tap-driven.
      await go(tester, '/memberzone/my-events/$_kMember/$_eventId');
      await waitFor(
        tester,
        () => find.text('workflowcoach_event').evaluate().isNotEmpty,
        description: 'event detail to load',
      );

      // The coaches section resolves each coach's display name async.
      const coachRow = '• $_kCoachDisplayName';
      await waitFor(
        tester,
        () => find.text(coachRow).evaluate().isNotEmpty,
        description: 'coach row to render',
      );

      // Bring the (possibly below-fold) coach row on-screen, then tap it.
      await tester.scrollUntilVisible(
        find.text(coachRow),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(coachRow));
      await settle(tester);

      // The public profile view: display name + achievements heading.
      await waitFor(
        tester,
        () => find.text('Achievements').evaluate().isNotEmpty,
        description: 'public profile to open',
      );
      expect(find.text(_kCoachDisplayName), findsWidgets);
      expect(find.text('Achievements'), findsOneWidget);
    },
  );
}
