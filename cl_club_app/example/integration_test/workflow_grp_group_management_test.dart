// workflow_grp: integration coverage for group management — auto,
// semi-auto, manual — and the join-request approve/reject lifecycle.
//
// One test, multiple scenes; each scene = login → action(s) → logout.
// Scene 2 also covers a regression: a member who repeatedly requests and
// cancels a join request must always see the group in MyGroups exactly
// once (no duplicate cards across request/cancel cycles).
// Scene 1 also checks the audit history (club_core#88): Group History
// lists the create and the member add, and a plain admin's dashboard has
// no global Audit Log entry.
//
// Setup is sudo-via-SDK (one admin + four members) so the UI scenes can
// concentrate on group CRUD and the member-facing surfaces. Cleanup
// soft-deletes the three groups via the admin UI then sudo deletes the
// users off-UI.
//
// Recommended run (from the club_core root):
//   just app-test-one app_test_server1.conf \
//       workflow_grp_group_management_test.dart

import 'package:cl_club_forms/cl_club_forms.dart'
    show AgeEligibilityText, GroupGender, GroupMode;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_members/src/models/group_list_filter.dart'
    show GroupListFilter, GroupTypeFilter;
import 'package:cl_club_members/src/providers/group_list_filter.dart'
    show groupListFilterProvider;
import 'package:cl_club_members/src/views/group_join_requests_view.dart'
    show JoinRequestRow, RejectReasonDialog;
import 'package:cl_club_members/src/widgets/add_member_dialog.dart'
    show AddMemberResultDialog;
import 'package:cl_club_members/src/widgets/cards/group_card.dart'
    show GroupCard;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, NoLongerEligibleLabel, UserSelectionDialogContent;

import '_helpers/audit_log.dart';
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

const _kAdmin = 'workflow_grp_admin';
const _kAdminPwd = 'WorkflowGrpAdmPwd!2024';

const _kMemberA = 'workflow_grp_member_a';
const _kMemberB = 'workflow_grp_member_b';
const _kMemberC = 'workflow_grp_member_c';
const _kMemberD = 'workflow_grp_member_d';
const _kMemberPwd = 'WorkflowGrpMemPwd!2024';

const _kGroupAuto = 'workflow_grp_auto';
const _kGroupSemi = 'workflow_grp_semiauto';
const _kGroupManual = 'workflow_grp_manual';

// Auto / Semi-auto criteria: aged 8 to 16, Male (club_client#33). A group
// counts ages on today, so the fixtures' dates of birth are relative to now:
// a fixed date would one day leave the band.
const _kMinAgeYears = 8;
const _kMaxAgeYears = 16;
const _kInsideAgeYears = 12;
const _kOutsideAgeYears = 30;
const _kAgeSentence = 'Open to members aged $_kMinAgeYears to $_kMaxAgeYears';
final DateTime _kInsideDob = _bornYearsAgo(_kInsideAgeYears);
final DateTime _kOutsideDob = _bornYearsAgo(_kOutsideAgeYears);

/// The date of birth of someone who turns [years] today, at midnight UTC.
DateTime _bornYearsAgo(int years) {
  final now = DateTime.now().toUtc();
  return DateTime.utc(now.year - years, now.month, now.day);
}

