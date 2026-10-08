// workflow365: integration coverage for a member's view of events they may see.
//
// A regular member must be able to see their own events (public events
// + private events they are enrolled in), open each one without hitting
// the admin-only `listEvents` endpoint, act on invite/request flows
// through notifications, and see the resulting enrollments reflected in
// both the events list and the calendar view.
//
// Fixtures (all `workflow365_` prefixed per the integration-test
// naming rule):
//   * workflow365_user                  — no roles (an ordinary member).
//   * workflow365_venue                 — venue anchor for every event.
//   * workflow365_public_invited        — public; user invited.
//   * workflow365_public_join           — public; user will request.
//   * workflow365_private_assigned      — private; user assigned.
//   * workflow365_private_hidden        — private; user has no enrollment.
//
// Events are seeded via the admin SDK in `setUpAll` (workflow4's pattern;
// the event-create UI is currently absent, so SDK seeding is
// the only viable path). Everything past setUpAll is driven through the
// app UI a real user would touch.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server1.conf \
//       workflow365_member_event_visibility_test.dart

import 'package:cl_club_communication/src/widgets/pending_action_trailing.dart'
    show PendingActionTrailing;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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

const _kUser = 'workflow365_user';
const _kUserPwd = 'Workflow365UserPwd!2024';
const _kVenue = 'workflow365_venue';

const _kPublicInvited = 'workflow365_public_invited';
const _kPublicJoin = 'workflow365_public_join';
const _kPrivateAssigned = 'workflow365_private_assigned';
const _kPrivateHidden = 'workflow365_private_hidden';

late int _venueId;
late int _publicInvitedId;
late int _publicJoinId;
late int _privateAssignedId;
late int _privateHiddenId;

Future<SecureClient> _adminClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

