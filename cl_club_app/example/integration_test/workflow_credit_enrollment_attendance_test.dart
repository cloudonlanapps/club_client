// workflow_credit: credit, enrollment and attendance together, through the
// UI, with what admin, coach and member see at each step (club_core#104).
//
// Runs where the stack reports the credit system on (app_test_server2.conf);
// the credits-off companion runs where it is off (app_test_server1.conf).
//
// Setup (SDK, as the suite does for time-dependent fixtures): the cast, a
// venue, and a public programme whose first session starts ~25 minutes
// out, so its register is open (30 minutes ahead) while every enrollment is
// made before the session starts (a member enrolled after it is not
// covered). Programmes recur at most daily, so every step below runs on
// that one session.
//
// Steps (the issue's table, adapted where the server dictates):
//  1. Admin funds m1 (10, bound) from m1's profile chip → credit view.
//     m1 sees 🪙 10 read-only; the coach sees it read-only too.
//  2. Admin assigns m1.                                (Assign picker)
//  3. Admin invites m2 (no credit): Invite is not gated.
//  3a. In Assign, m2 is blocked with an add-credit chip (#105).
//  4. m2 sees Accept greyed with 🪙 0 (#97); admin adds 1 general credit.
//  5. m2 accepts. Admin then reverses m2's credit (↶) so m2 is on the
//     register with no credit and no record (for #99 below).
//  5a/6. Assign Trial: m3 (1 general credit only) is blocked; the
//     add-credit chip opens m3's credit view with trial credit pre-filled;
//     once saved m3 is selectable and is assigned a trial (#105, #114).
//  5b. m4 (no credit) sees Request to Join greyed (#97); funded, m4 asks;
//     admin reverses it, so Approve is greyed with 🪙 0 (#105); funded
//     again from the chip, Approve goes through.
//  7. Coach marks m1 and m3 present: m3's trial ends, flagged on the
//     register (#98), and m3 lands in the collapsed Inactive group.
//  9. m2's row is greyed with 🪙 0 (#99); admin adds credit; the row
//     enables; coach marks m2 present, then late at no extra charge.
// 11. Coach clears m1's mark (refund) and marks it again. (A member cannot
//     declare leave once the register is open: leave closes 2 hours before
//     the session, marking opens 30 minutes before.)
// 12. m1 asks to withdraw: Approve is greyed with the bound credit (#96).
// 13. Admin settles from the chip: ⇄ Transfer with penalty 2.
// 14. Approve withdrawal goes through. 15. Removing m2 (general credit
//     only) is a plain confirm.
// Member views: m1's statement reads the server's running totals; m3 has
// the trial_ended notification (#100).
//
// Recommended run (from the club_core root):
//   just app-test-one app_test_server2.conf \
//       workflow_credit_enrollment_attendance_test.dart

import 'package:cl_club_communication/src/views/notifications_list_view.dart'
    show NotificationsListView;
import 'package:cl_club_credits/src/views/credit_view.dart' show CreditView;
import 'package:cl_club_credits/src/widgets/credit_chip.dart' show CreditChip;
import 'package:cl_club_events/src/models/enrollment_category.dart'
    show EnrollmentCategory, categoryFor;
import 'package:cl_club_events/src/views/event_enrolments_view.dart'
    show EventEnrolmentsView;
import 'package:cl_club_events/src/widgets/assign_trial_dialog.dart'
    show AssignTrialDialogContent;
import 'package:cl_club_events/src/widgets/buttons/enrollment_action_buttons.dart'
    show EnrollmentActionButtons;
import 'package:cl_club_events/src/widgets/enrollment_group_section.dart'
    show EnrollmentGroupSection, EnrollmentGroupSectionState;
import 'package:cl_club_events/src/widgets/enrollment_tile.dart'
    show EnrollmentTile;