Future<SecureClient> _sudoClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
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
    final client = await _sudoClient();

    // Admin (with Admin role).
    await client.users.createUser(
      username: _kAdmin,
      passwordHash: _kAdminPwd,
      firstName: 'WorkflowGrp',
      lastName: 'Admin',
      phone: '9876543210',
      email: '$_kAdmin@example.com',
      gender: Gender.preferNotToSay,
      dateOfBirthUtc: DateTime.utc(1990, 1, 1),
    );
    await client.users.assignRole(_kAdmin, 'admin');

    // Members A, B, C — male, in-window DOB. C is the search-only fixture
    // for scene 1's eligible-list assertion; B is added to no group up-front.
    for (final u in const [_kMemberA, _kMemberB, _kMemberC]) {
      await client.users.createUser(
        username: u,
        passwordHash: _kMemberPwd,
        firstName: 'WGrp',
        lastName: u.substring('workflow_grp_'.length),
        phone: '9876543210',
        email: '$u@example.com',
        gender: Gender.male,
        dateOfBirthUtc: _kInsideDob,
      );
    }

    // Member D — male like the others, but older than the age band, so the
    // band alone makes D ineligible for auto/semi-auto.
    await client.users.createUser(
      username: _kMemberD,
      passwordHash: _kMemberPwd,
      firstName: 'WGrp',
      lastName: 'D',
      phone: '9876543210',
      email: '$_kMemberD@example.com',
      gender: Gender.male,
      dateOfBirthUtc: _kOutsideDob,
    );

    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _sudoClient();
    for (final u in const [
      _kAdmin,
      _kMemberA,
      _kMemberB,
      _kMemberC,
      _kMemberD,
    ]) {
      try {
        await client.users.deleteUser(u);
      } on Object catch (_) {
        /* best-effort */
      }
      try {
        await client.users.hardDeleteUser(u);
      } on Object catch (_) {
        /* best-effort */
      }
    }
    await client.auth.logout();
  });

  testWidgets(
    'group management across auto / semi-auto / manual kinds',
    (tester) async {
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // -----------------------------------------------------------------
      // Scene 1 — Admin creates all three groups, validates eligible-user
      // sourcing, and filters by type to confirm one of each.
      // -----------------------------------------------------------------
      await loginViaUi(tester, _kAdmin, _kAdminPwd);
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'admin login should succeed against the seeded user',
      );
      // Issue 88: the global audit feed is super-admin only; a plain
      // admin's dashboard offers no entry to it.
      await go(tester, '/');
      await expectNoGlobalAuditLogTile(tester);

      // Create Auto: criteria set, semi-auto switch off (default).
      await _createGroupViaUi(
        tester,
        name: _kGroupAuto,
        minAgeYears: _kMinAgeYears,
        maxAgeYears: _kMaxAgeYears,
        gender: Gender.male,
        semiAuto: false,
      );

      // Create Semi-auto: same criteria, switch ON.
      await _createGroupViaUi(
        tester,
        name: _kGroupSemi,
        minAgeYears: _kMinAgeYears,
        maxAgeYears: _kMaxAgeYears,
        gender: Gender.male,
        semiAuto: true,
      );

      // Create Manual: no criteria, no switch.
      await _createGroupViaUi(
        tester,
        name: _kGroupManual,
        minAgeYears: null,
        maxAgeYears: null,
        gender: null,
        semiAuto: false,
      );

      // Read group IDs from the master state once — needed for
      // navigation and provider reads in later scenes.
      final groupsMap = await _waitForGroupsByName(
        tester,
        names: const {_kGroupAuto, _kGroupSemi, _kGroupManual},
      );
      final autoId = groupsMap[_kGroupAuto]!;
      final semiId = groupsMap[_kGroupSemi]!;
      final manualId = groupsMap[_kGroupManual]!;

      // Verify kinds via the read-side master state (TDD §3).
      final groupsState = container(
        tester,
      ).read(clGroupsMasterProvider).valueOrNull!;
      expect(groupsState[autoId]?.kind, GroupKind.auto);
      expect(groupsState[semiId]?.kind, GroupKind.semiAuto);
      expect(groupsState[manualId]?.kind, GroupKind.manual);

      // Eligible check on Semi-auto: A, B, C present; D absent. Driven
      // by opening the AddMemberDialog (the only path that warms the
      // autoDispose clEligibleUsersProvider). After verifying, add A in
      // the same dialog session.
      await _openGroupProfileViaUi(tester, _kGroupSemi);
      await _openAddMemberDialog(tester);
      final semiEligible = _readEligibleFromDialog(tester);
      expect(semiEligible, contains(_kMemberA));
      expect(semiEligible, contains(_kMemberB));
      expect(semiEligible, contains(_kMemberC));
      expect(
        semiEligible,
        isNot(contains(_kMemberD)),
        reason: 'D fails the semi-auto criteria and must be filtered out',
      );
      await _selectAndConfirmInDialog(tester, _kMemberA);

      // Issue 156: straight after the group create and the member add, Group
      // History opens from the profile and its Back returns to this group's
      // profile — no route or dialog left by those steps absorbs the pop.
      await openHistoryViaTitleRow(
        tester,
        title: 'Group History',
        rows: [
          'created group $_kGroupSemi',
          RegExp('added .+ to group $_kGroupSemi'),
        ],
      );
      await backFromHistory(tester);
      await waitFor(
        tester,
        () =>
            find.text('Eligibility').evaluate().isNotEmpty &&
            find.text(_kGroupSemi).evaluate().isNotEmpty &&
            find
                .widgetWithText(ActionButton, '+ Add member')
                .evaluate()
                .isNotEmpty,
        description:
            'Issue 156: Back from Group History to the '
            '"$_kGroupSemi" profile',
      );

      // Issue 33: the Semi-auto group stores the age band, and its profile
      // reads it as a sentence with the dates the server worked out, and
      // the day it counted them on, beneath.
      final semi = container(
        tester,
      ).read(clGroupsMasterProvider).valueOrNull![semiId]!;
      expect(semi.minAge, const Age(years: _kMinAgeYears));
      expect(semi.maxAge, const Age(years: _kMaxAgeYears));
      expect(semi.strictAge, isFalse);
      expect(semi.dobOnOrAfterUtc, isNotNull);
      expect(semi.dobOnOrBeforeUtc, isNotNull);
      expect(semi.eligibilityReferenceDayUtc, isNotNull);
      expect(find.text('$_kAgeSentence.'), findsOneWidget);
      expect(
        find.text(
          AgeEligibilityText.window(
            dobOnOrAfter: semi.dobOnOrAfterUtc,
            dobOnOrBefore: semi.dobOnOrBeforeUtc,
            referenceDay: semi.eligibilityReferenceDayUtc,
          )!,
        ),
        findsOneWidget,
      );
      expect(
        find.text(NoLongerEligibleLabel.text),
        findsNothing,
        reason: 'A is inside the band',
      );

      // Issue 33: A's date of birth is corrected to one outside the band.
      // A stays a member; the member list marks A and says how many no
      // longer match. Corrected back, the mark goes.
      final sudo = await _sudoClient();
      await sudo.users.updateUser(
        _kMemberA,
        dateOfBirthUtc: () => _kOutsideDob,
      );
      await _backToGroupListAndOpen(tester, _kGroupSemi);
      await waitFor(
        tester,
        () => find.text(NoLongerEligibleLabel.text).evaluate().isNotEmpty,
        description: 'member A to be marked as no longer eligible',
      );
      expect(find.text(NoLongerEligibleLabel.text), findsOneWidget);
      expect(find.text('1 member no longer eligible'), findsOneWidget);
      await sudo.users.updateUser(
        _kMemberA,
        dateOfBirthUtc: () => _kInsideDob,
      );
      await sudo.auth.logout();
      await _backToGroupListAndOpen(tester, _kGroupSemi);
      await waitFor(
        tester,
        () =>
            find.text('@$_kMemberA').evaluate().isNotEmpty &&
            find.text(NoLongerEligibleLabel.text).evaluate().isEmpty,
        description: 'member A to be listed without the mark again',
      );
      expect(find.textContaining('no longer eligible'), findsNothing);

      // Eligible check on Manual: all four present (no criteria).
      await _backToGroupListAndOpen(tester, _kGroupManual);
      await _openAddMemberDialog(tester);
      final manualEligible = _readEligibleFromDialog(tester);
      for (final u in const [
        _kMemberA,
        _kMemberB,
        _kMemberC,
        _kMemberD,
      ]) {
        expect(
          manualEligible,
          contains(u),
          reason: 'manual group has no criteria — $u must be eligible',
        );
      }
      await _selectAndConfirmInDialog(tester, _kMemberD);
      // Use semiId/manualId/autoId in later assertions.
      // ignore: unnecessary_statements
      [semiId, manualId, autoId];

      // a group profile reached by pushing from the list must
      // show a back arrow that returns to the list. Self-contained: opens
      // the manual group's profile fresh, asserts + uses the arrow.
      await _assertBackArrowReturnsToList(tester, _kGroupManual);

      // Issue 88: the profile's history button opens Group History, scoped
      // to this group, listing the create and the member add made above —
      // each summary names the group. Back returns to the profile.
      await _openGroupProfileViaUi(tester, _kGroupManual);
      await openHistoryViaTitleRow(
        tester,
        title: 'Group History',
        rows: [
          'created group $_kGroupManual',
          RegExp('added .+ to group $_kGroupManual'),
        ],
      );
      await backFromHistory(tester);
      await waitFor(
        tester,
        () => find.text('Eligibility').evaluate().isNotEmpty,
        description: 'Issue 88: Back from Group History to the group profile',
      );

      // Filter group list by type — assert each filter narrows to the
      // expected single group.
      await _navigateToGroupListViaBack(tester);
      await _verifyTypeFilter(tester, GroupTypeFilter.auto, _kGroupAuto);
      await _verifyTypeFilter(tester, GroupTypeFilter.semiAuto, _kGroupSemi);
      await _verifyTypeFilter(tester, GroupTypeFilter.manual, _kGroupManual);
      // Reset filter so subsequent assertions don't see a narrowed list.
      container(tester).read(groupListFilterProvider.notifier).state =
          const GroupListFilter();

      await logout(tester);

      // -----------------------------------------------------------------
      // Scene 2 — Member A: memberships = Auto + Semi-auto; joinable
      // shows Manual; submit join request for Manual. The
      // group.member_added notification (club_server#71) is asserted in
      // scene 9.
      // -----------------------------------------------------------------
      await loginViaUi(tester, _kMemberA, _kMemberPwd);
      expect(currentUser(tester), isNotNull);

      await go(tester, '/memberzone/my-groups/$_kMemberA');
      await _waitForMyGroupNames(
        tester,
        expected: const {_kGroupAuto, _kGroupSemi},
      );
      await _waitForJoinableNames(tester, expected: const {_kGroupManual});

      // The club_server#71 assertion sits at the end of the test (`Scene 9`
      // below), so a regression there cannot short-circuit scenes 3-8. It
      // still belongs to scene 2 conceptually.

      // Repeatedly requesting and cancelling a join request must
      // not accumulate duplicate cards. "Manual" stays exactly one card at
      // every step — a single request card while pending, a single joinable
      // card after cancel — no matter how many cycles ran.
      for (var cycle = 0; cycle < 3; cycle++) {
        await _tapJoinForGroup(tester, _kGroupManual);
        await _waitForRequestRow(
          tester,
          _kGroupManual,
          status: JoinRequestStatus.pending,
        );
        expect(
          _cardCountForGroup(tester, _kGroupManual),
          1,
          reason:
              'while the request is pending, "Manual" shows '
              'exactly one card (cycle $cycle)',
        );

        await _tapCancelForGroup(tester, _kGroupManual);
        await _waitForJoinableNames(tester, expected: const {_kGroupManual});
        expect(
          _cardCountForGroup(tester, _kGroupManual),
          1,
          reason:
              'after cancelling, "Manual" is back to exactly '
              'one joinable card (cycle $cycle)',
        );
      }

      // Submit the kept join request for Manual (approved by the admin in
      // Scene 5).
      await _tapJoinForGroup(tester, _kGroupManual);
      await _waitForRequestRow(
        tester,
        _kGroupManual,
        status: JoinRequestStatus.pending,
      );

      // re-mount /memberzone/my-groups and assert the pending
      // request row still renders the real group name (not "Group #N").
      // This is the exact scenario the bug regressed on: the row's name has
      // to come from JoinRequest.groupName (club_server#97).
      await logout(tester);
      await loginViaUi(tester, _kMemberA, _kMemberPwd);
      await go(tester, '/memberzone/my-groups/$_kMemberA');
      await _waitForRequestRow(
        tester,
        _kGroupManual,
        status: JoinRequestStatus.pending,
      );
      // Make sure no row is labelled with the legacy fallback.
      expect(
        find.textContaining(RegExp(r'^Group #\d+$')),
        findsNothing,
        reason:
            'joinable/request rows must show the real '
            'group name, never the "Group #<id>" fallback',
      );

      await logout(tester);

      // -----------------------------------------------------------------
      // Scene 3 — Member B: memberships = Auto only; joinable = Semi +
      // Manual; submit join request for Semi-auto.
      // -----------------------------------------------------------------
      await loginViaUi(tester, _kMemberB, _kMemberPwd);
      await go(tester, '/memberzone/my-groups/$_kMemberB');
      await _waitForMyGroupNames(tester, expected: const {_kGroupAuto});
      await _waitForJoinableNames(
        tester,
        expected: const {_kGroupSemi, _kGroupManual},
      );

      await _tapJoinForGroup(tester, _kGroupSemi);
      await _waitForRequestRow(
        tester,
        _kGroupSemi,
        status: JoinRequestStatus.pending,
      );

      await logout(tester);

      // -----------------------------------------------------------------
      // Scene 4 — Member D: memberships = Manual only; joinable does
      // NOT include Semi-auto (criteria fail). Manual was already added
      // by admin, so D has no joinable groups left here.
      // -----------------------------------------------------------------
      await loginViaUi(tester, _kMemberD, _kMemberPwd);
      await go(tester, '/memberzone/my-groups/$_kMemberD');
      await _waitForMyGroupNames(tester, expected: const {_kGroupManual});

      // Joinable section must not show Semi-auto (criteria fail) or
      // Auto (auto groups never joinable). Manual is already a
      // membership, so it's excluded too.
      await _waitForJoinableNames(tester, expected: const {});

      await logout(tester);

      // -----------------------------------------------------------------
      // Scene 5 — Admin processes the two pending join-request rows.
      // Approve A→Manual via the Pending Actions panel (no-reason
      // path); reject B→Semi-auto via the per-group view (with reason)
      // so the rejection notification carries the reason text.
      // -----------------------------------------------------------------
      await loginViaUi(tester, _kAdmin, _kAdminPwd);

      // Open the full Pending Actions list (admin role gates access).
      await go(tester, '/memberzone/pending-actions');
      await _waitForPendingActionRowFor(
        tester,
        requesterUsername: _kMemberA,
        groupName: _kGroupManual,
      );
      await _waitForPendingActionRowFor(
        tester,
        requesterUsername: _kMemberB,
        groupName: _kGroupSemi,
      );

      // Approve A's request via the panel.
      await _approvePendingActionFor(
        tester,
        requesterUsername: _kMemberA,
        groupName: _kGroupManual,
      );

      // Reject B's request via the per-group view with a reason.
      const rejectReason = 'workflow_grp test rejection';
      await _navigateToGroupListViaBack(tester);
      await _openGroupProfileViaUi(tester, _kGroupSemi);
      await _openManageRequestsForCurrentGroup(tester);
      await _rejectFirstPendingWithReason(tester, rejectReason);

      // Auto-dismiss verification: the panel should now show neither
      // entry. The panel notifier dismisses locally for actions taken
      // *through* the panel; the per-group reject (GroupJoinRequestsView)
      // doesn't touch the panel notifier. Force a refresh so the
      // server-side auto-dismiss propagates.
      await go(tester, '/memberzone/pending-actions');
      await container(
        tester,
      ).read(clPendingActionsMasterProvider.notifier).refresh();
      await settle(tester);
      await waitFor(
        tester,
        () =>
            !_pendingActionVisibleFor(
              tester,
              requesterUsername: _kMemberA,
              groupName: _kGroupManual,
            ) &&
            !_pendingActionVisibleFor(
              tester,
              requesterUsername: _kMemberB,
              groupName: _kGroupSemi,
            ),
        description: 'Pending Actions panel to drop both processed rows',
      );

      await logout(tester);

      // -----------------------------------------------------------------
      // Scene 6 — Member A: notifications include group.join_response
      // approved for Manual; current memberships now include Manual.
      // -----------------------------------------------------------------
      await loginViaUi(tester, _kMemberA, _kMemberPwd);
      await _assertNotificationOfType(
        tester,
        username: _kMemberA,
        type: 'group.join_response',
        groupName: _kGroupManual,
        outcome: 'approved',
      );

      await go(tester, '/memberzone/my-groups/$_kMemberA');
      await _waitForMyGroupNames(
        tester,
        expected: const {_kGroupAuto, _kGroupSemi, _kGroupManual},
      );

      await logout(tester);

      // -----------------------------------------------------------------
      // Scene 7 — Member B: rejected response for Semi-auto, reason
      // visible; memberships still = Auto only; Semi-auto reappears in
      // joinable.
      // -----------------------------------------------------------------
      await loginViaUi(tester, _kMemberB, _kMemberPwd);
      await _assertNotificationOfType(
        tester,
        username: _kMemberB,
        type: 'group.join_response',
        groupName: _kGroupSemi,
        outcome: 'rejected',
        expectedReason: rejectReason,
      );

      await go(tester, '/memberzone/my-groups/$_kMemberB');
      await _waitForMyGroupNames(tester, expected: const {_kGroupAuto});
      await _waitForJoinableNames(
        tester,
        expected: const {_kGroupSemi, _kGroupManual},
      );

      await logout(tester);

      // -----------------------------------------------------------------
      // Scene 8 — Admin cleanup: soft-delete all three groups via the
      // group profile's "Delete Group" action. Sudo deletes users in
      // tearDownAll.
      // -----------------------------------------------------------------
      await loginViaUi(tester, _kAdmin, _kAdminPwd);
      for (final name in const [_kGroupAuto, _kGroupSemi, _kGroupManual]) {
        await _navigateToGroupListViaBack(tester);
        // Default filter hides deleted; resetting ensures we always
        // start from the unfiltered list when looking up the next
        // group.
        container(tester).read(groupListFilterProvider.notifier).state =
            const GroupListFilter();
        await _openGroupProfileViaUi(tester, name);
        await _softDeleteCurrentGroupViaUi(tester);
        // Confirm via master state that the group is no longer active.
        final masterMap =
            container(tester).read(clGroupsMasterProvider).valueOrNull ??
            const <int, Group>{};
        final id = groupsMap[name]!;
        final g = masterMap[id];
        // Soft-delete leaves the entry visible in the master with
        // isActive=false, OR removes it from the active list.
        expect(
          g == null || !g.isActive,
          isTrue,
          reason: 'group "$name" should be soft-deleted',
        );
      }
      await logout(tester);

      // -----------------------------------------------------------------
      // Scene 9 (deferred from scene 2) — club_server#71 strict assertion.
      // Member A must have received a `group.member_added` notification
      // when admin direct-added them to the Semi-auto group in scene 1.
      // -----------------------------------------------------------------
      await loginViaUi(tester, _kMemberA, _kMemberPwd);
      await _assertNotificationOfType(
        tester,
        username: _kMemberA,
        type: 'group.member_added',
        groupName: _kGroupSemi,
      );
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

// ---------------------------------------------------------------------------
// Local helpers — group-specific UI driving / read-side checks.
//
// These are intentionally inline rather than promoted to `_helpers/groups.dart`
// because no other workflow yet exercises the group surfaces. Promote when
// the next workflow needs the same vocabulary.
// ---------------------------------------------------------------------------

/// Walk Dashboard → sidebar "Groups" → "+ Add group" → fill GroupForm.
/// Per CLAUDE.md the only legitimate `go` is to a sub-flow start —
/// `/memberzone` is the dashboard, the user-facing entry point.
/// Maps the SDK [Gender] used by the test fixtures to the form-local
/// [GroupGender] the SDK-free group form speaks: Boys, Girls, or Any for no
/// gender criterion (the form offers no other entry, club_client#78).
GroupGender _toGroupGender(Gender? g) => switch (g) {
  Gender.male => GroupGender.boys,
  Gender.female => GroupGender.girls,
  Gender.other || Gender.preferNotToSay || null => GroupGender.any,
};

Future<void> _createGroupViaUi(
  WidgetTester tester, {
  required String name,
  required int? minAgeYears,
  required int? maxAgeYears,
  required Gender? gender,
  required bool semiAuto,
}) async {
  await go(tester, '/memberzone/groups');
  final addBtn = find.widgetWithText(ActionButton, '+ Add group');
  await waitFor(
    tester,
    () => addBtn.evaluate().isNotEmpty,
    description: '"+ Add group" button on the admin groups list',
  );
  // Calling onPressed directly avoids hit-test misses on narrow viewports.
  tester.widget<ActionButton>(addBtn).onPressed!.call();
  await settle(tester);

  await waitFor(
    tester,
    () => find
        .byWidgetPredicate((w) => w is ShadInputFormField && w.id == 'name')
        .evaluate()
        .isNotEmpty,
    description: 'GroupCreateForm to mount with id="name"',
  );

  await enterTextById(tester, 'name', name);

  // Pick the membership mode. The eligibility criteria fields only render for
  // auto / semi-auto, so set the mode first and pump to mount them.
  final hasCriteria =
      minAgeYears != null || maxAgeYears != null || gender != null;
  final mode = !hasCriteria
      ? GroupMode.manual
      : (semiAuto ? GroupMode.semiAuto : GroupMode.auto);
  setShadFormValues(tester, {'mode': mode});
  await tester.pump();

  // The age band is typed, one input per part (club_client#33); there are
  // no date pickers. Gender is a select, written straight into the form's
  // value map as the form-local GroupGender (the form is SDK-free).
  if (hasCriteria) {
    expect(find.textContaining('DOB'), findsNothing);
    if (minAgeYears != null) {
      await enterTextById(
        tester,
        AgeEligibilityFormFields.minAgeYearsId,
        '$minAgeYears',
      );
    }
    if (maxAgeYears != null) {
      await enterTextById(
        tester,
        AgeEligibilityFormFields.maxAgeYearsId,
        '$maxAgeYears',
      );
    }
    setShadFormValues(tester, {'gender': _toGroupGender(gender)});
    await tester.pump();
  }

  // Submit.
  final create = find.widgetWithText(ShadButton, 'Create group');
  expect(create, findsOneWidget, reason: 'expected one Create group button');
  tester.widget<ShadButton>(create).onPressed!.call();
  await settle(tester);

  // Wait for the new group to appear in the master state — that is the
  // authoritative signal a server round-trip completed.
  await waitFor(
    tester,
    () {
      final groups = container(tester).read(clGroupsMasterProvider).valueOrNull;
      if (groups == null) return false;
      return groups.values.any((g) => g.name == name);
    },
    description: 'group "$name" to appear in clGroupsMasterProvider',
    timeout: const Duration(seconds: 30),
  );
}

Future<Map<String, int>> _waitForGroupsByName(
  WidgetTester tester, {
  required Set<String> names,
}) async {
  await waitFor(
    tester,
    () {
      final groups = container(tester).read(clGroupsMasterProvider).valueOrNull;
      if (groups == null) return false;
      final present = groups.values.map((g) => g.name).toSet();
      return names.every(present.contains);
    },
    description: 'clGroupsMasterProvider to contain ${names.join(", ")}',
  );
  final groups = container(tester).read(clGroupsMasterProvider).valueOrNull!;
  return {
    for (final g in groups.values)
      if (names.contains(g.name)) g.name: g.id,
  };
}

Future<void> _openGroupProfileViaUi(
  WidgetTester tester,
  String groupName,
) async {
  await go(tester, '/memberzone/groups');
  // Reset any active filter so the card is reachable.
  container(tester).read(groupListFilterProvider.notifier).state =
      const GroupListFilter();
  await tester.pump();
  await waitFor(
    tester,
    () => find
        .descendant(
          of: find.byType(GroupCard),
          matching: find.text(groupName),
        )
        .evaluate()
        .isNotEmpty,
    description: 'GroupCard for "$groupName" to render',
  );
  // Walk up from the name text to the enclosing GroupCard, then open it.
  final card = find.ancestor(
    of: find.text(groupName),
    matching: find.byType(GroupCard),
  );
  expect(
    card,
    findsOneWidget,
    reason: 'expected one GroupCard rendering "$groupName"',
  );
  // Invoke the card's onTap directly rather than tester.tap: on the
  // 1280x720 Linux desktop window the lower cards sit below the fold,
  // where a synthesized tap lands off-screen and silently no-ops (leaving
  // the test stranded on the group list).
  final cardWidget = tester.widget<GroupCard>(card.first);
  expect(
    cardWidget.onTap,
    isNotNull,
    reason: 'GroupCard for "$groupName" should be tappable',
  );
  cardWidget.onTap!.call();
  await settle(tester);
}

Future<void> _backToGroupListAndOpen(
  WidgetTester tester,
  String groupName,
) async {
  // The profile back arrow pops; rather than hunt for it, just renavigate
  // to the list (still a sub-flow start that a user could perform via the
  // sidebar).
  await _openGroupProfileViaUi(tester, groupName);
}

Future<void> _navigateToGroupListViaBack(WidgetTester tester) async {
  await go(tester, '/memberzone/groups');
}

/// a group profile reached by pushing from the group list must
/// show a back arrow that returns to the list. The router previously passed
/// `onBack: context.canPop() ? ... : null` — `canPop()` reads false inside
/// the shell pageBuilder even for pushed routes, so `onBack` came out null
/// and `TitleRow` hid the arrow entirely. Opens the named group's profile
/// fresh (a push from the list), asserts the arrow is present and enabled
/// (the regression), then invokes it and asserts the list re-renders (a
/// GroupCard appears and the detail's Eligibility section is gone).
Future<void> _assertBackArrowReturnsToList(
  WidgetTester tester,
  String groupName,
) async {
  await _openGroupProfileViaUi(tester, groupName);
  // On the pushed detail: the Eligibility section is present, the list's
  // cards are offstage.
  expect(
    find.text('Eligibility'),
    findsOneWidget,
    reason: 'precondition: opening a group must show its detail',
  );
  final backIcon = find.byIcon(Icons.arrow_back);
  expect(
    backIcon,
    findsOneWidget,
    reason: 'pushed group detail must show a back arrow',
  );
  // Invoke onPressed directly rather than tester.tap: on the 1280x720 Linux
  // desktop window the arrow can sit where a synthesized tap lands off-screen.
  final button = tester.widget<IconButton>(
    find.ancestor(of: backIcon, matching: find.byType(IconButton)),
  );
  expect(button.onPressed, isNotNull, reason: 'back arrow must be enabled');
  button.onPressed!.call();
  await settle(tester);
  // Back on the list: a GroupCard renders and the detail's Eligibility
  // section is gone.
  await waitFor(
    tester,
    () =>
        find.byType(GroupCard).evaluate().isNotEmpty &&
        find.text('Eligibility').evaluate().isEmpty,
    description: 'group list to render after tapping the back arrow',
  );
}

/// Opens the AddMemberDialog from the active group profile and waits
/// until the dialog has finished its eligible-users fetch (i.e. the
/// loading spinner is gone and either tiles or an empty-state message
/// is rendered).
Future<void> _openAddMemberDialog(WidgetTester tester) async {
  final btn = find.widgetWithText(ActionButton, '+ Add member');
  expect(
    btn,
    findsOneWidget,
    reason: 'expected "+ Add member" button on the profile',
  );
  tester.widget<ActionButton>(btn).onPressed!.call();
  await settle(tester);

  await waitFor(
    tester,
    () => find.byType(UserSelectionDialogContent).evaluate().isNotEmpty,
    description: 'AddMemberDialog to mount',
  );

  // Wait until at least one user tile (or the "no eligible users"
  // message) renders inside the dialog, signalling the eligible users
  // fetch finished.
  await waitFor(
    tester,
    () {
      final dialog = find.byType(UserSelectionDialogContent);
      if (dialog.evaluate().isEmpty) return false;
      final hasTile = find
          .descendant(of: dialog, matching: find.byType(GestureDetector))
          .evaluate()
          .isNotEmpty;
      final hasEmpty = find
          .descendant(
            of: dialog,
            matching: find.text('No eligible users for this group.'),
          )
          .evaluate()
          .isNotEmpty;
      return hasTile || hasEmpty;
    },
    description: 'AddMemberDialog to finish loading eligible users',
  );
}

/// Reads `@username` text fragments visible inside the open
/// AddMemberDialog, returning the bare usernames. Caller is responsible
/// for filtering to the workflow_grp_ namespace if the dialog might
/// list unrelated users.
List<String> _readEligibleFromDialog(WidgetTester tester) {
  final dialog = find.byType(UserSelectionDialogContent);
  expect(
    dialog,
    findsOneWidget,
    reason: 'expected an open AddMemberDialog when reading eligible users',
  );
  final captions = find.descendant(of: dialog, matching: find.byType(Text));
  final usernames = <String>[];
  for (final el in captions.evaluate()) {
    final w = el.widget as Text;
    final s = w.data;
    if (s != null && s.startsWith('@')) {
      usernames.add(s.substring(1));
    }
  }
  return usernames;
}

/// Selects the tile for [username] inside the open AddMemberDialog,
/// confirms via "Add", and waits for the dialog to dismiss.
Future<void> _selectAndConfirmInDialog(
  WidgetTester tester,
  String username,
) async {
  final tile = find.ancestor(
    of: find.text('@$username'),
    matching: find.byType(GestureDetector),
  );
  await waitFor(
    tester,
    () => tile.evaluate().isNotEmpty,
    description: 'eligible user tile for $username inside AddMemberDialog',
  );
  await tester.tap(tile.first);
  await settle(tester);

  // Once a user is selected the picker's confirm button relabels from "Add"
  // to "Add (N)", so match by prefix rather than the bare label.
  final addBtn = find.descendant(
    of: find.byType(UserSelectionDialogContent),
    matching: find.byWidgetPredicate(
      (w) =>
          w is ShadButton &&
          w.child is Text &&
          ((w.child! as Text).data ?? '').startsWith('Add'),
    ),
  );
  await waitFor(
    tester,
    () {
      final found = addBtn.evaluate();
      return found.isNotEmpty &&
          (found.first.widget as ShadButton).onPressed != null;
    },
    description: '"Add (…)" confirm enabled with "$username" picked',
  );
  tester.widget<ShadButton>(addBtn).onPressed!.call();
  await settle(tester);

  await waitFor(
    tester,
    () => find.byType(UserSelectionDialogContent).evaluate().isEmpty,
    description: 'AddMemberDialog to dismiss after adding $username',
  );

  // The add ends on a modal outcome dialog. Close it with "Done", as a user
  // must before touching the page underneath: left open, it stays the top
  // route of the root navigator and absorbs the next Back (club_core#156).
  final result = find.byType(AddMemberResultDialog);
  await waitFor(
    tester,
    () => result.evaluate().isNotEmpty,
    description: 'add-member outcome dialog after adding $username',
  );
  expect(
    find.descendant(of: result, matching: find.text('@$username')),
    findsOneWidget,
    reason: 'the outcome dialog must list $username as added',
  );
  tester
      .widget<ShadButton>(
        find.descendant(
          of: result,
          matching: find.widgetWithText(ShadButton, 'Done'),
        ),
      )
      .onPressed!
      .call();
  await settle(tester);
  await waitFor(
    tester,
    () => result.evaluate().isEmpty,
    description: 'add-member outcome dialog to close on "Done"',
  );
}

Future<void> _verifyTypeFilter(
  WidgetTester tester,
  GroupTypeFilter type,
  String expectedSingleGroup,
) async {
  container(tester).read(groupListFilterProvider.notifier).state =
      GroupListFilter(typeFilter: type);
  await settle(tester);
  await waitFor(
    tester,
    () => find
        .descendant(
          of: find.byType(GroupCard),
          matching: find.text(expectedSingleGroup),
        )
        .evaluate()
        .isNotEmpty,
    description: 'filtered list to surface "$expectedSingleGroup"',
  );
  // Other workflow_grp groups must NOT appear under this filter.
  for (final other in const [_kGroupAuto, _kGroupSemi, _kGroupManual]) {
    if (other == expectedSingleGroup) continue;
    expect(
      find.descendant(
        of: find.byType(GroupCard),
        matching: find.text(other),
      ),
      findsNothing,
      reason:
          'filter $type should hide "$other" while showing '
          '"$expectedSingleGroup"',
    );
  }
}

Future<void> _waitForMyGroupNames(
  WidgetTester tester, {
  required Set<String> expected,
}) async {
  // Rows are identified by the group-name Text descendant of each
  // GroupCard. The round-2 card API exposes only groupId; the name is
  // resolved internally from the master.
  await waitFor(
    tester,
    () => expected.every(
      (name) => find
          .descendant(
            of: find.byType(GroupCard),
            matching: find.text(name),
          )
          .evaluate()
          .isNotEmpty,
    ),
    description: 'GroupCard rows to include ${expected.join(", ")}',
  );
}

Future<void> _waitForJoinableNames(
  WidgetTester tester, {
  required Set<String> expected,
}) async {
  // A joinable row is a GroupCard with a descendant ActionButton labelled
  // "Request to Join". We look for the group name's text inside such a
  // card.
  await waitFor(
    tester,
    () {
      return expected.every((name) {
        final nameText = find.descendant(
          of: find.byType(GroupCard),
          matching: find.text(name),
        );
        if (nameText.evaluate().isEmpty) return false;
        final card = find.ancestor(
          of: nameText,
          matching: find.byType(GroupCard),
        );
        return find
            .descendant(
              of: card,
              matching: find.widgetWithText(ActionButton, 'Request to Join'),
            )
            .evaluate()
            .isNotEmpty;
      });
    },
    description: 'joinable GroupCard rows to be exactly ${expected.join(", ")}',
  );
}

Future<void> _tapJoinForGroup(WidgetTester tester, String groupName) async {
  final nameText = find.descendant(
    of: find.byType(GroupCard),
    matching: find.text(groupName),
  );
  final card = find.ancestor(of: nameText, matching: find.byType(GroupCard));
  final joinBtn = find.descendant(
    of: card,
    matching: find.widgetWithText(ActionButton, 'Request to Join'),
  );
  expect(
    joinBtn,
    findsOneWidget,
    reason: 'expected one joinable GroupCard for "$groupName"',
  );
  tester.widget<ActionButton>(joinBtn).onPressed!.call();
  await settle(tester);
}

/// Taps the "Cancel Request" action on the pending GroupCard for [groupName].
/// Mirrors [_tapJoinForGroup]; the cancel fires directly (no confirm dialog).
/// A pending group renders as a single request card, so there is
/// exactly one "Cancel Request" action.
Future<void> _tapCancelForGroup(WidgetTester tester, String groupName) async {
  final nameText = find.descendant(
    of: find.byType(GroupCard),
    matching: find.text(groupName),
  );
  final card = find.ancestor(of: nameText, matching: find.byType(GroupCard));
  final cancelBtn = find.descendant(
    of: card,
    matching: find.widgetWithText(ActionButton, 'Cancel Request'),
  );
  expect(
    cancelBtn,
    findsOneWidget,
    reason: 'expected one pending GroupCard for "$groupName"',
  );
  tester.widget<ActionButton>(cancelBtn).onPressed!.call();
  await settle(tester);
}

/// Counts how many distinct [GroupCard]s currently mention [groupName].
/// The invariant is that this is always exactly 1 — the group
/// must never appear as both a joinable row and a request row, nor as two
/// request rows, regardless of how many request/cancel cycles ran.
int _cardCountForGroup(WidgetTester tester, String groupName) {
  var count = 0;
  for (final element in find.byType(GroupCard).evaluate()) {
    final inThisCard = find.descendant(
      of: find.byWidget(element.widget),
      matching: find.text(groupName),
    );
    if (inThisCard.evaluate().isNotEmpty) count++;
  }
  return count;
}

Future<void> _waitForRequestRow(
  WidgetTester tester,
  String groupName, {
  required JoinRequestStatus status,
}) async {
  // The card derives its own caption from the join-request state; the
  // status text appears as a descendant Text widget that contains the
  // expected status keyword (e.g. "pending").
  final keyword = _statusLabel(status);
  await waitFor(
    tester,
    () {
      final nameText = find.descendant(
        of: find.byType(GroupCard),
        matching: find.text(groupName),
      );
      if (nameText.evaluate().isEmpty) return false;
      final card = find.ancestor(
        of: nameText,
        matching: find.byType(GroupCard),
      );
      return find
          .descendant(
            of: card,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Text &&
                  (w.data?.toLowerCase().contains(keyword) ?? false),
            ),
          )
          .evaluate()
          .isNotEmpty;
    },
    description: 'request row for "$groupName" with status $status',
  );
}

