// workflow_editgroup: focused coverage of the group eligibility section editor
// and the description markdown editor on `/memberzone/groups/:id`, across roles.
//
// The Phase 1 groups-list-empty failure is fixed: the groups
// master now gates the admin-only `getDeletedGroups` fetch on the admin role
// (watching `currentUserProvider`), so a coach session — or an admin session
// mid-login before the role lands — no longer 403s on `/groups/deleted` and
// poisons the whole list.
//
// Flow:
//   0. Sudo creates an admin, a coach, and a member.
//   1. Admin creates a group, opens it, and sees the editable eligibility
//      section + description editor.
//   2. Coach opens the group — eligibility and description are read-only.
//   3. Member is access-gated from the admin groups list (admin/coach-only).
//   4. Admin edits eligibility (inline) and the description (markdown); each
//      change round-trips to the server AND reflects in place.
//   5. Coach (read-only viewer) re-opens the group and sees the updated prose.
//   6. Cleanup: admin deletes the group; sudo soft-deletes the actors.

import 'package:cl_club_members/src/models/group_list_filter.dart'
    show GroupListFilter;
import 'package:cl_club_members/src/providers/group_list_filter.dart'
    show groupListFilterProvider;
import 'package:cl_club_members/src/widgets/cards/group_card.dart'
    show GroupCard;
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Gender, Group, GroupKind, Role;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, ErrorView, GroupGender, GroupMode;

import '_helpers/auth.dart';
import '_helpers/editors.dart';
import '_helpers/forms.dart';
import '_helpers/pump.dart';
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

const _kAdmin = 'workflow_editgroup_admin';
const _kCoach = 'workflow_editgroup_coach';
const _kMember = 'workflow_editgroup_member';
const _kPwd = 'WfEditGroupPwd!2024';

const _kGroupName = 'workflow_editgroup_team';
const _kEditedDescription =
    '# workflow_editgroup updated\n\nEdited inline by the admin.';
// Eligibility prose the card renders after switching to a girls-only,
// criteria-based group.
const _kGirlsSentence = 'This group is only for Girls.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  testWidgets(
    'group eligibility + markdown editors across admin/coach/member',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── Phase 0: sudo creates the three actors ────────────────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await createUserViaUi(tester, username: _kAdmin, password: _kPwd);
      await grantRolesViaCheckboxViaUi(
        tester,
        username: _kAdmin,
        roles: {Role.admin},
      );
      await createUserViaUi(tester, username: _kCoach, password: _kPwd);
      await grantRolesViaCheckboxViaUi(
        tester,
        username: _kCoach,
        roles: {Role.coach},
      );
      await createUserViaUi(tester, username: _kMember, password: _kPwd);
      await logout(tester);

      // ─── Phase 1: admin creates the group, sees editable sections ──────
      await loginViaUi(tester, _kAdmin, _kPwd);
      // Pinpoint: the admin's session must actually carry the admin role
      // (granted in Phase 0) — the groups list GET is admin/coach-gated.
      expect(
        container(tester).read(authStateProvider).valueOrNull?.roles.isAdmin,
        isTrue,
        reason: 'admin session must carry the admin role after login',
      );
      await _createManualGroup(tester, _kGroupName);
      final groupId = await _waitForGroupId(tester, _kGroupName);

      await _openGroupDetail(tester, groupId);
      expect(find.text('Eligibility'), findsOneWidget);
      expectSectionEditable(tester, _eligibilityCard);
      expect(find.byTooltip('Edit Description'), findsOneWidget);
      await logout(tester);

      // ─── Phase 2: coach view is read-only ──────────────────────────────
      await loginViaUi(tester, _kCoach, _kPwd);
      await _openGroupDetail(tester, groupId);
      expect(find.text('Eligibility'), findsOneWidget);
      expectSectionReadOnly(tester, _eligibilityCard);
      expect(
        find.byTooltip('Edit Description'),
        findsNothing,
        reason: 'coach must not get the description editor',
      );
      await logout(tester);

      // ─── Phase 3: member is access-gated from the admin groups list ────
      // Unlike venues, the groups list is admin/coach-only — a plain member
      // cannot reach it (a member views a group via my-groups when they
      // belong to it). Assert the gate rather than a read-only render.
      await loginViaUi(tester, _kMember, _kPwd);
      await go(tester, '/memberzone/groups');
      await waitFor(
        tester,
        () => find.byType(ErrorView).evaluate().isNotEmpty,
        description: 'member to be access-gated from the admin groups list',
      );
      await logout(tester);

      // ─── Phase 4: admin edits eligibility + description ────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openGroupDetail(tester, groupId);

      // Eligibility — inline edit: switch to a semi-auto, girls-only group.
      await tapSectionPencil(tester, _eligibilityCard);
      setShadFormValues(tester, {
        'mode': GroupMode.semiAuto,
        'gender': GroupGender.female,
      });
      await tester.pump();
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () {
          final g = _group(tester, groupId);
          return g.kind == GroupKind.semiAuto && g.gender == Gender.female;
        },
        description: 'eligibility to round-trip to the server',
      );
      // The card returns to read mode showing the new eligibility prose.
      expect(
        find.text(_kGirlsSentence),
        findsOneWidget,
        reason: 'updated eligibility prose must show after save',
      );

      // Description — markdown editor.
      await editMarkdownField(
        tester,
        tooltip: 'Edit Description',
        markdown: _kEditedDescription,
      );
      await waitFor(
        tester,
        () => _group(tester, groupId).description == _kEditedDescription,
        description: 'description to round-trip to the server',
      );
      await logout(tester);

      // ─── Phase 5: coach (read-only viewer) sees the updated prose ──────
      await loginViaUi(tester, _kCoach, _kPwd);
      await _openGroupDetail(tester, groupId);
      expect(find.text(_kGirlsSentence), findsOneWidget);
      await logout(tester);

      // ─── Phase 6: cleanup ──────────────────────────────────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openGroupDetail(tester, groupId);
      await _deleteGroup(tester);
      await logout(tester);

      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await softDeleteUserViaUi(tester, _kAdmin);
      await softDeleteUserViaUi(tester, _kCoach);
      await softDeleteUserViaUi(tester, _kMember);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

