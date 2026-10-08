// workflow_edituser: focused coverage of the user-profile section editors and
// the bio/achievements markdown editors, across roles and on the self profile.
//
// Flow:
//   0. Sudo creates an admin, a coach, and a member.
//   1. Admin opens the member's profile: sections present and editable; the
//      empty Address section is shown (with the add affordance) to the admin.
//      The phone typed at creation is stored in international format (#31).
//   2. Coach opens the member's profile: read-only (no pencils, no markdown
//      editors) and the empty Address section is hidden entirely.
//   3. Member opens their own profile: sections present and self-editable.
//   4. Admin edits personal details / contact / address (inline) + bio
//      (markdown); each change round-trips to the server and reflects in place.
//   5. Member confirms the updates on their own profile.
//   6. Cleanup: admin soft-deletes the member; sudo soft-deletes admin + coach.

import 'package:cl_club_members/src/views/user_profile_view.dart'
    show AddressCard, PersonalDetailsCard;
import 'package:cl_club_members/src/widgets/user_contact_info_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clUserPrivateProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Role, UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers/auth.dart';
import '_helpers/capabilities.dart';
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

const _kAdmin = 'workflow_edituser_admin';
const _kCoach = 'workflow_edituser_coach';
const _kMember = 'workflow_edituser_member';
const _kPwd = 'WfEditUserPwd!2024';

const _kEditedFirstName = 'WfEdited';

// Phones as typed, and the national number each must be stored under once
// the app has put it in international format (#31): one typed bare at
// creation, one typed with a space and a leading 0 in the Contact section.
const _kCreatedPhone = '7400500010';
const _kEditedPhoneTyped = '074005 00011';
const _kEditedPhone = '7400500011';
const _kEditedAddrLine1 = 'WfEdited line 1';
const _kEditedBio = 'workflow_edituser bio: edited by admin.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  testWidgets(
    'user profile section + markdown editors across roles + self',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // The country code a phone typed without one is completed with is the
      // stack's, so what is stored is expected from its capabilities (#31).
      final caps = await stackCapabilities(
        baseUrl: _kApiBaseUrl,
        username: _kSudoUsername,
        password: _kSudoPassword,
      );
      final createdPhone = storedPhone(caps, _kCreatedPhone);
      final editedPhone = storedPhone(caps, _kEditedPhone);

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
      await createUserViaUi(
        tester,
        username: _kMember,
        password: _kPwd,
        phone: _kCreatedPhone,
      );
      await logout(tester);

      // ─── Phase 1: admin sees editable sections (empty Address shown) ───
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openMemberProfile(tester, _kMember);
      expect(find.text('Personal details'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
      expect(
        find.text('Address'),
        findsOneWidget,
        reason: 'empty Address section is shown (with add affordance) to admin',
      );
      expectSectionEditable(tester, find.byType(PersonalDetailsCard));
      expect(find.byTooltip('Edit Bio'), findsOneWidget);
      expect(
        _member(tester).phone,
        createdPhone,
        reason:
            'Issue 31: a phone typed without a country code at user '
            'creation is stored with the country code of the stack',
      );
      await logout(tester);

      // ─── Phase 2: coach view is read-only; empty Address is hidden ─────
      await loginViaUi(tester, _kCoach, _kPwd);
      await _openMemberProfile(tester, _kMember);
      expect(find.text('Personal details'), findsOneWidget);
      expectSectionReadOnly(tester, find.byType(PersonalDetailsCard));
      expectSectionReadOnly(tester, find.byType(UserContactInfoCard));
      expect(
        find.byTooltip('Edit Bio'),
        findsNothing,
        reason: 'coach must not get the bio editor',
      );
      // The AddressCard widget stays in the tree but renders nothing
      // (SizedBox.shrink) when empty + read-only, so assert its title is gone.
      expect(
        find.text('Address'),
        findsNothing,
        reason: 'empty Address section is hidden from a read-only viewer',
      );
      await logout(tester);

      // ─── Phase 3: member self-profile is editable ──────────────────────
      await loginViaUi(tester, _kMember, _kPwd);
      await go(tester, '/memberzone/profile');
      await waitFor(
        tester,
        () => find.text('Personal details').evaluate().isNotEmpty,
        description: 'self profile to render',
      );
      expectSectionEditable(tester, find.byType(PersonalDetailsCard));
      await logout(tester);

      // ─── Phase 4: admin edits sections + bio, server + view reflect ────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openMemberProfile(tester, _kMember);

      // Personal details — first name.
      await tapSectionPencil(tester, find.byType(PersonalDetailsCard));
      await enterTextById(tester, 'firstName', _kEditedFirstName);
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () => _member(tester).firstName == _kEditedFirstName,
        description: 'first name to round-trip to the server',
      );

      // Contact — phone, typed with a space and a leading 0: stored, and
      // shown in the card on save, in international format (#31).
      await tapSectionPencil(tester, find.byType(UserContactInfoCard));
      await enterTextById(tester, 'phone', _kEditedPhoneTyped);
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () => _member(tester).phone == editedPhone,
        description: 'phone to reach the server as $editedPhone',
      );
      expect(
        find.text(editedPhone),
        findsOneWidget,
        reason: 'updated phone must show in the Contact card after save',
      );

      // Address — line 1 (was empty; now introduced).
      await tapSectionPencil(tester, find.byType(AddressCard));
      await enterTextById(tester, 'addrLine1', _kEditedAddrLine1);
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () => _member(tester).address?.addrLine1 == _kEditedAddrLine1,
        description: 'address line 1 to round-trip to the server',
      );

      // Bio — markdown editor.
      await editMarkdownField(
        tester,
        tooltip: 'Edit Bio',
        markdown: _kEditedBio,
      );
      await waitFor(
        tester,
        () => _member(tester).bio == _kEditedBio,
        description: 'bio to round-trip to the server',
      );
      await logout(tester);

      // ─── Phase 5: member confirms updates on their own profile ─────────
      await loginViaUi(tester, _kMember, _kPwd);
      await go(tester, '/memberzone/profile');
      await waitFor(
        tester,
        () => find.text(editedPhone).evaluate().isNotEmpty,
        description: 'updated phone visible on the self profile',
      );
      final self = container(tester).read(authStateProvider).valueOrNull!;
      expect(self.firstName, _kEditedFirstName);
      expect(self.address?.addrLine1, _kEditedAddrLine1);
      expect(self.bio, _kEditedBio);
      await logout(tester);

      // ─── Phase 6: cleanup ──────────────────────────────────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await softDeleteUserViaUi(tester, _kMember);
      await logout(tester);

      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await softDeleteUserViaUi(tester, _kAdmin);
      await softDeleteUserViaUi(tester, _kCoach);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

// ---------------------------------------------------------------------------
// Local helpers.
// ---------------------------------------------------------------------------

/// Reads the member's [UserPrivate]. Caller must be on the member's admin
/// profile (which watches `clUserPrivateProvider`).
UserPrivate _member(WidgetTester tester) {
  final v = container(tester).read(clUserPrivateProvider(_kMember)).valueOrNull;
  expect(v, isNotNull, reason: 'clUserPrivateProvider($_kMember) must be live');
  return v!;
}

Future<void> _openMemberProfile(WidgetTester tester, String username) async {
  await go(tester, '/memberzone/users');
  final card = find.byKey(ValueKey(username));
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: 'user card "$username" in the admin list',
  );
  await tester.tap(card);
  await settle(tester);
  await waitFor(
    tester,
    () => find.text('Personal details').evaluate().isNotEmpty,
    description: 'profile (Personal details section) to render',
  );
}