/// Polls the server-side enrollment row until it matches [expected]. Uses
/// a transient admin SDK client so the test never has to wrestle with the
/// app's autoDispose family providers from outside the widget tree.
Future<void> _expectEnrollmentStatus({
  required int eventId,
  required String username,
  required EnrollmentStatus expected,
  required String description,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final admin = await _adminClient();
  final deadline = DateTime.now().add(timeout);
  EnrollmentStatus? last;
  try {
    while (DateTime.now().isBefore(deadline)) {
      last = await admin.enrollments.getEnrollmentStatus(eventId, username);
      if (last == expected) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  } finally {
    await admin.auth.logout();
  }
  throw TestFailure(
    'Enrollment status mismatch for event $eventId / $username '
    '($description): expected $expected, last observed $last.',
  );
}

Future<int> _createEvent(
  SecureClient client, {
  required String title,
  required sdk.Visibility visibility,
  required int slotIndex,
}) async {
  // Stagger each event in its own 30-minute slot at the shared venue to
  // avoid the server's overlap rule, and keep every slot inside the same
  // UTC calendar month so the calendar view's month-window provider
  // surfaces them. slot 0 = +15min, slot 1 = +45min, slot 2 = +75min,
  // slot 3 = +105min.
  final now = DateTime.now().toUtc();
  final start = now.add(Duration(minutes: 15 + slotIndex * 30));
  final end = start.add(const Duration(minutes: 20));
  final event = await client.events.createEvent(
    title: title,
    description: 'workflow365 test event',
    type: EventType.oneOff,
    visibility: visibility,
    venueId: _venueId,
    startTimeUtc: start,
    endTimeUtc: end,
  );
  return event.id;
}

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
    // All four event slots must land in the same UTC month as the
    // calendar view's range query, otherwise the final calendar
    // verification will miss them. Refuse to run if the last slot would
    // cross the month boundary — operator can re-run after the boundary
    // passes or earlier on the next day.
    final nowUtc = DateTime.now().toUtc();
    final lastSlot = nowUtc.add(const Duration(minutes: 105 + 20));
    if (lastSlot.month != nowUtc.month) {
      throw StateError(
        'workflow365: cannot run within ~2 hours of UTC month rollover '
        '(now=$nowUtc). Re-run after the boundary.',
      );
    }
    final admin = await _adminClient();

    final venue = await admin.venues.createVenue(
      name: _kVenue,
      address: 'Workflow 365 Test Rink',
    );
    _venueId = venue.id;

    await admin.users.createUser(
      username: _kUser,
      passwordHash: _kUserPwd,
      firstName: 'Workflow365',
      lastName: 'User',
      phone: '7400543210',
      email: '$_kUser@example.com',
      gender: Gender.preferNotToSay,
      dateOfBirthUtc: DateTime.utc(1990, 1, 1),
    );

    _publicInvitedId = await _createEvent(
      admin,
      title: _kPublicInvited,
      visibility: sdk.Visibility.public,
      slotIndex: 0,
    );
    _publicJoinId = await _createEvent(
      admin,
      title: _kPublicJoin,
      visibility: sdk.Visibility.public,
      slotIndex: 1,
    );
    _privateAssignedId = await _createEvent(
      admin,
      title: _kPrivateAssigned,
      visibility: sdk.Visibility.private,
      slotIndex: 2,
    );
    _privateHiddenId = await _createEvent(
      admin,
      title: _kPrivateHidden,
      visibility: sdk.Visibility.private,
      slotIndex: 3,
    );

    await admin.enrollments.invite(_publicInvitedId, _kUser);
    await admin.enrollments.assign(_privateAssignedId, _kUser);

    await admin.auth.logout();
  });

  tearDownAll(() async {
    final admin = await _adminClient();
    for (final id in [
      _publicInvitedId,
      _publicJoinId,
      _privateAssignedId,
      _privateHiddenId,
    ]) {
      try {
        await admin.events.deleteEvent(id);
      } on Object catch (_) {
        /* best-effort */
      }
    }
    try {
      await admin.users.deleteUser(_kUser);
    } on Object catch (_) {}
    try {
      await admin.venues.deleteVenue(_venueId);
    } on Object catch (_) {}
    await admin.auth.logout();
  });

  testWidgets(
    'member sees their public and assigned-private events, can '
    'open each detail without 403, accepts invite via notification, '
    'requests join, sudo approves via notification, and all enrollments '
    'land in My Events list and calendar',
    (tester) async {
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─────────────────────────────────────────────────────────────
      // Phase 1: member logs in; their My Events master shows the three
      // events they may see — the two public ones + the private event
      // they were assigned to. The fourth event (private, no enrollment)
      // must NOT appear.
      // ─────────────────────────────────────────────────────────────
      await loginViaUi(tester, _kUser, _kUserPwd);
      expect(currentUser(tester), isNotNull, reason: 'member should log in');

      await go(tester, '/memberzone');
      // Hold the auto-dispose master while polling it. The dashboard only
      // watches it through panels that show today's events, so when the
      // fixtures fall after local midnight nothing else keeps it alive,
      // and each unwatched read rebuilds and drops it (club_core#109).
      final myEventsSub = container(
        tester,
      ).listen(clMyEventsMasterProvider(_kUser), (_, _) {});
      addTearDown(myEventsSub.close);
      // What the list held at the last poll, for the failure message: this
      // wait has timed out once (club_core#109) and the cause is not known.
      Object? lastSeen = 'nothing (still loading)';
      try {
        await waitFor(
          tester,
          () {
            final state = container(
              tester,
            ).read(clMyEventsMasterProvider(_kUser));
            final v = state.valueOrNull;
            lastSeen = state.hasError
                ? 'error: ${state.error}'
                : v?.map((e) => e.title).toList() ?? lastSeen;
            return v != null && v.length == 3;
          },
          description: 'member My Events master to load exactly 3 events',
          timeout: const Duration(seconds: 30),
        );
      } on TestFailure {
        fail(
          'member My Events master did not settle on exactly 3 events '
          '(club_core#109); last seen: $lastSeen',
        );
      }
      final myEvents = container(
        tester,
      ).read(clMyEventsMasterProvider(_kUser)).valueOrNull!;
      final myTitles = myEvents.map((e) => e.title).toSet();
      expect(
        myTitles,
        {_kPublicInvited, _kPublicJoin, _kPrivateAssigned},
        reason:
            'member should see both public events + the assigned '
            'private event, and NOT the hidden private event',
      );

      // ─────────────────────────────────────────────────────────────
      // Phase 2: open each visible event detail screen. The pre-fix
      // bug surfaced here as a 403 ServerException; the
      // post-fix path must render the event title and no error view.
      // ─────────────────────────────────────────────────────────────
      for (final title in const [
        _kPublicInvited,
        _kPublicJoin,
        _kPrivateAssigned,
      ]) {
        final id = myEvents.firstWhere((e) => e.title == title).id;
        await go(tester, '/memberzone/my-events/$_kUser/$id');
        await waitFor(
          tester,
          () => find.text(title).evaluate().isNotEmpty,
          description: 'event "$title" detail title to render',
          timeout: const Duration(seconds: 15),
        );
        expect(
          find.text('Could not load event'),
          findsNothing,
          reason: 'member must not see the 403 error view for "$title"',
        );
      }

      // ─────────────────────────────────────────────────────────────
      // Phase 3: open notifications. The member should see an invite
      // notification for `public_invited` with Accept/Decline action
      // buttons (PendingActionTrailing) and an assign notification for
      // `private_assigned` (informational — no action buttons).
      // ─────────────────────────────────────────────────────────────
      await go(tester, '/memberzone/notifications');
      // Warm the master so the list populates.
      container(tester).read(clNotificationsMasterProvider);
      await waitFor(
        tester,
        () {
          final v = container(
            tester,
          ).read(clNotificationsMasterProvider).valueOrNull;
          if (v == null) return false;
          final hasInvite = v.values.any(
            (n) =>
                n.pendingActionType == PendingActionType.enrollmentOpportunity,
          );
          final hasAssign = v.values.any(
            (n) =>
                (n.payload['data'] as Map?)?['eventId'] == _privateAssignedId,
          );
          return hasInvite && hasAssign;
        },
        description: 'invite + assign notifications to appear for the member',
        timeout: const Duration(seconds: 30),
      );

      // The invite row carries PendingActionTrailing with an "Accept"
      // ShadButton. The assign row has no PendingActionTrailing — the
      // count of trailing widgets is therefore exactly one.
      expect(
        find.byType(PendingActionTrailing),
        findsOneWidget,
        reason:
            'only the invite notification should show action buttons; '
            'the assign notification is informational',
      );
      expect(
        find.descendant(
          of: find.byType(PendingActionTrailing),
          matching: find.widgetWithText(ShadButton, 'Accept'),
        ),
        findsOneWidget,
        reason:
            '"Accept" action button must be visible on the invite '
            'notification',
      );

      // Tap Accept — drives clMyEnrollmentsMasterProvider.acceptInvite.
      await tester.tap(
        find.descendant(
          of: find.byType(PendingActionTrailing),
          matching: find.widgetWithText(ShadButton, 'Accept'),
        ),
      );
      await settle(tester);

      // Server-side double-verification. Reading clMyEnrollmentProvider
      // from the test container would race autoDispose (the warning in
      // app/CLAUDE.md), so verify via a short-lived admin SDK call. This
      // also confirms the mutation actually persisted, not just an
      // optimistic local update.
      await _expectEnrollmentStatus(
        eventId: _publicInvitedId,
        username: _kUser,
        expected: EnrollmentStatus.accepted,
        description: 'invite accepted via notification button',
      );

      // ─────────────────────────────────────────────────────────────
      // Phase 4: navigate to `public_join` detail and tap
      // "Request to Join". Verify the enrollment transitions to
      // requested.
      // ─────────────────────────────────────────────────────────────
      await go(tester, '/memberzone/my-events/$_kUser/$_publicJoinId');
      await waitFor(
        tester,
        () => find
            .widgetWithText(ActionButton, 'Request to Join')
            .evaluate()
            .isNotEmpty,
        description: '"Request to Join" button to render on $_kPublicJoin',
        timeout: const Duration(seconds: 15),
      );
      final reqBtn = tester.widget<ActionButton>(
        find.widgetWithText(ActionButton, 'Request to Join'),
      );
      expect(reqBtn.onPressed, isNotNull);
      reqBtn.onPressed!.call();
      await settle(tester);

      await _expectEnrollmentStatus(
        eventId: _publicJoinId,
        username: _kUser,
        expected: EnrollmentStatus.requested,
        description: 'request-to-join from event detail button',
      );

      // ─────────────────────────────────────────────────────────────
      // Phase 5: hand off to sudo, who finds the join-request as a
      // pending action in notifications and Approves it.
      // ─────────────────────────────────────────────────────────────
      await logout(tester);
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);

      await go(tester, '/memberzone/notifications');
      container(tester).read(clNotificationsMasterProvider);
      await waitFor(
        tester,
        () {
          final v = container(
            tester,
          ).read(clNotificationsMasterProvider).valueOrNull;
          return v != null &&
              v.values.any(
                (n) =>
                    n.pendingActionType ==
                        PendingActionType.enrollmentRequest &&
                    (n.payload['data'] as Map?)?['eventId'] == _publicJoinId,
              );
        },
        description:
            'sudo to receive an enrollmentRequest notification for '
            'public_join',
        timeout: const Duration(seconds: 30),
      );

      // Find the specific PendingActionTrailing whose notification is the
      // enrollmentRequest for public_join. Multiple pending actions may
      // be queued for sudo on a busy server, so identify the row by the
      // widget's notification data, not by formatter-produced body text.
      final trailingFinder = find.byWidgetPredicate(
        (w) =>
            w is PendingActionTrailing &&
            w.notification.pendingActionType ==
                PendingActionType.enrollmentRequest &&
            (w.notification.payload['data'] as Map?)?['eventId'] ==
                _publicJoinId,
      );
      expect(
        trailingFinder,
        findsOneWidget,
        reason:
            'PendingActionTrailing for the public_join request '
            "must be mounted in sudo's notifications list",
      );
      final approveBtn = find.descendant(
        of: trailingFinder,
        matching: find.widgetWithText(ShadButton, 'Approve'),
      );
      expect(
        approveBtn,
        findsOneWidget,
        reason:
            'Approve button must be present on the enrollmentRequest '
            'row for public_join',
      );
      await tester.tap(approveBtn);
      await settle(tester);

      // ─────────────────────────────────────────────────────────────
      // Phase 6: member logs back in. All three enrollments are now
      // either accepted or assigned; the member has a notification
      // telling them their join request was approved; and all three
      // events appear in the My Events calendar for today.
      // ─────────────────────────────────────────────────────────────
      await logout(tester);
      await loginViaUi(tester, _kUser, _kUserPwd);
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'member should still be able to log in',
      );

      // Server-side enrollment double-verification.
      await _expectEnrollmentStatus(
        eventId: _publicInvitedId,
        username: _kUser,
        expected: EnrollmentStatus.accepted,
        description: 'invite-accepted enrollment persists',
      );
      await _expectEnrollmentStatus(
        eventId: _publicJoinId,
        username: _kUser,
        expected: EnrollmentStatus.accepted,
        description: 'sudo-approved join request is accepted',
      );
      await _expectEnrollmentStatus(
        eventId: _privateAssignedId,
        username: _kUser,
        expected: EnrollmentStatus.assigned,
        description: 'admin-assigned enrollment stays assigned',
      );

      // Notification confirming the join request was approved. The
      // server emits `enrollment.request_response` (approved=true) for
      // this transition; rather than couple the test to the exact wire
      // string we look for any notification whose payload references
      // public_join AND was created after the request flow began.
      await go(tester, '/memberzone/notifications');
      await waitFor(
        tester,
        () {
          final v = container(
            tester,
          ).read(clNotificationsMasterProvider).valueOrNull;
          if (v == null) return false;
          return v.values.any((n) {
            if ((n.payload['data'] as Map?)?['eventId'] != _publicJoinId) {
              return false;
            }
            // The user-side response notification is informational —
            // pendingActionType is null. Filter out the original
            // outgoing request (which never had a pendingActionType for
            // the member anyway).
            return n.pendingActionType == null;
          });
        },
        description:
            'member to receive a notification about the public_join approval',
        timeout: const Duration(seconds: 30),
      );

      // Calendar: every accepted/assigned event should appear in the
      // current month's occurrence list that the calendar view queries.
      // The view's day filter mixes UTC and local time in a way that's
      // fragile near a TZ-boundary, so assert against the underlying
      // provider data — the calendar mounts that provider for the full
      // current UTC month, which is what we care about here.
      await go(tester, '/memberzone/my-events/$_kUser/calendar');
      final monthRange = (
        username: _kUser,
        fromTimeUtc: DateTime.utc(DateTime.now().year, DateTime.now().month),
        toTimeUtc: DateTime.utc(DateTime.now().year, DateTime.now().month + 1),
      );
      // The calendar watches its own range, not this one: hold this key so
      // the auto-dispose provider resolves instead of being rebuilt and
      // dropped on every poll (club_core#107).
      final monthSub = container(
        tester,
      ).listen(clMyOccurrencesListProvider(monthRange), (_, _) {});
      addTearDown(monthSub.close);
      await waitFor(
        tester,
        () {
          final occs = container(
            tester,
          ).read(clMyOccurrencesListProvider(monthRange)).valueOrNull;
          if (occs == null) return false;
          final eventIds = occs.map((o) => o.eventId).toSet();
          return eventIds.containsAll({
            _publicInvitedId,
            _publicJoinId,
            _privateAssignedId,
          });
        },
        description:
            'My Calendar to expose occurrences for all three enrolled events',
        timeout: const Duration(seconds: 30),
      );
      final occs = container(
        tester,
      ).read(clMyOccurrencesListProvider(monthRange)).valueOrNull!;
      final eventIds = occs.map((o) => o.eventId).toSet();
      expect(
        eventIds.contains(_publicInvitedId),
        isTrue,
        reason: 'public_invited must appear on the calendar',
      );
      expect(
        eventIds.contains(_publicJoinId),
        isTrue,
        reason: 'public_join must appear on the calendar after approval',
      );
      expect(
        eventIds.contains(_privateAssignedId),
        isTrue,
        reason: 'private_assigned must appear on the calendar',
      );
      expect(
        eventIds.contains(_privateHiddenId),
        isFalse,
        reason: 'private_hidden must NOT appear (user has no enrollment)',
      );

      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