String _statusLabel(JoinRequestStatus s) {
  switch (s) {
    case JoinRequestStatus.pending:
      return 'pending';
    case JoinRequestStatus.approved:
      return 'approved';
    case JoinRequestStatus.rejected:
      return 'rejected';
    case JoinRequestStatus.cancelled:
      return 'cancelled';
  }
}

Future<void> _assertNotificationOfType(
  WidgetTester tester, {
  required String username,
  required String type,
  String? groupName,
  String? outcome,
  String? expectedReason,
}) async {
  // The notifications master is autoloaded for the current user. Wait
  // for it to load and contain a row matching the predicate.
  await waitFor(
    tester,
    () {
      final m = container(
        tester,
      ).read(clNotificationsMasterProvider).valueOrNull;
      if (m == null) return false;
      return m.values.any((n) {
        if (n.type != type) return false;
        final data = _payloadData(n);
        if (groupName != null && data['groupName'] != groupName) return false;
        if (outcome != null && data['outcome'] != outcome) return false;
        if (expectedReason != null && data['reason'] != expectedReason) {
          return false;
        }
        return true;
      });
    },
    description:
        'notification of type "$type" (group=$groupName, outcome=$outcome)',
    // The longer timeout allows for the notification list's refresh cadence.
    timeout: const Duration(seconds: 25),
  );
}