import 'package:cl_club_members/src/widgets/profile_credit_line.dart'
    show ProfileCreditLine;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        AttendanceStatus,
        Capabilities,
        CreditAccountKind,
        EnrollmentStatus,
        EventType,
        Gender,
        SecureClient,
        Visibility;
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, CreditCountChip, UserSelectionDialogContent;

import '_helpers/attendance.dart';
import '_helpers/auth.dart';
import '_helpers/capabilities.dart';
import '_helpers/credit.dart';
import '_helpers/enrollments.dart';
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

const _kPwd = 'WorkflowCreditPwd!2026';
const _kAdmin = 'workflow_credit_admin';
const _kCoach = 'workflow_credit_coach';
const _kM1 = 'workflow_credit_m1';
const _kM2 = 'workflow_credit_m2';
const _kM3 = 'workflow_credit_m3';
const _kM4 = 'workflow_credit_m4';
const _kVenue = 'workflow_credit_venue';
const _kProgramme = 'workflow_credit_programme';

const List<String> _kCast = [_kAdmin, _kCoach, _kM1, _kM2, _kM3, _kM4];

/// How far ahead of setup the session starts: inside the 30-minute
/// register lead-in, with room to enroll everyone before it begins.
const _kSessionLead = Duration(minutes: 25);

Future<SecureClient> _sudoClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

