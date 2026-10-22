// workflow_evswitch: the Cancelled events and Past events switches of the
// Events section of a profile (club_client#88, club_client#125).
//
// The section lists a member's current events. Each switch adds the events
// of its kind the member is enrolled on, and takes them away again when it
// is turned off.
//
// Fixtures (all `workflow_evswitch_` prefixed per the naming rule), seeded
// through the admin SDK in setUpAll (workflow365's pattern):
//   * workflow_evswitch_member     the member whose profile is read.
//   * workflow_evswitch_admin      an admin (not the super admin).
//   * workflow_evswitch_venue      the venue of the three events.
//   * workflow_evswitch_current    a one-off a month ahead.
//   * workflow_evswitch_cancelled  a camp that began yesterday and runs for
//     five days, cancelled from its first day by the super admin (who may
//     set a cutoff that has passed).
//   * workflow_evswitch_ended      a one-off held two days ago.
// The member is assigned to all three by the super admin, who may enrol on
// an event that is over.
//
// Flow:
//   1. The member opens their own profile: only the current event. Each
//      switch adds its event and no other, and takes it away again; with
//      both on all three are listed.
//   2. The admin opens the member from the members page: the same.
//   3. Cleanup: the super admin soft-deletes the two users; the events and
//      the venue are deleted through the SDK in tearDownAll.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//       workflow_evswitch_profile_events_switches_test.dart

import 'package:cl_club_events/cl_club_events.dart' show MyEventsSection;
import 'package:cl_club_events/src/widgets/cards/event_card.dart'
    show EventCard;
import 'package:cl_club_events/src/widgets/my_events_section_header.dart'
    show MyEventsSectionHeader;
import 'package:cl_club_events/src/widgets/my_events_switch.dart'
    show MyEventsSwitch;
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '_helpers/auth.dart';
import '_helpers/pump.dart';
import '_helpers/surface.dart';
import '_helpers/users.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

const _kMember = 'workflow_evswitch_member';
const _kAdmin = 'workflow_evswitch_admin';
const _kPwd = 'WfEvSwitchPwd!2024';
const _kVenue = 'workflow_evswitch_venue';
const _kCurrentTitle = 'workflow_evswitch_current';
const _kCancelledTitle = 'workflow_evswitch_cancelled';
const _kEndedTitle = 'workflow_evswitch_ended';

const String _kCancelledSwitch = MyEventsSectionHeader.cancelledSwitchLabel;
const String _kPastSwitch = MyEventsSectionHeader.pastSwitchLabel;

late int _venueId;
late int _currentId;
late int _cancelledId;
late int _endedId;

Future<SecureClient> _sdkClient(String username, String password) async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(username, password);
  return c;
}