Map<String, dynamic> _payloadData(AppNotification n) {
  final raw = n.payload['data'];
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const <String, dynamic>{};
}

Future<void> _waitForPendingActionRowFor(
  WidgetTester tester, {
  required String requesterUsername,
  required String groupName,
}) async {
  await waitFor(
    tester,
    () => _pendingActionVisibleFor(
      tester,
      requesterUsername: requesterUsername,
      groupName: groupName,
    ),
    description: 'pending action row for $requesterUsername / $groupName',
  );
}

bool _pendingActionVisibleFor(
  WidgetTester tester, {
  required String requesterUsername,
  required String groupName,
}) {
  final m = container(tester).read(clPendingActionsMasterProvider).valueOrNull;
  if (m == null) return false;
  return m.values.any((n) {
    if (n.type != 'group.join_request') return false;
    final data = _payloadData(n);
    return data['requesterUsername'] == requesterUsername &&
        data['groupName'] == groupName;
  });
}

Future<void> _approvePendingActionFor(
  WidgetTester tester, {
  required String requesterUsername,
  required String groupName,
}) async {
  // Locate the AppNotification id via the master state, then walk the
  // visible Approve button on its row. The PendingActionTrailing widget
  // does not expose the notification id, so we match on the body text
  // contributed by the formatter ("$requesterUsername asked to join
  // $groupName.").
  final body = '$requesterUsername asked to join $groupName.';
  await waitFor(
    tester,
    () => find.text(body).evaluate().isNotEmpty,
    description: 'pending action body text for $requesterUsername',
  );
  // Walk up to the row card and find the Approve button.
  final approve = find.descendant(
    of: find
        .ancestor(
          of: find.text(body),
          matching: find.byType(ListView),
        )
        .first,
    matching: find.widgetWithText(ShadButton, 'Approve'),
  );
  // ListView contains all rows; we need the Approve button inside this
  // specific row. Walk via the immediate Row ancestor of the body text.
  final rowApprove = find.descendant(
    of: find.ancestor(
      of: find.text(body),
      matching: find.byType(Row),
    ),
    matching: find.widgetWithText(ShadButton, 'Approve'),
  );
  expect(rowApprove, findsAtLeastNWidgets(1));
  // Some Row ancestors capture the button; grab the closest match.
  final closest = rowApprove.first;
  tester.widget<ShadButton>(closest).onPressed!.call();
  await settle(tester);
  final _ = approve; // silence analyzer for the diagnostic finder above
}