late int _programmeId;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  late Capabilities caps;

  setUpAll(() async {
    caps = await stackCapabilities(
      baseUrl: _kApiBaseUrl,
      username: _kSudoUsername,
      password: _kSudoPassword,
    );
    final client = await _sudoClient();
    for (final u in _kCast) {
      await client.users.createUser(
        username: u,
        passwordHash: _kPwd,
        firstName: 'WCredit',
        lastName: u.substring('workflow_credit_'.length),
        phone: '9876543210',
        email: '$u@example.com',
        gender: Gender.preferNotToSay,
        dateOfBirthUtc: DateTime.utc(2000, 1, 1),
      );
    }
    await client.users.assignRole(_kAdmin, 'admin');
    await client.users.assignRole(_kCoach, 'coach');
    final venue = await client.venues.createVenue(name: _kVenue);
    final now = DateTime.now().toUtc().add(_kSessionLead);
    final start = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    final programme = await client.events.createEvent(
      title: _kProgramme,
      description: 'workflow_credit programme',
      type: EventType.programme,
      visibility: Visibility.public,
      venueId: venue.id,
      startTimeUtc: start,
      endTimeUtc: start.add(const Duration(hours: 1)),
      organizerName: _kAdmin,
      coachNames: const [_kCoach],
      rrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU',
    );
    _programmeId = programme.id;
    await client.auth.logout();
  });

  tearDownAll(() async {
    final client = await _sudoClient();
    try {
      await client.events.deleteEvent(_programmeId);
    } on Object catch (_) {}
    for (final u in _kCast) {
      try {
        await client.users.deleteUser(u);
      } on Object catch (_) {}
    }
    await client.auth.logout();
  });

  testWidgets(
    'credit, enrollment and attendance move together, and each role sees '
    'the right credit at every step',
    (tester) async {
      if (skipUnless(enabled: caps.creditSystem, feature: 'credit system')) {
        return;
      }
      await tester.binding.setSurfaceSize(const Size(1600, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── 1. Admin funds m1: 10, bound to the programme ─────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _loadEvents(tester);
      await openCreditSheetFromProfile(tester, username: _kM1);
      expect(
        find.descendant(
          of: find.byType(CreditView),
          matching: find.textContaining('active'),
        ),
        findsOneWidget,
        reason: 'the admin sees the member status in the credit view',
      );
      await addCreditInSheet(tester, credits: 10, programmeId: _programmeId);
      await expectSheetTotal(tester, 10);
      expect(await statementTotals(tester), [10]);
      await closeCreditSheet(tester);

      // ─── 2. Admin assigns m1 ───────────────────────────────────────────
      await _openEnrollments(tester);
      await _pickInActionBarDialog(tester, 'Assign More…', _kM1);
      await _waitForTile(tester, _kM1, EnrollmentStatus.assigned);

      // ─── 3. Invite m2 (no credit): Invite is not gated ─────────────────
      await _pickInActionBarDialog(tester, 'Invite More…', _kM2);
      await _waitForTile(tester, _kM2, EnrollmentStatus.invited);

      // ─── 3a. Assign blocks m2, with an add-credit chip (#105) ──────────
      await _openActionBarDialog(tester, 'Assign More…');
      await waitFor(
        tester,
        () => pickerTile(tester, _kM4).onTap == null,
        description: 'an unfunded member blocked in the Assign picker',
      );
      expect(
        find.descendant(
          of: find.byType(UserSelectionDialogContent),
          matching: find.bySemanticsLabel('Add credit'),
        ),
        findsWidgets,
      );
      invokeShadButton(
        tester,
        find.descendant(
          of: find.byType(UserSelectionDialogContent),
          matching: find.widgetWithText(ShadButton, 'Cancel'),
        ),
      );
      await settle(tester);
      await logout(tester);

      // ─── 4. m2 sees Accept greyed with 🪙 0 (#97) ──────────────────────
      await loginViaUi(tester, _kM2, _kPwd);
      final accept = await _memberAction(
        tester,
        _kM2,
        'Accept',
        enabled: false,
      );
      expect(accept.onPressed, isNull, reason: 'no credit, no accept');
      expect(
        chipCredits(tester, _kM2, within: find.byType(EnrollmentActionButtons)),
        0,
      );
      await logout(tester);

      await loginViaUi(tester, _kAdmin, _kPwd);
      await _loadEvents(tester);
      await openCreditSheetFromProfile(tester, username: _kM2);
      await addCreditInSheet(tester, credits: 1);
      await expectSheetTotal(tester, 1);
      await closeCreditSheet(tester);
      await logout(tester);

      // ─── 5. m2 accepts; admin then takes the credit back ───────────────
      await loginViaUi(tester, _kM2, _kPwd);
      final funded = await _memberAction(
        tester,
        _kM2,
        'Accept',
        enabled: true,
      );
      expect(funded.onPressed, isNotNull, reason: 'funded, accept enabled');
      funded.onPressed!();
      await _memberAction(tester, _kM2, 'Withdraw');
      await logout(tester);

      await loginViaUi(tester, _kAdmin, _kPwd);
      await _loadEvents(tester);
      await openCreditSheetFromProfile(tester, username: _kM2);
      await packageActionInSheet(
        tester,
        where: (a) => a.balance == 1,
        action: 'Reverse',
        text: const {'reason': 'workflow reversal'},
      );
      await expectSheetTotal(tester, 0);
      await closeCreditSheet(tester);

      // ─── 5a/6. Assign Trial: m3 funded on the fly (#105, #114) ─────────
      await openCreditSheetFromProfile(tester, username: _kM3);
      await addCreditInSheet(tester, credits: 1);
      await closeCreditSheet(tester);
      await _openEnrollments(tester);
      await _openActionBarDialog(tester, 'Assign Trial…');
      final addChip = find.descendant(
        of: find.byType(AssignTrialDialogContent),
        matching: find.byWidgetPredicate(
          (w) => w is CreditCountChip && w.add,
        ),
      );
      await waitFor(
        tester,
        () => addChip.evaluate().isNotEmpty,
        description: 'm3 blocked for a trial: general credit does not fund it',
      );
      // Every unfunded member shows one; take m3's.
      final m3Chip = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is CreditChip && w.username == _kM3,
        ),
        matching: find.byType(CreditCountChip),
      );
      tester.widget<CreditCountChip>(m3Chip).onTap!();
      await settle(tester);
      // Add credit opens pre-filled with this programme, as a trial.
      await addCreditInSheet(tester, credits: 1);
      await closeCreditSheet(tester);
      await waitFor(
        tester,
        () => find
            .byWidgetPredicate((w) => w is CreditChip && w.username == _kM3)
            .evaluate()
            .isEmpty,
        description: 'm3 selectable once trial credit is added',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AssignTrialDialogContent),
          matching: find.text(_kM3),
        ),
      );
      await settle(tester);
      await _waitForTile(tester, _kM3, EnrollmentStatus.assignedTrial);
      await logout(tester);

      // ─── 5b. m4: Request to Join greyed, then Approve gated (#97, #105) ─
      await loginViaUi(tester, _kM4, _kPwd);
      final request = await _memberAction(
        tester,
        _kM4,
        'Request to Join',
        enabled: false,
      );
      expect(request.onPressed, isNull, reason: 'no credit, no request');
      await logout(tester);

      await loginViaUi(tester, _kAdmin, _kPwd);
      await _loadEvents(tester);
      await openCreditSheetFromProfile(tester, username: _kM4);
      await addCreditInSheet(tester, credits: 1);
      await closeCreditSheet(tester);
      await logout(tester);

      await loginViaUi(tester, _kM4, _kPwd);
      final requestNow = await _memberAction(
        tester,
        _kM4,
        'Request to Join',
        enabled: true,
      );
      expect(requestNow.onPressed, isNotNull);
      requestNow.onPressed!();
      await settle(tester);
      await _memberAction(tester, _kM4, 'Requested');
      await logout(tester);

      await loginViaUi(tester, _kAdmin, _kPwd);
      await _loadEvents(tester);
      await openCreditSheetFromProfile(tester, username: _kM4);
      await packageActionInSheet(
        tester,
        where: (a) => a.balance == 1,
        action: 'Reverse',
        text: const {'reason': 'workflow reversal'},
      );
      await closeCreditSheet(tester);
      await _openEnrollments(tester);
      // The requester's credit loads after the row: wait for the grey.
      final gatedApprove = await _tileAction(
        tester,
        _kM4,
        'Approve',
        until: (b) => b.onPressed == null,
      );
      expect(gatedApprove.onPressed, isNull, reason: 'unfunded requester');
      await _tapTileChip(tester, _kM4);
      await addCreditInSheet(tester, credits: 1);
      await closeCreditSheet(tester);
      final approve = await _tileAction(
        tester,
        _kM4,
        'Approve',
        until: (b) => b.onPressed != null,
      );
      approve.onPressed!();
      await _waitForTile(tester, _kM4, EnrollmentStatus.accepted);
      await logout(tester);

      // ─── 7. Coach marks m1 and m3: m3's trial ends (#98) ───────────────
      await loginViaUi(tester, _kCoach, _kPwd);
      await openRegisterViaCalendarViaUi(tester, eventTitle: _kProgramme);
      await markInRegisterViaUi(tester, _kM1, AttendanceStatus.present);
      await markInRegisterViaUi(tester, _kM3, AttendanceStatus.present);
      await registerTile(
        tester,
        _kM3,
        until: (t) => t.trialEnded,
        description: 'm3 flagged: the mark ended the trial',
      );

      // ─── 9. m2 has no credit and no record: greyed with 🪙 0 (#99) ─────
      final m2Row = await registerTile(
        tester,
        _kM2,
        until: (t) => t.blockedCredits == 0,
        description: 'm2 greyed out for lack of credit',
      );
      expect(m2Row.blockedCredits, 0);
      await logout(tester);

      // ─── 10. Admin funds m2; the row enables; charged once (#99) ───────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _loadEvents(tester);
      await openCreditSheetFromProfile(tester, username: _kM2);
      await addCreditInSheet(tester, credits: 2);
      await closeCreditSheet(tester);
      await logout(tester);

      await loginViaUi(tester, _kCoach, _kPwd);
      await openRegisterViaCalendarViaUi(tester, eventTitle: _kProgramme);
      await registerTile(
        tester,
        _kM2,
        until: (t) => t.blockedCredits == null,
        description: 'm2 enabled once funded',
      );
      await markInRegisterViaUi(tester, _kM2, AttendanceStatus.present);
      await markInRegisterViaUi(tester, _kM2, AttendanceStatus.late);

      // ─── 11. Coach corrects m1: clear (refund), mark again ─────────────
      await clearInRegisterViaUi(tester, _kM1);
      await markInRegisterViaUi(tester, _kM1, AttendanceStatus.present);

      // The coach reads m1's credit, but has no credit actions.
      await openCreditSheetFromProfile(tester, username: _kM1);
      await expectSheetTotal(tester, 9);
      expect(find.text('Add credit'), findsNothing);
      await closeCreditSheet(tester);
      await logout(tester);

      // m2: charged once for present → late.
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _loadEvents(tester);
      await openCreditSheetFromProfile(tester, username: _kM2);
      await expectSheetTotal(tester, 1);
      await closeCreditSheet(tester);

      // m3: the ended trial in the collapsed Inactive group, flagged (#98).
      await _openEnrollments(tester);
      await _expandInactive(tester);
      final m3Tile = find.byWidgetPredicate(
        (w) => w is EnrollmentTile && w.username == _kM3,
      );
      await waitFor(
        tester,
        () => find
            .descendant(of: m3Tile, matching: find.byIcon(LucideIcons.flag))
            .evaluate()
            .isNotEmpty,
        description: 'm3 in Inactive with the trial-ended flag',
      );
      await logout(tester);

      // ─── 12. m1 asks to withdraw ────────────────────────────────────────
      await loginViaUi(tester, _kM1, _kPwd);
      final withdraw = await _memberAction(tester, _kM1, 'Withdraw');
      withdraw.onPressed!();
      await _memberAction(tester, _kM1, 'Cancel Withdraw');
      await logout(tester);

      // Approve withdrawal is greyed while credit is bound (#96).
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _loadEvents(tester);
      await _openEnrollments(tester);
      final approveWithdraw = await _tileAction(
        tester,
        _kM1,
        'Approve',
        until: (b) => b.onPressed == null,
      );
      expect(approveWithdraw.onPressed, isNull);
      expect(
        chipCredits(tester, _kM1, within: find.byType(EventEnrolmentsView)),
        9,
      );

      // ─── 13. Settle from the chip: ⇄ Transfer, penalty 2 ───────────────
      await _tapTileChip(tester, _kM1);
      await packageActionInSheet(
        tester,
        where: (a) => a.kind == CreditAccountKind.event,
        action: 'Transfer',
        text: const {'penalty': '2', 'reason': 'workflow settlement'},
      );
      await expectSheetTotal(tester, 7);
      await closeCreditSheet(tester);

      // ─── 14. Approve withdrawal goes through ───────────────────────────
      final settled = await _tileAction(
        tester,
        _kM1,
        'Approve',
        until: (b) => b.onPressed != null,
      );
      settled.onPressed!();
      await _waitForTile(tester, _kM1, EnrollmentStatus.withdrawn);

      // ─── 15. Removing m2 (general credit only) is a plain confirm ──────
      final remove = await _tileAction(tester, _kM2, 'Remove');
      expect(remove.onPressed, isNotNull, reason: 'nothing bound to settle');
      remove.onPressed!();
      await settle(tester);
      // The confirmation dialog: its destructive "Remove" button.
      invokeShadButton(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w is ShadButton &&
              w.variant == ShadButtonVariant.destructive &&
              w.child is Text &&
              (w.child! as Text).data == 'Remove',
        ),
        reason: 'confirm Remove',
      );
      await settle(tester);
      await _waitForTile(tester, _kM2, EnrollmentStatus.removed);
      await logout(tester);

      // ─── Member views ──────────────────────────────────────────────────
      // m1's statement: newest first, the server's running totals.
      await loginViaUi(tester, _kM1, _kPwd);
      await openCreditSheetFromProfile(tester, username: _kM1, self: true);
      await expectSheetTotal(tester, 7);
      expect(find.text('Add credit'), findsNothing);
      final totals = await statementTotals(tester, atLeast: 7);
      expect(totals.last, 10, reason: 'the grant opened the statement at 10');
      expect(
        totals.sublist(totals.length - 4),
        [9, 10, 9, 10],
        reason: 'grant, charge, refund (the cleared mark), charge again',
      );
      expect(statementAmounts(tester), contains(-2), reason: 'the penalty');
      await closeCreditSheet(tester);
      await logout(tester);

      // m3: the trial_ended notification (#100).
      await loginViaUi(tester, _kM3, _kPwd);
      await go(tester, '/memberzone/notifications');
      await waitFor(
        tester,
        () => find
            .descendant(
              of: find.byType(NotificationsListView),
              matching: find.byIcon(LucideIcons.flag),
            )
            .evaluate()
            .isNotEmpty,
        description: 'the trial_ended notification for m3',
      );
      await logout(tester);
    },
  );

  testWidgets('with credit off there is no credit UI anywhere', (
    tester,
  ) async {
    if (skipIf(enabled: caps.creditSystem, feature: 'credit system')) return;
    await tester.binding.setSurfaceSize(const Size(1600, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
    await ensureLoggedOut(tester);

    await loginViaUi(tester, _kAdmin, _kPwd);
    await _loadEvents(tester);
    await go(tester, '/memberzone/users/$_kM1');
    await waitFor(
      tester,
      () => find.byType(ProfileCreditLine).evaluate().isNotEmpty,
      description: 'm1 profile to load',
    );
    expect(find.byType(CreditCountChip), findsNothing);

    await _openEnrollments(tester);
    await _pickInActionBarDialog(tester, 'Assign More…', _kM1);
    await _waitForTile(tester, _kM1, EnrollmentStatus.assigned);
    final remove = await _tileAction(tester, _kM1, 'Remove');
    expect(remove.onPressed, isNotNull);
    expect(find.byType(CreditCountChip), findsNothing);

    await go(tester, '/memberzone/credit/$_kM1');
    await waitFor(
      tester,
      () => find.text('Access Denied').evaluate().isNotEmpty,
      description: 'the credit route refused with credit off',
    );
    await logout(tester);
  });
}

/// Loads the staff events master, so the programme resolves on every
/// screen that looks it up (as opening any staff list does).
Future<void> _loadEvents(WidgetTester tester) async {
  await container(tester).read(clEventsMasterProvider.future);
}

Future<void> _openEnrollments(WidgetTester tester) =>
    navigateToEnrollmentManagementViaUi(
      tester,
      eventTitle: _kProgramme,
      eventTypeSegment: 'programmes',
    );

Future<void> _openActionBarDialog(WidgetTester tester, String label) async {
  final button = find.widgetWithText(ShadButton, label);
  await waitFor(
    tester,
    () => button.evaluate().isNotEmpty,
    description: '"$label" on the enrollment screen',
  );
  tester.widget<ShadButton>(button).onPressed!();
  await settle(tester);
}

/// Opens [label]'s picker, picks [username], confirms.
Future<void> _pickInActionBarDialog(
  WidgetTester tester,
  String label,
  String username,
) async {
  await _openActionBarDialog(tester, label);
  await waitFor(
    tester,
    () => find
        .byWidgetPredicate(
          (w) => w is UserSelectionDialogContent,
        )
        .evaluate()
        .isNotEmpty,
    description: 'the $label picker',
  );
  final tile = pickerTile(tester, username);
  expect(tile.onTap, isNotNull, reason: '$username selectable in $label');
  tile.onTap!();
  await tester.pump();
  final select = find.descendant(
    of: find.byType(UserSelectionDialogContent),
    matching: find.byWidgetPredicate(
      (w) =>
          w is ShadButton &&
          w.child is Text &&
          ((w.child! as Text).data ?? '').startsWith('Select ('),
    ),
  );
  invokeShadButton(tester, select, reason: 'Select');
  await settle(tester);
}

Future<void> _waitForTile(
  WidgetTester tester,
  String username,
  EnrollmentStatus status,
) async {
  if (categoryFor(status) == EnrollmentCategory.inactive) {
    await _expandInactive(tester);
  }
  try {
    await waitFor(
      tester,
      () => find
          .byWidgetPredicate(
            (w) =>
                w is EnrollmentTile &&
                w.username == username &&
                w.status == status,
          )
          .evaluate()
          .isNotEmpty,
      description: '$username ${status.name} on the enrollment screen',
    );
  } on TestFailure {
    final shown = [
      for (final t in tester.widgetList<EnrollmentTile>(
        find.byType(EnrollmentTile),
      ))
        '${t.username}:${t.status.name}',
    ];
    final sections = [
      for (final e in find.byType(EnrollmentGroupSection).evaluate())
        _sectionState(e),
    ];
    fail('$username not ${status.name}; tiles $shown; sections $sections');
  }
}

String _sectionState(Element e) {
  final section = e.widget as EnrollmentGroupSection;
  final state = (e as StatefulElement).state as EnrollmentGroupSectionState;
  return '${section.category.name}:${state.expanded}';
}

/// Opens the Inactive enrollment group, which starts collapsed (#98), once
/// it exists.
Future<void> _expandInactive(WidgetTester tester) async {
  final section = find.byWidgetPredicate(
    (w) =>
        w is EnrollmentGroupSection &&
        w.category == EnrollmentCategory.inactive,
  );
  await waitFor(
    tester,
    () => section.evaluate().isNotEmpty,
    description: 'the Inactive enrollment group',
  );
  if (tester.state<EnrollmentGroupSectionState>(section).expanded) return;
  await tester.tap(
    find.descendant(of: section, matching: find.text('Inactive')),
  );
  await settle(tester);
}

/// The [label] action on [username]'s enrollment row.
Future<ActionButton> _tileAction(
  WidgetTester tester,
  String username,
  String label, {
  bool Function(ActionButton button)? until,
}) async {
  final finder = find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is EnrollmentTile && w.username == username,
    ),
    matching: find.widgetWithText(ActionButton, label),
  );
  await waitFor(
    tester,
    () {
      final found = finder.evaluate();
      if (found.isEmpty) return false;
      return until?.call(found.first.widget as ActionButton) ?? true;
    },
    description: '"$label" on the enrollment row of $username',
  );
  return tester.widget<ActionButton>(finder.first);
}