/// 09:00 UTC on the day [days] from today (negative: before today).
DateTime _nineOn(int days) {
  final d = DateTime.now().toUtc().add(Duration(days: days));
  return DateTime.utc(d.year, d.month, d.day, 9);
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
    final sudo = await _sdkClient(_kSudoUsername, _kSudoPassword);

    final venue = await sudo.venues.createVenue(
      name: _kVenue,
      address: 'workflow_evswitch address line 1',
    );
    _venueId = venue.id;

    var phone = 7400500410;
    for (final (username, first, last) in [
      (_kMember, 'Switch', 'Member'),
      (_kAdmin, 'Switch', 'Admin'),
    ]) {
      await sudo.users.createUser(
        username: username,
        passwordHash: _kPwd,
        firstName: first,
        lastName: last,
        phone: '${phone++}',
        email: '$username@example.com',
        gender: Gender.preferNotToSay,
        dateOfBirthUtc: DateTime.utc(1990),
      );
    }
    await sudo.users.assignRole(_kAdmin, 'admin');

    Future<Event> create(
      String title,
      EventType type,
      DateTime start, {
      String? rrule,
    }) => sudo.events.createEvent(
      title: title,
      description: 'workflow_evswitch test event',
      type: type,
      visibility: sdk.Visibility.public,
      venueId: _venueId,
      startTimeUtc: start,
      endTimeUtc: start.add(const Duration(hours: 1)),
      rrule: rrule,
    );

    _currentId = (await create(
      _kCurrentTitle,
      EventType.oneOff,
      _nineOn(30),
    )).id;
    _endedId = (await create(_kEndedTitle, EventType.oneOff, _nineOn(-2))).id;
    final campStart = _nineOn(-1);
    _cancelledId = (await create(
      _kCancelledTitle,
      EventType.camp,
      campStart,
      rrule: 'FREQ=DAILY;COUNT=5',
    )).id;

    for (final eventId in [_currentId, _endedId, _cancelledId]) {
      await sudo.enrollments.assign(eventId, _kMember);
    }

    // Cancelled from its first day, which has passed: the camp's cutoff is
    // reached, though three of its days are still ahead.
    final cancelled = await sudo.events.cancelSeries(
      _cancelledId,
      version: (await sudo.events.getEvent(_cancelledId)).version,
      reason: 'workflow_evswitch: the rink is closed',
      effectiveDateTimeUtc: campStart,
    );
    expect(cancelled.untilTimeUtc, campStart);

    await sudo.auth.logout();
  });

  tearDownAll(() async {
    // The users are soft-deleted through the UI by the test itself.
    final sudo = await _sdkClient(_kSudoUsername, _kSudoPassword);
    try {
      for (final eventId in [_currentId, _endedId, _cancelledId]) {
        await sudo.events.deleteEvent(eventId);
      }
      await sudo.venues.deleteVenue(_venueId);
    } finally {
      await sudo.auth.logout();
    }
  });

  testWidgets(
    'Issue 125: the Cancelled events and Past events switches of the '
    "profile's Events section each add their own event and take it away "
    "again, on the member's own profile and on an admin's view of it",
    (tester) async {
      await useTestSurface(tester, const Size(1600, 4000));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── 1. The member's own profile ───────────────────────────────────
      await loginViaUi(tester, _kMember, _kPwd);
      await go(tester, '/memberzone/profile');
      await _checkSwitches(tester, "the member's own profile");
      await logout(tester);

      // ─── 2. An admin's view of the member ──────────────────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await go(tester, '/memberzone/users');
      final memberCard = find.byKey(const ValueKey(_kMember));
      await waitFor(
        tester,
        () => memberCard.evaluate().isNotEmpty,
        description: "the member's card in the members list",
      );
      await tester.tap(memberCard);
      await settle(tester);
      await _checkSwitches(tester, "an admin's view of the member");
      await logout(tester);

      // ─── 3. Cleanup through the UI ─────────────────────────────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await softDeleteUserViaUi(tester, _kMember);
      await softDeleteUserViaUi(tester, _kAdmin);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

// ---------------------------------------------------------------------------
// Local helpers.
// ---------------------------------------------------------------------------

/// The switch of the Events section labelled [label].
Finder _switch(String label) => find.descendant(
  of: find.widgetWithText(MyEventsSwitch, label),
  matching: find.byType(ShadSwitch),
);

/// Which of the three events the Events section on screen lists. Another
/// event the server holds is not this test's to count.
Set<int> _listed(WidgetTester tester) => tester
    .widgetList<EventCard>(
      find.descendant(
        of: find.byType(MyEventsSection),
        matching: find.byType(EventCard),
      ),
    )
    .map((card) => card.eventId)
    .toSet()
    .intersection({_currentId, _cancelledId, _endedId});

/// Waits until the section lists [expected] of the three events, then
/// checks it still does once the page is at rest: an event whose enrolment
/// is read late would join the list after the wait.
Future<void> _expectListed(
  WidgetTester tester,
  Set<int> expected, {
  required String when,
}) async {
  await waitFor(
    tester,
    () => setEquals(_listed(tester), expected),
    description: 'the Events section to list $expected $when',
  );
  await settle(tester);
  expect(_listed(tester), expected, reason: when);
}

/// Turns the switch labelled [label] on or off with a tap.
Future<void> _turn(
  WidgetTester tester,
  String label, {
  required bool on,
}) async {
  expect(
    tester.widget<ShadSwitch>(_switch(label)).value,
    !on,
    reason: '"$label" before it is turned ${on ? 'on' : 'off'}',
  );
  await tester.tap(_switch(label));
  await waitFor(
    tester,
    () => tester.widget<ShadSwitch>(_switch(label)).value == on,
    description: '"$label" to be ${on ? 'on' : 'off'}',
  );
}

/// On the profile now open ([where]): only the current event to start with;
/// each switch adds its own event and takes it away again.
Future<void> _checkSwitches(WidgetTester tester, String where) async {
  await waitFor(
    tester,
    () =>
        _switch(_kCancelledSwitch).evaluate().isNotEmpty &&
        _switch(_kPastSwitch).evaluate().isNotEmpty,
    description: 'the two switches of the Events section on $where',
  );
  expect(tester.widget<ShadSwitch>(_switch(_kCancelledSwitch)).value, isFalse);
  expect(tester.widget<ShadSwitch>(_switch(_kPastSwitch)).value, isFalse);
  await _expectListed(
    tester,
    {_currentId},
    when: 'with both switches off on $where',
  );

  await _turn(tester, _kCancelledSwitch, on: true);
  await _expectListed(
    tester,
    {_currentId, _cancelledId},
    when: 'with Cancelled events on, on $where',
  );
  await _turn(tester, _kCancelledSwitch, on: false);
  await _expectListed(
    tester,
    {_currentId},
    when: 'with Cancelled events off again on $where',
  );

  await _turn(tester, _kPastSwitch, on: true);
  await _expectListed(
    tester,
    {_currentId, _endedId},
    when: 'with Past events on, on $where',
  );

  await _turn(tester, _kCancelledSwitch, on: true);
  await _expectListed(
    tester,
    {_currentId, _cancelledId, _endedId},
    when: 'with both switches on, on $where',
  );
  await _turn(tester, _kCancelledSwitch, on: false);

  await _turn(tester, _kPastSwitch, on: false);
  await _expectListed(
    tester,
    {_currentId},
    when: 'with Past events off again on $where',
  );
}