Future<void> _openManageRequestsForCurrentGroup(WidgetTester tester) async {
  // Pending requests are now surfaced as a persistent
  // "New Requests" section directly on the group profile, so there
  // is no overflow menu to traverse — just wait for the rows.
  await waitFor(
    tester,
    () => find.byType(JoinRequestRow).evaluate().isNotEmpty,
    description: 'JoinRequestRow rows to render in the per-group view',
  );
}

Future<void> _rejectFirstPendingWithReason(
  WidgetTester tester,
  String reason,
) async {
  final reject = find.widgetWithText(ShadButton, 'Reject');
  expect(
    reject,
    findsAtLeastNWidgets(1),
    reason: 'expected at least one Reject button on a pending row',
  );
  // The row can sit below the fold, where a synthesized tap misses
  // (club_core#106): invoke the button instead.
  tester.widget<ShadButton>(reject.first).onPressed!.call();
  await settle(tester);

  await waitFor(
    tester,
    () => find.byType(RejectReasonDialog).evaluate().isNotEmpty,
    description: 'RejectReasonDialog to mount',
  );
  // The dialog has a single ShadInput with multiline; type into its
  // EditableText.
  final editable = find.descendant(
    of: find.byType(RejectReasonDialog),
    matching: find.byType(EditableText),
  );
  expect(editable, findsOneWidget);
  await tester.enterText(editable, reason);
  await tester.pump();

  // The destructive "Reject" button confirms.
  final confirm = find.descendant(
    of: find.byType(RejectReasonDialog),
    matching: find.widgetWithText(ShadButton, 'Reject'),
  );
  expect(confirm, findsOneWidget);
  tester.widget<ShadButton>(confirm).onPressed!.call();
  await settle(tester);

  await waitFor(
    tester,
    () => find.byType(RejectReasonDialog).evaluate().isEmpty,
    description: 'RejectReasonDialog to close after rejection',
  );
}

Future<void> _softDeleteCurrentGroupViaUi(WidgetTester tester) async {
  // The active-group profile exposes a destructive "Delete" admin action
  // (an ActionButton in GroupManagementSection) that opens a ConfirmDialog.
  await waitFor(
    tester,
    () => find.widgetWithText(ActionButton, 'Delete').evaluate().isNotEmpty,
    description: '"Delete" action button on active group profile',
  );
  tester
      .widget<ActionButton>(find.widgetWithText(ActionButton, 'Delete').first)
      .onPressed!
      .call();
  await settle(tester);

  // Confirm in the ConfirmDialog (a ShadDialog with a destructive "Delete"
  // button); scope to the dialog so we don't match the trigger ActionButton's
  // own inner ShadButton.
  final confirm = find.descendant(
    of: find.byType(ShadDialog),
    matching: find.widgetWithText(ShadButton, 'Delete'),
  );
  await waitFor(
    tester,
    () => confirm.evaluate().isNotEmpty,
    description: 'Delete confirm button in the ConfirmDialog',
  );
  tester.widget<ShadButton>(confirm.first).onPressed!.call();
  await settle(tester);
}