/// Taps the credit chip beside [username]'s greyed-out row action.
Future<void> _tapTileChip(WidgetTester tester, String username) async {
  final chip = find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is EnrollmentTile && w.username == username,
    ),
    matching: find.byType(CreditCountChip),
  );
  await waitFor(
    tester,
    () => chip.evaluate().isNotEmpty,
    description: 'the credit chip on the row of $username',
  );
  tester.widget<CreditCountChip>(chip.first).onTap!();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(CreditView).evaluate().isNotEmpty,
    description: 'the credit view from the chip of $username',
  );
}

/// The member's [label] action on the programme's event page.
Future<ActionButton> _memberAction(
  WidgetTester tester,
  String username,
  String label, {
  bool? enabled,
}) async {
  await go(tester, '/memberzone/my-events/$username/$_programmeId');
  final finder = find.descendant(
    of: find.byType(EnrollmentActionButtons),
    matching: find.widgetWithText(ActionButton, label),
  );
  await waitFor(
    tester,
    () {
      final found = finder.evaluate();
      if (found.isEmpty) return false;
      if (enabled == null) return true;
      // The member's credit loads after the page: wait for its verdict.
      return ((found.first.widget as ActionButton).onPressed != null) ==
          enabled;
    },
    description: '"$label" for $username on the programme page',
  );
  return tester.widget<ActionButton>(finder.first);
}