// ---------------------------------------------------------------------------
// Local helpers.
// ---------------------------------------------------------------------------

/// The eligibility section card, scoped by its 'Eligibility' header.
final Finder _eligibilityCard = find.ancestor(
  of: find.text('Eligibility'),
  matching: find.byType(ShadCard),
);

Group _group(WidgetTester tester, int groupId) {
  final map = container(tester).read(clGroupsMasterProvider).valueOrNull;
  expect(map, isNotNull, reason: 'clGroupsMasterProvider should be loaded');
  final group = map![groupId];
  expect(group, isNotNull, reason: 'group #$groupId must exist');
  return group!;
}

Future<int> _waitForGroupId(WidgetTester tester, String name) async {
  await waitFor(
    tester,
    () {
      final map = container(tester).read(clGroupsMasterProvider).valueOrNull;
      return map != null && map.values.any((g) => g.name == name);
    },
    description: 'clGroupsMasterProvider to contain "$name"',
    timeout: const Duration(seconds: 30),
  );
  final map = container(tester).read(clGroupsMasterProvider).valueOrNull!;
  return map.values.firstWhere((g) => g.name == name).id;
}

Future<void> _createManualGroup(WidgetTester tester, String name) async {
  await go(tester, '/memberzone/groups');
  final addBtn = find.widgetWithText(ActionButton, '+ Add group');
  await waitFor(
    tester,
    () => addBtn.evaluate().isNotEmpty,
    description: '"+ Add group" button on the admin groups list',
  );
  tester.widget<ActionButton>(addBtn).onPressed!.call();
  await settle(tester);

  await waitFor(
    tester,
    () => find
        .byWidgetPredicate((w) => w is ShadInputFormField && w.id == 'name')
        .evaluate()
        .isNotEmpty,
    description: 'GroupCreateForm to mount',
  );
  await enterTextById(tester, 'name', name);
  setShadFormValues(tester, {'mode': GroupMode.manual});
  await tester.pump();

  final create = find.widgetWithText(ShadButton, 'Create group');
  expect(create, findsOneWidget, reason: 'expected one Create group button');
  tester.widget<ShadButton>(create).onPressed!.call();
  await settle(tester);
  await waitFor(
    tester,
    () {
      final groups = container(tester).read(clGroupsMasterProvider).valueOrNull;
      return groups != null && groups.values.any((g) => g.name == name);
    },
    description: 'group "$name" to appear in clGroupsMasterProvider',
    timeout: const Duration(seconds: 30),
  );
}

Future<void> _openGroupDetail(WidgetTester tester, int groupId) async {
  await go(tester, '/memberzone/groups');
  // Reset any active list filter so the card is reachable (mirrors
  // workflow_grp's _openGroupProfileViaUi).
  container(tester).read(groupListFilterProvider.notifier).state =
      const GroupListFilter();
  await settle(tester);
  // The list keys each GroupCard with ValueKey(group.id); matching the id is
  // robust against how the card renders the name.
  final card = find.byKey(ValueKey(groupId));
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: 'GroupCard #$groupId to render on the groups list',
    timeout: const Duration(seconds: 25),
  );
  tester.widget<GroupCard>(card.first).onTap!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.text('Eligibility').evaluate().isNotEmpty,
    description: 'group profile (Eligibility section) to render',
  );
}

Future<void> _deleteGroup(WidgetTester tester) async {
  final managementCard = find.ancestor(
    of: find.text('Group Management'),
    matching: find.byType(ShadCard),
  );
  final trigger = find.descendant(
    of: managementCard,
    matching: find.widgetWithText(ActionButton, 'Delete'),
  );
  expect(trigger, findsOneWidget, reason: 'management Delete button');
  tester.widget<ActionButton>(trigger).onPressed!.call();
  await settle(tester);
  // ConfirmDialog with a destructive confirm labelled 'Delete'.
  await waitFor(
    tester,
    () => find.text('Delete group?').evaluate().isNotEmpty,
    description: 'delete-group confirm dialog',
  );
  invokeShadButton(
    tester,
    find.descendant(
      of: find.byType(ShadDialog),
      matching: find.widgetWithText(ShadButton, 'Delete'),
    ),
    reason: 'confirm group soft-delete',
  );
  await settle(tester);
}
