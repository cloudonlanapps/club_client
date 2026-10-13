// workflow3: self-signup, profile updates, super-admin DOB edit, block/unblock.
//
// Flow:
//   1.  Login as bootstrap super-admin (sudo).
//   2.  Sudo creates `workflow3_admin` via the admin Add User form, then
//       toggles the Admin role chip on that user's profile.
//   3.  Logout sudo. The new member self-signs-up via /auth/signup.
//   4.  The member logs in (the onboarding-routing model authenticates
//       `registered` users) and is routed to /onboarding/welcome; they upload
//       an identity document and submit for review, flipping to `pending` and
//       seeing the submitted-confirmation card, then log out.
//   4b. Login as the admin and Reject the pending registration
//       via the "Act Now" banner with a review note — status returns to
//       `registered` with the note attached. The member logs back in, sees
//       the ReapplyVariant banner, edits a field, and resubmits; status
//       returns to `pending`.
//   5.  Login as the admin, open the pending registration via the "Act Now"
//       banner and Approve it (status → active).
//   6.  Login as the member; edit Bio + Achievements via the markdown editor;
//       edit every self-editable field (names, contact, address, emergency,
//       medical) via UserEditView. Verify each via clUserPrivateProvider.
//   7.  Logout / login the member again — re-verify all updates persist.
//   8.  Login as admin, view the member's profile, assert Bio/Achievements
//       and contact details match. Open the edit form and confirm the DOB
//       row is rendered as a read-only ReadOnlyField (not an editable
//       ShadDatePickerFormField). Modify a couple of admin-editable fields.
//   9.  Login as sudo, edit the member's DOB (super-admin only), verify.
//   10. Login as the member, re-verify admin- and sudo-set values.
//   11. Login as admin, block the member via the AdminUserProfileView.
//   12. Confirm the blocked member cannot log in.
//   13. Login as admin, unblock the member from the user-list user card.
//   14. Member logs in successfully again.
//   15. Cleanup: admin soft-deletes the member, sudo soft-deletes the admin.
//
// Resource-naming convention: every entity created by an integration test
// (users, events, venues, etc.) MUST be prefixed with the test's workflow
// number — e.g. `workflow3_user`, `workflow3_admin`. This guarantees
// per-test namespacing and prevents collisions when several integration
// tests run against the same server.
//
// The test relies on a freshly reset DB. The recommended way to run it:
//
//   just app-test-one app_test_server1.conf \
//       workflow3_user_profile_updates_test.dart
//
// Manual run:
//
//   flutter test integration_test/workflow3_user_profile_updates_test.dart \
//     --dart-define=CLUB_API_BASE_URL=http://127.0.0.1:8155/v1 \
//     --dart-define=SUDO_PASSWORD=... \
//     --dart-define=SUDO_USERNAME=sudo

import 'package:cl_club_app/cl_club_app.dart';
import 'package:cl_club_forms/cl_club_forms.dart' show SignupGender;
import 'package:cl_club_forms/src/widgets/read_only_field.dart'
    show ReadOnlyField;
import 'package:cl_club_members/src/widgets/address_card.dart';
import 'package:cl_club_members/src/widgets/personal_details_card.dart';
import 'package:cl_club_members/src/widgets/user_contact_info_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clUserPrivateProvider, imagePickerProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Capabilities, UserPrivate, UserStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, PickedImage, SectionEditButton;

import '_helpers/capabilities.dart';
import '_helpers/forms.dart' show ensureTextById;
import '_helpers/pump.dart' show pumpApp;

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

// Test-resource identities. All prefixed `workflow3_` per the integration
// test naming convention.
const _kMemberUsername = 'workflow3_user';
const _kMemberPassword = 'Workflow3Pwd!2024';
const _kMemberEmail = 'workflow3_user@example.com';
const _kMemberPhone = '7400543212';

// Phase 3b reconsider/reapply cycle (steps 4-5): the admin
// sends the pending registration back with a note, the member sees the
// ReapplyVariant banner, edits a field, and resubmits.
const _kReviewNote = 'Please re-upload a clearer identity document.';
const _kReapplyPhone = '7400543200';

const _kAdminUsername = 'workflow3_admin';
const _kAdminPassword = 'Workflow3AdmPwd!2024';
const _kAdminEmail = 'workflow3_admin@example.com';
const _kAdminPhone = '7400543213';

// Profile content used by Phase 5/6.
const _kBioMarkdown = 'workflow3 user bio: hockey is life.';
const _kAchievementsMarkdown =
    'workflow3 user achievements: skated since 2020.';

// User-edit values applied in Phase 6 (self-edit by the member).
const _kEditedFirstName = 'Wf3First';
const _kEditedMiddleName = 'Wf3Middle';
const _kEditedLastName = 'Wf3Last';
const _kEditedNickname = 'Wf3Nick';
const _kEditedEmail = 'workflow3_user_updated@example.com';
// Phones are typed as people type them (a space, a leading 0) and stored in
// international format (#31): `_kEdited*Phone` is the national number the
// stored value must end in, behind the stack's country code.
const _kEditedPhoneTyped = '74005 43299';
const _kEditedPhone = '7400543299';
const _kEditedAddrLine1 = 'Wf3 Line1';
const _kEditedAddrLine2 = 'Wf3 Line2';
const _kEditedCity = 'Wf3 City';
const _kEditedState = 'Karnataka';
const _kEditedPincode = '560001';
const _kEditedEmergencyName = 'Wf3 EC Name';
const _kEditedEmergencyRelation = 'Parent';
const _kEditedEmergencyPhoneTyped = '07400543298';
const _kEditedEmergencyPhone = '7400543298';
const _kEditedMedicalInfo = 'Wf3 medical notes';

// Admin overwrites applied in Phase 8.
const _kAdminEditedMedicalInfo = 'Wf3 admin-overridden medical';
const _kAdminEditedAddrLine1 = 'Wf3 admin-overridden line1';

// Super-admin overwrite applied in Phase 9.
final _kSudoEditedDob = DateTime.utc(1985, 6, 15);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env). '
      'Source: `pass club/dev/bootstrap/sudo`.',
    );
  }

  testWidgets(
    'workflow3 — self-signup, profile updates, super-admin DOB edit, '
    'block/unblock',
    (tester) async {
      // The user-edit form is taller than the default 1280x720 Linux desktop
      // window, so its lower fields fall below the fold where a synthesized
      // focus-tap inside tester.enterText silently misses (the field's value
      // never lands, the form fails validation, and Save never submits). Give
      // the test surface enough height that the whole form fits — the
      // documented alternative to per-field scrolling for long forms.
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(
        tester,
        apiBaseUrl: _kApiBaseUrl,
        // Stand in for the native file dialog so the document-upload step runs
        // headless — an integration test can't drive a real OS file chooser
        // (on Linux that's a zenity process the FilePicker stub can't touch).
        extraOverrides: [imagePickerProvider.overrideWithValue(_stubPicker)],
      );
      await _ensureLoggedOut(tester);

      // Identity verification decides the onboarding path: with it on, a
      // new member uploads a document before submitting for review; with it
      // off, sign-up lands them straight in `pending`.
      final caps = await stackCapabilities(
        baseUrl: _kApiBaseUrl,
        username: _kSudoUsername,
        password: _kSudoPassword,
      );
      final verification = caps.identityVerification;

      // ─── Phase 1: sudo creates workflow3_admin and grants Admin role ───
      await _loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      expect(
        _currentUser(tester),
        isNotNull,
        reason: 'sudo login should succeed against a fresh test DB',
      );

      await _createMemberViaUi(
        tester,
        username: _kAdminUsername,
        password: _kAdminPassword,
        email: _kAdminEmail,
        phone: _kAdminPhone,
        firstName: 'Workflow3',
        lastName: 'Admin',
      );
      await _grantAdminRoleViaUi(tester, _kAdminUsername);

      await _logout(tester);

      // ─── Phase 2: workflow3_user self-signs-up ─────────────────────────
      await _signupViaUi(
        tester,
        username: _kMemberUsername,
        password: _kMemberPassword,
        email: _kMemberEmail,
        phone: _kMemberPhone,
        firstName: 'Workflow3',
        lastName: 'User',
      );

      // ─── Phase 3: new member logs in → routed into onboarding ──────────
      // The onboarding-routing auth model lets a `registered` or `pending`
      // user authenticate (login is NOT rejected) and the router lands them
      // on /onboarding/welcome. With identity verification on, a
      // `registered` member uploads an identity document there and submits
      // for review, which flips their status to `pending` and shows the
      // "submitted" confirmation. With it off, sign-up already made them
      // `pending`, so the confirmation shows at once.
      await _loginViaUi(tester, _kMemberUsername, _kMemberPassword);
      expect(
        _currentUser(tester),
        isNotNull,
        reason:
            'a new member must authenticate (not be rejected) under '
            'the onboarding-routing model',
      );
      expect(
        (_currentUser(tester)! as UserPrivate).phone,
        storedPhone(caps, _kMemberPhone),
        reason:
            'Issue 31: a phone typed without a country code at sign-up is '
            'stored with the country code of the stack',
      );
      if (verification) {
        await _assertRoutedToOnboardingWelcome(tester);
        await _submitDocumentsViaUi(tester);
      }
      await _assertSubmittedConfirmation(tester);
      await _logoutFromOnboarding(tester);

      // ─── Phase 3b: admin reconsiders → member reapplies ────────────────
      // Before approving, exercise the reconsider/reapply cycle: the admin
      // sends the pending registration back with a note, the member sees the
      // ReapplyVariant banner, edits a field, and resubmits — returning the
      // flow to a fresh `pending` state for Phase 4 to approve.
      await _loginViaUi(tester, _kAdminUsername, _kAdminPassword);
      await _reconsiderViaActNowViaUi(tester, note: _kReviewNote);
      await _logout(tester);

      await _loginViaUi(tester, _kMemberUsername, _kMemberPassword);
      await _assertReapplyVariant(tester, note: _kReviewNote);
      await _reapplyViaUi(
        tester,
        newPhone: _kReapplyPhone,
        documentsRequired: verification,
      );

      // reapplyForSelf clears the note and the edited phone has persisted
      // server-side. With verification on the member stays `registered`
      // until the document step; with it off, "Submit changes" also
      // submits for review, so they are `pending` already.
      final afterReapply = await _refreshSelf(tester);
      expect(
        afterReapply.status,
        verification ? UserStatus.registered : UserStatus.pending,
        reason: verification
            ? 'reapply keeps the user in `registered` until documents'
            : 'without verification, reapply submits for review',
      );
      expect(
        (afterReapply.adminReviewNote ?? '').isEmpty,
        isTrue,
        reason: 'reapply must clear the admin review note',
      );
      expect(
        afterReapply.phone,
        storedPhone(caps, _kReapplyPhone),
        reason:
            'Issue 31: reapply must persist the edited phone, in '
            'international format',
      );

      // Resubmit documents → back to `pending` for the approval phase.
      if (verification) await _uploadIdentityDocAndSubmit(tester);
      await _assertSubmittedConfirmation(tester);
      await _logoutFromOnboarding(tester);

      // ─── Phase 4: admin approves the pending registration ──────────────
      // Pending users are surfaced via the "Act Now" banner on the admin
      // user list (they're filtered out of the main card list), which opens
      // the dedicated review surface where Approve flips them to `active`.
      await _loginViaUi(tester, _kAdminUsername, _kAdminPassword);
      await _approveViaActNowViaUi(tester);
      await _logout(tester);

      // ─── Phase 5: member edits Bio + Achievements ──────────────────────
      await _loginViaUi(tester, _kMemberUsername, _kMemberPassword);

      await _editMarkdownFieldViaUi(
        tester,
        tooltip: 'Edit Bio',
        markdown: _kBioMarkdown,
      );
      await _editMarkdownFieldViaUi(
        tester,
        tooltip: 'Edit Achievements',
        markdown: _kAchievementsMarkdown,
      );

      var fresh = await _refreshSelf(tester);
      expect(fresh.bio, _kBioMarkdown, reason: 'self-edit should persist bio');
      expect(
        fresh.achievements,
        _kAchievementsMarkdown,
        reason: 'self-edit should persist achievements',
      );

      // ─── Phase 6: member edits all self-editable fields ────────────────
      await _editSelfContactViaUi(tester, username: _kMemberUsername);

      fresh = await _refreshSelf(tester);
      _expectMemberSelfEditedFields(fresh, caps);

      // ─── Phase 7: logout / login round-trip — values still there ──────
      await _logout(tester);
      await _loginViaUi(tester, _kMemberUsername, _kMemberPassword);
      fresh = await _refreshSelf(tester);
      expect(fresh.bio, _kBioMarkdown);
      expect(fresh.achievements, _kAchievementsMarkdown);
      _expectMemberSelfEditedFields(fresh, caps);
      await _logout(tester);

      // ─── Phase 8: admin verifies + edits non-DOB fields ────────────────
      await _loginViaUi(tester, _kAdminUsername, _kAdminPassword);

      await _openAdminProfileViaUi(tester, _kMemberUsername);
      // Admin sees the member's bio and achievements live on the profile.
      // AdminUserProfileView watches clUserPrivateProvider, so _refreshOther
      // is safe to call here.
      var asAdmin = await _refreshOther(tester, _kMemberUsername);
      expect(
        asAdmin.bio,
        _kBioMarkdown,
        reason: 'admin must see member bio after self-edit',
      );
      expect(
        asAdmin.achievements,
        _kAchievementsMarkdown,
        reason: 'admin must see member achievements after self-edit',
      );
      _expectMemberSelfEditedFields(asAdmin, caps);

      // DOB is read-only for a plain admin — verify in the personal editor,
      // then close it without changes.
      await _openSectionEditor(tester, PersonalDetailsCard, 'firstName');
      _expectDobIsReadOnly(tester);
      await _cancelSectionDialog(tester, 'firstName');

      // Medical notes live in the contact editor; address line in the address
      // editor — each saved through its own section dialog.
      await _openSectionEditor(tester, UserContactInfoCard, 'email');
      await _enterTextById(tester, 'medicalInfo', _kAdminEditedMedicalInfo);
      await _saveSectionDialog(tester, 'email');

      await _openSectionEditor(tester, AddressCard, 'addrLine1');
      await _enterTextById(tester, 'addrLine1', _kAdminEditedAddrLine1);
      await _saveSectionDialog(tester, 'addrLine1');

      // After save the dialog pops back to AdminUserProfileView (which still
      // watches clUserPrivateProvider).
      asAdmin = await _refreshOther(tester, _kMemberUsername);
      expect(asAdmin.medicalInfo, _kAdminEditedMedicalInfo);
      expect(asAdmin.address?.addrLine1, _kAdminEditedAddrLine1);
      await _logout(tester);

      // ─── Phase 9: super-admin edits DOB ────────────────────────────────
      await _loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await _openAdminProfileViaUi(tester, _kMemberUsername);
      await _openSectionEditor(tester, PersonalDetailsCard, 'firstName');

      _setShadFormValues(tester, {'dateOfBirthUtc': _kSudoEditedDob});
      await tester.pump();
      await _saveSectionDialog(tester, 'firstName');

      final asSudo = await _refreshOther(tester, _kMemberUsername);
      expect(
        asSudo.dateOfBirthUtc,
        _kSudoEditedDob,
        reason: 'super-admin must be able to edit DOB',
      );
      expect(
        asSudo.medicalInfo,
        _kAdminEditedMedicalInfo,
        reason: 'admin-set medical notes must survive super-admin save',
      );
      expect(
        asSudo.address?.addrLine1,
        _kAdminEditedAddrLine1,
        reason: 'admin-set address line must survive super-admin save',
      );
      await _logout(tester);

      // ─── Phase 10: member confirms admin/sudo-applied updates ──────────
      await _loginViaUi(tester, _kMemberUsername, _kMemberPassword);
      final asMember = await _refreshSelf(tester);
      expect(asMember.dateOfBirthUtc, _kSudoEditedDob);
      expect(asMember.medicalInfo, _kAdminEditedMedicalInfo);
      expect(asMember.address?.addrLine1, _kAdminEditedAddrLine1);
      await _logout(tester);

      // ─── Phase 11: admin blocks the member ─────────────────────────────
      await _loginViaUi(tester, _kAdminUsername, _kAdminPassword);
      await _openAdminProfileViaUi(tester, _kMemberUsername);
      await _invokeProfileActionViaUi(tester, 'Block');
      await _logout(tester);

      // ─── Phase 12: blocked member cannot log in ────────────────────────
      await _attemptLoginExpectFailure(
        tester,
        _kMemberUsername,
        _kMemberPassword,
      );

      // ─── Phase 13: admin unblocks the member ───────────────────────────
      await _loginViaUi(tester, _kAdminUsername, _kAdminPassword);
      await _unblockUserFromListViaUi(tester, _kMemberUsername);
      await _logout(tester);

      // ─── Phase 14: member logs in successfully again ───────────────────
      await _loginViaUi(tester, _kMemberUsername, _kMemberPassword);
      expect(
        _currentUser(tester),
        isNotNull,
        reason: 'unblocked user must be able to log in again',
      );
      await _logout(tester);

      // ─── Phase 15: cleanup ─────────────────────────────────────────────
      await _loginViaUi(tester, _kAdminUsername, _kAdminPassword);
      await _softDeleteUserViaUi(tester, _kMemberUsername);
      await _logout(tester);

      await _loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await _softDeleteUserViaUi(tester, _kAdminUsername);
      await _logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

// ---------------------------------------------------------------------------
// App / auth helpers (parallel with workflow1/workflow2). The app is mounted
// via the shared `pumpApp` from _helpers/pump.dart, which wires the test
// server, in-memory storage stubs, AND the appLogoUriProvider override (a
// previous local `_pumpApp` omitted the logo override, which surfaced as an
// "Asset not found: placeholder_logo.png" failure even when assertions
// passed). Consolidating on the shared helper removes that drift.
// ---------------------------------------------------------------------------

/// A valid 32x32 PNG used as the fixture identity document. It must be a
/// well-formed image: the server converts uploaded images to WebP via
/// ImageMagick, which rejects malformed/zero-area PNGs (a 1x1 stub with a bad
/// IDAT CRC fails conversion with "exit 3"). This 32x32 solid image converts
/// cleanly and stays well under the 2 MB cap.
const List<int> _fixturePng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x20,
  0x00,
  0x00,
  0x00,
  0x20,
  0x08,
  0x02,
  0x00,
  0x00,
  0x00,
  0xFC,
  0x18,
  0xED,
  0xA3,
  0x00,
  0x00,
  0x00,
  0x2B,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0xDA,
  0xED,
  0xCD,
  0x41,
  0x01,
  0x00,
  0x40,
  0x04,
  0x00,
  0x30,
  0x2E,
  0x97,
  0x60,
  0x22,
  0x8A,
  0x75,
  0x25,
  0xF8,
  0x6D,
  0x05,
  0x96,
  0xD5,
  0x13,
  0x97,
  0x5E,
  0x1C,
  0x13,
  0x08,
  0x04,
  0x02,
  0x81,
  0x40,
  0x20,
  0x10,
  0x08,
  0x04,
  0x5B,
  0x3E,
  0x8D,
  0x39,
  0x01,
  0xBC,
  0xB1,
  0xB2,
  0x4F,
  0x45,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

/// Stand-in for the native image picker so the onboarding "submit documents"
/// step runs headless. Injected via `imagePickerProvider` (see the override in
/// `_pumpApp`), so the real OS file chooser — which an integration test can't
/// drive — never opens, while the rest of the upload + submit path runs
/// unchanged.
Future<PickedImage?> _stubPicker() async => const PickedImage(
  bytes: _fixturePng,
  filename: 'workflow3_aadhaar.png',
  mimeType: 'image/png',
);

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(App)));

Object? _currentUser(WidgetTester tester) =>
    _container(tester).read(authStateProvider).valueOrNull;

Future<void> _ensureLoggedOut(WidgetTester tester) async {
  if (_currentUser(tester) != null) await _logout(tester);
}

Future<void> _logout(WidgetTester tester) async {
  await _container(tester).read(authStateProvider.notifier).logout();
  await _settle(tester);
}

Future<void> _go(WidgetTester tester, String location) async {
  // Reading the router from the provider container avoids the "No GoRouter
  // found in context" issue you get when calling GoRouter.of() with the App
  // element — the router lives below App in the widget tree.
  _container(tester).read(routerProvider).go(location);
  await _settle(tester);
}

/// Reads the current logged-in user's [UserPrivate] from [authStateProvider].
/// Waits until the value is available (it's loaded as part of every login).
///
/// Use this for self-state checks. Reading via
/// `clUserPrivateProvider(...).future` from the test container hangs because
/// the autoDispose provider has no widget-tree listener after navigation away
/// from screens that watch it.
Future<UserPrivate> _refreshSelf(WidgetTester tester) async {
  final container = _container(tester)
    // Make sure auth re-fetches in case a server-side mutation just happened.
    ..invalidate(authStateProvider);
  // Wait for the re-fetch itself, not just a value: a refreshing provider
  // keeps its previous value, and a re-fetch still in flight would land
  // after a following logout and sign the user back in.
  await _waitFor(
    tester,
    () {
      final auth = container.read(authStateProvider);
      return !auth.isLoading && auth.valueOrNull != null;
    },
    description: 'authStateProvider to re-fetch the current user',
  );
  return container.read(authStateProvider).valueOrNull!;
}

/// Reads [clUserPrivateProvider] for [username]. The caller MUST already be
/// on a screen that watches this provider (e.g. AdminUserProfileView or
/// UserEditView) so the autoDispose provider stays alive long enough for
/// the future to resolve.
Future<UserPrivate> _refreshOther(
  WidgetTester tester,
  String username,
) async {
  final container = _container(tester)
    ..invalidate(clUserPrivateProvider(username));
  await _waitFor(
    tester,
    () => container.read(clUserPrivateProvider(username)).valueOrNull != null,
    description: 'clUserPrivateProvider($username) to populate',
  );
  return container.read(clUserPrivateProvider(username)).valueOrNull!;
}

// ---------------------------------------------------------------------------
// UI flows
// ---------------------------------------------------------------------------

Future<void> _loginViaUi(
  WidgetTester tester,
  String username,
  String password,
) async {
  await _go(tester, '/auth/login');

  // If a previous _attemptLoginExpectFailure left the screen on a status
  // card (AccountPendingView / AccountBlockedView / AccountLeftView — all
  // shown by LoginView for status-coded rejections), dismiss it so the
  // login form is mounted before we try to fill it.
  final back = find.widgetWithText(ShadButton, 'Back to sign in');
  if (back.evaluate().isNotEmpty) {
    _invokeShadButton(tester, back, reason: 'dismiss status card');
    await _settle(tester);
  }

  // Wait for the login form to mount.
  await _waitFor(
    tester,
    () => find
        .byWidgetPredicate(
          (w) => w is ShadInputFormField && w.id == 'username',
        )
        .evaluate()
        .isNotEmpty,
    description: 'login form to mount',
  );

  await _enterTextById(tester, 'username', username);
  await _enterTextById(tester, 'password', password);
  // No Enter here: in the password field it signs in (#103), and the
  // button pressed below would then read "Signing in…".
  await tester.pump();

  // As in the shared loginViaUi: a field emptied after it was typed is
  // typed again, or Sign in validates an empty form and starts nothing.
  await ensureTextById(tester, 'username', username);
  await ensureTextById(tester, 'password', password);
  await _submitFormContaining(tester, fieldId: 'username', label: 'Sign in');

  try {
    await _waitFor(
      tester,
      () => _currentUser(tester) != null,
      description: 'login completion for $username',
    );
  } catch (e) {
    final auth = _container(tester).read(authStateProvider);
    // Integration test diagnostic output; `print` is the intended channel
    // because the logger framework isn't wired in tests.
    // ignore: avoid_print
    print(
      '[test] login failed for "$username": '
      'isLoading=${auth.isLoading} '
      'value=${auth.valueOrNull} '
      'error=${auth.error} '
      'passwordLength=${password.length}',
    );
    rethrow;
  }
}

Future<void> _attemptLoginExpectFailure(
  WidgetTester tester,
  String username,
  String password,
) async {
  await _go(tester, '/auth/login');
  await _waitFor(
    tester,
    () => find
        .byWidgetPredicate(
          (w) => w is ShadInputFormField && w.id == 'username',
        )
        .evaluate()
        .isNotEmpty,
    description: 'login form to mount',
  );

  await _enterTextById(tester, 'username', username);
  await _enterTextById(tester, 'password', password);
  // No Enter here: in the password field it signs in (#103), and the
  // button pressed below would then read "Signing in…".
  await tester.pump();

  // As in the shared loginViaUi: a field emptied after it was typed is
  // typed again, or Sign in validates an empty form and starts nothing.
  await ensureTextById(tester, 'username', username);
  await ensureTextById(tester, 'password', password);
  await _submitFormContaining(tester, fieldId: 'username', label: 'Sign in');

  // Settle into a non-loading null state — auth notifier sets state.error on
  // failure (account blocked, invalid credentials, …) and state.value stays
  // null, so this asserts the rejection without binding to a specific code.
  await _waitFor(
    tester,
    () {
      final auth = _container(tester).read(authStateProvider);
      return !auth.isLoading && auth.valueOrNull == null;
    },
    description: 'login attempt for $username to be rejected',
  );
  expect(
    _currentUser(tester),
    isNull,
    reason: 'rejected login must leave authStateProvider null',
  );
}

/// Asserts the onboarding-routing model: a freshly `registered` user who has
/// just logged in is routed to /onboarding/welcome, where the IntroCard
/// invites them to upload documents. Replaces the old expectation that a
/// pending user's login was rejected with an "Awaiting approval" card.
Future<void> _assertRoutedToOnboardingWelcome(WidgetTester tester) async {
  await _waitFor(
    tester,
    () => find.text('Welcome aboard - almost!').evaluate().isNotEmpty,
    description: 'onboarding welcome IntroCard for the registered user',
  );
  expect(
    find.widgetWithText(ShadButton, 'Continue'),
    findsOneWidget,
    reason: 'IntroCard should offer a Continue button into document upload',
  );
}

/// Drives the onboarding document-upload step the way a real user does:
/// Continue → submit-documents → add a (stubbed) identity document → accept
/// the privacy policy → Submit. `submitForReviewForSelf` then flips the user
/// to `pending` and the router redirect bounces back to /onboarding/welcome.
Future<void> _submitDocumentsViaUi(WidgetTester tester) async {
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Continue'),
    reason: 'IntroCard Continue button',
  );
  await _settle(tester);
  await _uploadIdentityDocAndSubmit(tester);
}

/// The document-upload + privacy + Submit core of the submit-documents view,
/// without the leading IntroCard "Continue" tap. Shared between the first
/// submission (reached via [_submitDocumentsViaUi]'s Continue) and the
/// post-reapply resubmission (where `reapplyForSelf`'s onContinue has already
/// routed straight to /onboarding/submit-documents — there is no IntroCard).
Future<void> _uploadIdentityDocAndSubmit(WidgetTester tester) async {
  // The add-document tile renders a plus icon; tapping it triggers the
  // (stubbed) file picker, which returns a fixture PNG the field uploads.
  await _waitFor(
    tester,
    () => find.byIcon(Icons.add).evaluate().isNotEmpty,
    description: 'identity-document add tile on the submit-documents view',
  );
  await tester.tap(find.byIcon(Icons.add).first);
  await _settle(tester);
  // Give the upload (file picker → server media upload → slot) time to land.
  await tester.pump(const Duration(seconds: 2));
  await _settle(tester);

  // Accept the privacy policy by invoking the inner ShadCheckbox.onChanged
  // directly (the small hit-target is unreliable in widget tests).
  await _waitFor(
    tester,
    () => find
        .byWidgetPredicate(
          (w) => w is ShadCheckboxFormField && w.id == 'privacyAccepted',
        )
        .evaluate()
        .isNotEmpty,
    description: 'privacy checkbox on the submit-documents form',
  );
  final innerCheckbox = find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is ShadCheckboxFormField && w.id == 'privacyAccepted',
    ),
    matching: find.byType(ShadCheckbox),
  );
  expect(
    innerCheckbox,
    findsOneWidget,
    reason: 'expected inner ShadCheckbox inside the privacy field',
  );
  tester.widget<ShadCheckbox>(innerCheckbox).onChanged?.call(true);
  await _settle(tester);

  // Submit enables once a document is uploaded; pressing it validates the
  // consent ticked above.
  await _waitFor(
    tester,
    () {
      final toast = _firstErrorToastMessage(tester);
      if (toast != null) {
        throw TestFailure('document submission blocked. Toast: "$toast"');
      }
      // An upload failure surfaces as inline field error text, not a toast.
      if (find.textContaining("Couldn't upload").evaluate().isNotEmpty) {
        throw TestFailure('identity-document upload failed on the server');
      }
      final submit = find.widgetWithText(ShadButton, 'Submit');
      return submit.evaluate().isNotEmpty &&
          tester.widget<ShadButton>(submit).onPressed != null;
    },
    description: 'Submit button to enable after the upload',
  );
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Submit'),
    reason: 'submit-documents Submit button',
  );
  await _settle(tester);
}

/// After submission the user is `pending`; the router shows the
/// SubmittedConfirmation card on /onboarding/welcome.
Future<void> _assertSubmittedConfirmation(WidgetTester tester) async {
  await _waitFor(
    tester,
    () => find.text('Thanks for signing up!').evaluate().isNotEmpty,
    description: 'submitted-confirmation card after document submission',
  );
  expect(
    find.widgetWithText(ShadButton, 'Back to sign in'),
    findsOneWidget,
    reason: 'pending onboarding screen should offer Back to sign in',
  );
}

/// Logs out from the onboarding "submitted" screen via its Back to sign in
/// button (which calls authStateProvider.notifier.logout()).
Future<void> _logoutFromOnboarding(WidgetTester tester) async {
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Back to sign in'),
    reason: 'onboarding Back to sign in button',
  );
  await _waitFor(
    tester,
    () => _currentUser(tester) == null,
    description: 'logout after onboarding submission',
  );
  await _settle(tester);
}

/// Approves the pending registration through the admin "Act Now" banner on
/// the user list (pending users are filtered out of the main card list and
/// surfaced via this banner). The banner opens the review surface, where the
/// Approve action flips the user to `active`.
Future<void> _approveViaActNowViaUi(WidgetTester tester) async {
  await _go(tester, '/memberzone/users');

  // PendingApprovalsBanner renders only when there is ≥1 pending user.
  await _waitFor(
    tester,
    () => find.widgetWithText(ShadButton, 'Act Now').evaluate().isNotEmpty,
    description: 'pending-approvals "Act Now" banner on the admin user list',
  );
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Act Now'),
    reason: 'pending-approvals Act Now button',
  );
  await _settle(tester);

  // The review surface shows the pending user with an Approve action that
  // fires immediately (no reason dialog).
  await _waitFor(
    tester,
    () => find.widgetWithText(ShadButton, 'Approve').evaluate().isNotEmpty,
    description: 'Approve button on the admin review surface',
  );
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Approve'),
    reason: 'admin review Approve button',
  );
  await _settle(tester);

  // Approval clears the pending queue — the Approve button disappears. A
  // destructive toast means the approval failed.
  await _waitFor(
    tester,
    () {
      final toast = _firstErrorToastMessage(tester);
      if (toast != null) {
        throw TestFailure('approval failed. Toast: "$toast"');
      }
      return find.widgetWithText(ShadButton, 'Approve').evaluate().isEmpty;
    },
    description: 'Approve button to disappear after approval',
  );
  await tester.pump(const Duration(seconds: 1));
}

/// Sends the pending registration back for reconsideration through the admin
/// "Act Now" banner. The review surface's Reject action opens a reason dialog;
/// confirming it calls `reconsiderUser`, which flips the user
/// `pending` → `registered` and stores [note] as their `adminReviewNote`.
Future<void> _reconsiderViaActNowViaUi(
  WidgetTester tester, {
  required String note,
}) async {
  await _go(tester, '/memberzone/users');

  await _waitFor(
    tester,
    () => find.widgetWithText(ShadButton, 'Act Now').evaluate().isNotEmpty,
    description: 'pending-approvals "Act Now" banner on the admin user list',
  );
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Act Now'),
    reason: 'pending-approvals Act Now button',
  );
  await _settle(tester);

  // Reject opens the reason dialog rather than firing immediately.
  await _waitFor(
    tester,
    () => find.widgetWithText(ShadButton, 'Reject').evaluate().isNotEmpty,
    description: 'Reject button on the admin review surface',
  );
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Reject'),
    reason: 'admin review Reject button',
  );
  await _settle(tester);

  // The reason dialog hosts a single ShadInput; type the note, then confirm.
  // Scope to the dialog so we never pick up an input on the surface behind it.
  final reasonInput = find.descendant(
    of: find.byType(ShadDialog),
    matching: find.byType(ShadInput),
  );
  await _waitFor(
    tester,
    () => reasonInput.evaluate().isNotEmpty,
    description: 'reason dialog ShadInput for the reconsider note',
  );
  await tester.enterText(reasonInput.first, note);
  await _settle(tester);
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Confirm Reject'),
    reason: 'reason dialog Confirm Reject button',
  );
  await _settle(tester);

  // Reconsider clears the pending queue — the Reject button disappears. A
  // destructive toast means the reconsider call failed.
  await _waitFor(
    tester,
    () {
      final toast = _firstErrorToastMessage(tester);
      if (toast != null) {
        throw TestFailure('reconsider failed. Toast: "$toast"');
      }
      return find.widgetWithText(ShadButton, 'Reject').evaluate().isEmpty;
    },
    description: 'Reject button to disappear after reconsider',
  );
  await tester.pump(const Duration(seconds: 1));
}

/// Asserts the reconsidered user lands on the ReapplyVariant of
/// /onboarding/welcome: the registration form titled "Update your
/// registration", with the admin [note] rendered in the banner.
Future<void> _assertReapplyVariant(
  WidgetTester tester, {
  required String note,
}) async {
  await _waitFor(
    tester,
    () => find.text('Update your registration').evaluate().isNotEmpty,
    description: 'ReapplyVariant form for the reconsidered user',
  );
  expect(
    find.text(note),
    findsOneWidget,
    reason: 'ReapplyVariant must surface the admin review note as a banner',
  );
  expect(
    find.widgetWithText(ShadButton, 'Submit changes'),
    findsOneWidget,
    reason: 'reapply form should offer a "Submit changes" CTA',
  );
}

/// Edits a single field (phone) on the ReapplyVariant form and submits.
/// `reapplyForSelf` keeps status `registered` and clears `adminReviewNote`.
/// When [documentsRequired], the view's onContinue then routes to
/// /onboarding/submit-documents; otherwise it submits for review, and the
/// submitted confirmation follows.
Future<void> _reapplyViaUi(
  WidgetTester tester, {
  required String newPhone,
  required bool documentsRequired,
}) async {
  // The form is pre-filled from the user's current values (username pinned,
  // password hidden); changing the phone is enough to exercise the edit path.
  await _enterTextById(tester, 'phone', newPhone);
  await _settle(tester);

  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Submit changes'),
    reason: 'reapply "Submit changes" button',
  );
  await _settle(tester);

  // On success onContinue routes to submit-documents (the add-document tile
  // appears) or, without documents, to the submitted confirmation. On
  // failure the reapply form stays mounted with a toast.
  await _waitFor(
    tester,
    () {
      final toast = _firstErrorToastMessage(tester);
      if (toast != null) {
        throw TestFailure('reapply submission failed. Toast: "$toast"');
      }
      return documentsRequired
          ? find.byIcon(Icons.add).evaluate().isNotEmpty
          : find.text('Thanks for signing up!').evaluate().isNotEmpty;
    },
    description: documentsRequired
        ? 'submit-documents view after a successful reapply'
        : 'submitted confirmation after a successful reapply',
  );
  await _settle(tester);
}

Future<void> _signupViaUi(
  WidgetTester tester, {
  required String username,
  required String password,
  required String email,
  required String phone,
  required String firstName,
  required String lastName,
}) async {
  // Sub-flow start: open the login screen, then tap the "Sign up" link to
  // reach the signup form (matches the user-facing path).
  await _go(tester, '/auth/login');
  await _waitFor(
    tester,
    () => find.widgetWithText(ShadButton, 'Sign up').evaluate().isNotEmpty,
    description: '"Sign up" link on the login screen',
  );
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Sign up'),
    reason: '"Sign up" link on login screen',
  );
  await _settle(tester);

  // Wait for the signup form (identifiable by its title — both forms have a
  // ShadInputFormField id='username').
  await _waitFor(
    tester,
    () => find.text('Create an account').evaluate().isNotEmpty,
    description: 'signup form to mount',
  );

  await _enterTextById(tester, 'username', username);
  // Pump so the username controller listener fires and rebuilds the row
  // that owns the "Check availability" button (it is gated on
  // username.isNotEmpty).
  await _settle(tester);

  // The signup form gates the Create-account button on a successful
  // username-availability check (signup_view.canSubmit). Tap "Check
  // availability" and wait for the "Available" message before proceeding —
  // otherwise the submit button stays disabled.
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Check availability'),
    reason: '"Check availability" button',
  );
  await _settle(tester);
  await _waitFor(
    tester,
    () => find.text('Available').evaluate().isNotEmpty,
    description: 'username "$username" to be reported available',
  );

  await _enterTextById(tester, 'email', email);
  await _enterTextById(tester, 'password', password);
  // SignupForm requires a matching confirmPassword; without it the form
  // never validates and the Create-account button stays disabled.
  await _enterTextById(tester, 'confirmPassword', password);
  await _enterTextById(tester, 'firstName', firstName);
  await _enterTextById(tester, 'lastName', lastName);
  await _enterTextById(tester, 'phone', phone);

  // The gender field is a ShadSelectFormField<SignupGender> (forms speak the
  // form-local type, not the SDK Gender enum).
  _setShadFormValues(tester, {
    'gender': SignupGender.preferNotToSay,
    'dateOfBirthUtc': DateTime.utc(1990, 1, 1),
  });
  await tester.pump();

  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Create account'),
    reason: '"Create account" submit button',
  );
  await _settle(tester);

  // Success: signup view shows the confirmation toast then navigates back to
  // /auth/login (router callback). On failure the form stays mounted with a
  // destructive toast — fast-fail with the toast text in that case.
  await _waitFor(
    tester,
    () {
      final toast = _firstErrorToastMessage(tester);
      if (toast != null) {
        throw TestFailure(
          'signup form rejected the submission. Toast: "$toast"',
        );
      }
      return find
          .widgetWithText(ShadButton, 'Create account')
          .evaluate()
          .isEmpty;
    },
    description: 'signup form to close after submit',
  );
}

Future<void> _createMemberViaUi(
  WidgetTester tester, {
  required String username,
  required String password,
  required String email,
  required String phone,
  required String firstName,
  required String lastName,
}) async {
  await _go(tester, '/memberzone/users');
  final addUserButton = find.widgetWithText(ActionButton, '+ Add user');
  await _waitFor(
    tester,
    () => addUserButton.evaluate().isNotEmpty,
    description: '"+ Add user" button on the admin users list',
  );
  await tester.tap(addUserButton);
  await _settle(tester);

  await _waitFor(
    tester,
    () => find
        .byWidgetPredicate(
          (w) => w is ShadInputFormField && w.id == 'username',
        )
        .evaluate()
        .isNotEmpty,
    description: 'admin Add User form to mount',
  );

  await _enterTextById(tester, 'username', username);

  // The Create user button is gated on `canSubmit` (matches SignupView).
  // Run the username availability check before attempting submit.
  final checkButton = find.widgetWithText(ShadButton, 'Check availability');
  await _waitFor(
    tester,
    () => checkButton.evaluate().isNotEmpty,
    description: '"Check availability" button to appear',
  );
  _invokeShadButton(tester, checkButton, reason: '"Check availability" button');
  await _settle(tester);
  await _waitFor(
    tester,
    () => find.text('Available').evaluate().isNotEmpty,
    description: 'username availability to report "Available"',
  );

  // The Add User form defaults `useDefaultPassword=true`, which hides the
  // password + confirmPassword fields. Invoke the checkbox's onChanged
  // directly so the form value map AND the parent's local visibility state
  // both flip.
  final useDefaultCheckbox = find.byWidgetPredicate(
    (w) => w is ShadCheckboxFormField && w.id == 'useDefaultPassword',
  );
  expect(
    useDefaultCheckbox,
    findsOneWidget,
    reason: 'expected "useDefaultPassword" checkbox on Add User form',
  );
  final innerCheckbox = find.descendant(
    of: useDefaultCheckbox,
    matching: find.byType(ShadCheckbox),
  );
  expect(
    innerCheckbox,
    findsOneWidget,
    reason: 'expected inner ShadCheckbox inside useDefaultPassword field',
  );
  tester.widget<ShadCheckbox>(innerCheckbox).onChanged?.call(false);
  await _settle(tester);
  await _waitFor(
    tester,
    () => find
        .byWidgetPredicate((w) => w is ShadInputFormField && w.id == 'password')
        .evaluate()
        .isNotEmpty,
    description: 'password field to appear after toggling off default password',
  );

  await _enterTextById(tester, 'password', password);
  await _enterTextById(tester, 'confirmPassword', password);
  await _enterTextById(tester, 'firstName', firstName);
  await _enterTextById(tester, 'lastName', lastName);
  await _enterTextById(tester, 'phone', phone);
  await _enterTextById(tester, 'email', email);

  // UserForm gender field is a ShadSelectFormField<SignupGender>.
  _setShadFormValues(tester, {
    'gender': SignupGender.preferNotToSay,
    'dateOfBirthUtc': DateTime.utc(1990, 1, 1),
  });
  await tester.pump();

  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Create user'),
    reason: '"Create user" submit button',
  );
  await _settle(tester);

  await _waitFor(
    tester,
    () {
      final toast = _firstErrorToastMessage(tester);
      if (toast != null) {
        throw TestFailure(
          'admin Add User form rejected the submission. Toast: "$toast"',
        );
      }
      return find.widgetWithText(ShadButton, 'Create user').evaluate().isEmpty;
    },
    description: 'admin Add User form to close after submit',
  );
}

/// Tap the "Admin" role chip on a user's profile to grant the Admin role.
/// Asserts the UserPrivate model reflects `roles.isAdmin == true` afterwards.
Future<void> _grantAdminRoleViaUi(
  WidgetTester tester,
  String username,
) async {
  await _openAdminProfileViaUi(tester, username);

  // Wait for the RolesSection to render (its instructional caption is the
  // most stable anchor inside the section).
  await _waitFor(
    tester,
    () => find
        .text('Toggle the roles assigned to this user.')
        .evaluate()
        .isNotEmpty,
    description: 'RolesSection to mount',
  );

  // RolesSection renders each role as a ShadCheckbox with a label. Invoke
  // the Admin checkbox's onChanged directly — tapping the small hit-target
  // is unreliable in widget tests.
  final adminCheckbox = find.byWidgetPredicate(
    (w) =>
        w is ShadCheckbox &&
        w.label is Text &&
        (w.label! as Text).data == 'Make this user an Admin',
  );
  expect(
    adminCheckbox,
    findsOneWidget,
    reason: 'expected an Admin role checkbox on the profile',
  );
  final cb = tester.widget<ShadCheckbox>(adminCheckbox);
  expect(
    cb.onChanged,
    isNotNull,
    reason: 'Admin role checkbox should be enabled',
  );
  cb.onChanged!.call(true);
  await _settle(tester);

  // The role-toggle handler shows a transient toast that is easy to miss
  // between pumps; fast-fail on a destructive one and otherwise poll the
  // canonical source of truth — the user's roles via clUserPrivateProvider.
  await _waitFor(
    tester,
    () {
      final destructive = _firstErrorToastMessage(tester);
      if (destructive != null) {
        throw TestFailure('role toggle failed. Toast: "$destructive"');
      }
      // Synchronous read on the family provider; the master notifier flips
      // local state once the server returns 200, so this becomes truthy
      // without needing another network round-trip.
      final value = _container(
        tester,
      ).read(clUserPrivateProvider(username)).valueOrNull;
      return value != null && value.roles.isAdmin;
    },
    description: 'Admin role to take effect on $username',
  );
}

/// Navigate from the admin user list to a specific user's profile by tapping
/// the user card (no `go()` to the deep route — must use the user-facing
/// path).
Future<void> _openAdminProfileViaUi(
  WidgetTester tester,
  String username,
) async {
  await _go(tester, '/memberzone/users');
  final userCard = find.byKey(ValueKey(username));
  await _waitFor(
    tester,
    () => userCard.evaluate().isNotEmpty,
    description: 'user card "$username" to appear in the admin list',
  );
  await tester.tap(userCard);
  await _settle(tester);
}

/// Open the Bio or Achievements editor (matched by its tooltip), enter
/// markdown, tap Save, and wait for the editor dialog to close.
Future<void> _editMarkdownFieldViaUi(
  WidgetTester tester, {
  required String tooltip,
  required String markdown,
}) async {
  // Always start from the self profile so the EditableMarkdown widgets are
  // mounted with their save callbacks wired (ProfileView delegates to
  // UserProfileView with onBioSave/onAchievementsSave set).
  await _go(tester, '/memberzone/profile');

  await _waitFor(
    tester,
    () => find.byTooltip(tooltip).evaluate().isNotEmpty,
    description: 'pencil icon with tooltip "$tooltip"',
  );

  await tester.tap(find.byTooltip(tooltip));
  await _settle(tester);

  // The MarkdownEditorDialog is a centered Dialog with a single editable
  // TextField (the markdown source). The Save button is a ShadButton.
  await _waitFor(
    tester,
    () => find.widgetWithText(ShadButton, 'Save').evaluate().isNotEmpty,
    description: 'markdown editor dialog to open',
  );

  final field = find.byType(TextField);
  expect(
    field,
    findsOneWidget,
    reason: 'expected one editable TextField in the markdown editor',
  );
  await tester.enterText(field, markdown);
  await tester.pump();

  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Save'),
    reason: 'markdown editor Save button',
  );
  await _settle(tester);

  await _waitFor(
    tester,
    () => find.widgetWithText(ShadButton, 'Save').evaluate().isEmpty,
    description: 'markdown editor dialog to close',
  );
}

/// Taps a section card's edit pencil. The pencil is a [SectionEditButton]
/// wrapping a `LucideIcons.pencil` icon, located by scoping to the given
/// [cardType] (the card only renders the pencil when the viewer may edit the
/// section). Tapping it flips the card into its inline editor. Invoking
/// `onTap` directly keeps this screen-size independent. Used by both the self
/// profile and the admin profile.
Future<void> _tapSectionPencil(WidgetTester tester, Type cardType) async {
  final pencil = find.descendant(
    of: find.byElementPredicate((e) => e.widget.runtimeType == cardType),
    matching: find.byType(SectionEditButton),
  );
  await _waitFor(
    tester,
    () => pencil.evaluate().isNotEmpty,
    description: 'edit pencil on the $cardType section',
  );
  tester.widget<SectionEditButton>(pencil.first).onTap.call();
  await _settle(tester);
}

bool _fieldMounted(WidgetTester tester, String id) => find
    .byWidgetPredicate((w) => w is ShadInputFormField && w.id == id)
    .evaluate()
    .isNotEmpty;

/// Opens a section editor dialog from the current profile by tapping its
/// card pencil, then waits for [anchorFieldId] to mount.
Future<void> _openSectionEditor(
  WidgetTester tester,
  Type cardType,
  String anchorFieldId,
) async {
  await _tapSectionPencil(tester, cardType);
  await _waitFor(
    tester,
    () => _fieldMounted(tester, anchorFieldId),
    description: '$cardType editor dialog to mount',
  );
}

/// Submit a section editor dialog via its "Save" button, then wait for it to
/// close (the [anchorFieldId] field unmounts). Fast-fails on an error toast.
Future<void> _saveSectionDialog(
  WidgetTester tester,
  String anchorFieldId,
) async {
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Save'),
    reason: 'section editor Save button',
  );
  await _settle(tester);
  await tester.pump(const Duration(seconds: 2));
  await _settle(tester);

  final toast = _firstErrorToastMessage(tester);
  if (toast != null) {
    throw TestFailure('section editor rejected save. Toast: "$toast"');
  }

  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    if (!_fieldMounted(tester, anchorFieldId)) break;
    await tester.pump(const Duration(milliseconds: 200));
  }
  await _settle(tester);
}

/// Drive the self-edit flow across the three section dialogs (personal
/// details, contact, address). Starts from /memberzone/profile.
Future<void> _editSelfContactViaUi(
  WidgetTester tester, {
  required String username,
}) async {
  await _go(tester, '/memberzone/profile');

  // ── Personal details ──
  await _openSectionEditor(tester, PersonalDetailsCard, 'firstName');
  await _enterTextById(tester, 'firstName', _kEditedFirstName);
  await _enterTextById(tester, 'middleName', _kEditedMiddleName);
  await _enterTextById(tester, 'lastName', _kEditedLastName);
  await _enterTextById(tester, 'nickname', _kEditedNickname);
  await _saveSectionDialog(tester, 'firstName');

  // ── Contact ──
  await _openSectionEditor(tester, UserContactInfoCard, 'email');
  await _enterTextById(tester, 'email', _kEditedEmail);
  await _enterTextById(tester, 'phone', _kEditedPhoneTyped);
  await _enterTextById(tester, 'emergencyContactName', _kEditedEmergencyName);
  await _enterTextById(
    tester,
    'emergencyContactPhone',
    _kEditedEmergencyPhoneTyped,
  );
  await _enterTextById(tester, 'medicalInfo', _kEditedMedicalInfo);
  _setShadFormValues(tester, {
    'emergencyContactRelation': _kEditedEmergencyRelation,
  });
  await tester.pump();
  await _saveSectionDialog(tester, 'email');

  // ── Address ──
  await _openSectionEditor(tester, AddressCard, 'addrLine1');
  await _enterTextById(tester, 'addrLine1', _kEditedAddrLine1);
  await _enterTextById(tester, 'addrLine2', _kEditedAddrLine2);
  await _enterTextById(tester, 'city', _kEditedCity);
  await _enterTextById(tester, 'pincode', _kEditedPincode);
  _setShadFormValues(tester, {'state': _kEditedState});
  await tester.pump();
  await _saveSectionDialog(tester, 'addrLine1');
}

/// Closes an open section editor dialog via its "Cancel" button.
Future<void> _cancelSectionDialog(
  WidgetTester tester,
  String anchorFieldId,
) async {
  _invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Cancel'),
    reason: 'section editor Cancel button',
  );
  await _settle(tester);
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    if (!_fieldMounted(tester, anchorFieldId)) break;
    await tester.pump(const Duration(milliseconds: 200));
  }
  await _settle(tester);
}

/// Verify the personal-details editor renders DOB as a [ReadOnlyField], not as
/// an editable [ShadDatePickerFormField]. Caller must have the personal-details
/// dialog open.
void _expectDobIsReadOnly(WidgetTester tester) {
  final editable = find.byWidgetPredicate(
    (w) => w is ShadDatePickerFormField && w.id == 'dateOfBirthUtc',
  );
  expect(
    editable,
    findsNothing,
    reason:
        'admin must not see an editable DOB field — DOB is super-admin '
        'only and should render as ReadOnlyField',
  );

  final readOnly = find.byWidgetPredicate(
    (w) => w is ReadOnlyField && w.label == 'Date of birth',
  );
  expect(
    readOnly,
    findsOneWidget,
    reason: 'admin edit form must render Date of birth as a ReadOnlyField',
  );
}

/// Tap one of the labelled action buttons in `ProfileActionsSection` (Block,
/// Mark as Left, Delete). Caller must be on the AdminUserProfileView.
Future<void> _invokeProfileActionViaUi(
  WidgetTester tester,
  String label,
) async {
  await _waitFor(
    tester,
    () => find.widgetWithText(ActionButton, label).evaluate().isNotEmpty,
    description: '"$label" ActionButton on the admin profile',
  );
  final btn = tester.widget<ActionButton>(
    find.widgetWithText(ActionButton, label),
  );
  expect(
    btn.onPressed,
    isNotNull,
    reason: '"$label" should be enabled for the admin',
  );
  btn.onPressed!.call();
  await _settle(tester);

  final toast = _firstErrorToastMessage(tester);
  if (toast != null) {
    throw TestFailure('"$label" action failed. Toast: "$toast"');
  }
  await tester.pump(const Duration(seconds: 1));
  await _settle(tester);
}

/// Unblock a user from the admin user list. Tapping a blocked user's card
/// is a no-op (UserCard.onTap is gated to active users), so the affordance
/// is the "Unblock" ActionButton inside the card itself.
Future<void> _unblockUserFromListViaUi(
  WidgetTester tester,
  String username,
) async {
  await _go(tester, '/memberzone/users');
  final userCard = find.byKey(ValueKey(username));
  await _waitFor(
    tester,
    () => userCard.evaluate().isNotEmpty,
    description: 'blocked user card "$username" to appear',
  );

  final unblock = find.descendant(
    of: userCard,
    matching: find.widgetWithText(ActionButton, 'Unblock'),
  );
  await _waitFor(
    tester,
    () => unblock.evaluate().isNotEmpty,
    description: 'Unblock button on user card "$username"',
  );
  // A destructive toast can linger from the Phase-12 blocked-login attempt
  // ("Your account is blocked"). Wait for it to auto-dismiss so the
  // post-unblock error check below isn't fooled by a stale toast.
  await _waitFor(
    tester,
    () => _firstErrorToastMessage(tester) == null,
    description: 'stale error toast to clear before unblocking "$username"',
    timeout: const Duration(seconds: 12),
  );

  final btn = tester.widget<ActionButton>(unblock);
  expect(
    btn.onPressed,
    isNotNull,
    reason: 'Unblock should be enabled on a blocked user card',
  );
  btn.onPressed!.call();
  await _settle(tester);

  await _waitFor(
    tester,
    () {
      final toast = _firstErrorToastMessage(tester);
      if (toast != null) {
        throw TestFailure('unblock failed. Toast: "$toast"');
      }
      return find
          .descendant(
            of: userCard,
            matching: find.widgetWithText(ActionButton, 'Unblock'),
          )
          .evaluate()
          .isEmpty;
    },
    description: 'Unblock button to disappear after action',
  );
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _softDeleteUserViaUi(
  WidgetTester tester,
  String username,
) async {
  await _openAdminProfileViaUi(tester, username);
  await _invokeProfileActionViaUi(tester, 'Delete');
}

// ---------------------------------------------------------------------------
// Field-by-field assertions
// ---------------------------------------------------------------------------

void _expectMemberSelfEditedFields(UserPrivate u, Capabilities caps) {
  expect(u.firstName, _kEditedFirstName, reason: 'firstName');
  expect(u.middleName, _kEditedMiddleName, reason: 'middleName');
  expect(u.lastName, _kEditedLastName, reason: 'lastName');
  expect(u.nickname, _kEditedNickname, reason: 'nickname');
  expect(u.email, _kEditedEmail, reason: 'email');
  expect(
    u.phone,
    storedPhone(caps, _kEditedPhone),
    reason: 'Issue 31: phone, in international format',
  );
  expect(u.address?.addrLine1, _kEditedAddrLine1, reason: 'addrLine1');
  expect(u.address?.addrLine2, _kEditedAddrLine2, reason: 'addrLine2');
  expect(u.address?.city, _kEditedCity, reason: 'city');
  expect(u.address?.state, _kEditedState, reason: 'state');
  expect(u.address?.pincode, _kEditedPincode, reason: 'pincode');
  expect(u.medicalInfo, _kEditedMedicalInfo, reason: 'medicalInfo');
  // emergencyContact is denormalised on the server side as
  // "Name (Relation) : Phone". Assert the round-tripped composite carries
  // each fragment so the test does not depend on string formatting nuances.
  final ec = u.emergencyContact ?? '';
  expect(
    ec,
    contains(_kEditedEmergencyName),
    reason: 'emergency contact must include name',
  );
  expect(
    ec,
    contains(_kEditedEmergencyRelation),
    reason: 'emergency contact must include relation',
  );
  expect(
    ec,
    endsWith(storedPhone(caps, _kEditedEmergencyPhone)),
    reason:
        'Issue 31: emergency contact must include the phone, in '
        'international format',
  );
}

// ---------------------------------------------------------------------------
// Form-field helpers
// ---------------------------------------------------------------------------

Future<void> _enterTextById(
  WidgetTester tester,
  String fieldId,
  String value,
) async {
  final field = find.byWidgetPredicate(
    (w) => w is ShadInputFormField && w.id == fieldId,
  );
  expect(
    field,
    findsOneWidget,
    reason: 'expected ShadInputFormField with id="$fieldId"',
  );
  final editable = find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
  expect(
    editable,
    findsOneWidget,
    reason: 'expected an EditableText inside field "$fieldId"',
  );
  // Scroll the field into view first. tester.enterText runs an internal
  // focus tap on the EditableText; for off-screen fields that tap silently
  // misses (no hit-test target), and the typed text never lands in the
  // form. UserEditView is taller than the test surface, so several fields
  // sit below the viewport on first paint.
  final scrollable = find
      .ancestor(of: editable, matching: find.byType(Scrollable))
      .first;
  if (scrollable.evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(
      editable,
      200,
      scrollable: scrollable,
    );
  }
  await tester.enterText(editable, value);
}

Future<void> _submitFormContaining(
  WidgetTester tester, {
  required String fieldId,
  required String label,
}) async {
  final formFinder = find.ancestor(
    of: find.byWidgetPredicate(
      (w) => w is ShadInputFormField && w.id == fieldId,
    ),
    matching: find.byType(ShadForm),
  );
  expect(
    formFinder,
    findsOneWidget,
    reason: 'expected one ShadForm enclosing field "$fieldId"',
  );
  final btn = _submitButtonBeside(formFinder.evaluate().single, label);
  expect(btn.onPressed, isNotNull, reason: '"$label" button should be enabled');
  btn.onPressed!.call();
  await _settle(tester);
}

/// The ShadButton labelled [label] that belongs to the form at [form]: the
/// one closest to it in the widget tree. A form owns no buttons; its host
/// draws them beside it, so the button and the form share a near ancestor,
/// which a same-labelled button elsewhere on the page (the public navbar's
/// "Sign in") does not.
ShadButton _submitButtonBeside(Element form, String label) {
  final around = <Element>[form];
  form.visitAncestorElements((ancestor) {
    around.add(ancestor);
    return true;
  });
  ShadButton? nearest;
  var nearestDistance = around.length;
  for (final candidate in find.widgetWithText(ShadButton, label).evaluate()) {
    var distance = around.length;
    candidate.visitAncestorElements((ancestor) {
      final index = around.indexOf(ancestor);
      if (index < 0) return true;
      distance = index;
      return false;
    });
    if (distance < nearestDistance) {
      nearest = candidate.widget as ShadButton;
      nearestDistance = distance;
    }
  }
  expect(
    nearest,
    isNotNull,
    reason: 'expected a "$label" ShadButton beside the form',
  );
  return nearest!;
}

void _setShadFormValues(WidgetTester tester, Map<String, dynamic> values) {
  // ShadFormBuilderField only propagates a value into the parent ShadForm's
  // value map when its custom `setValue(populateForm: true)` runs — base
  // FormFieldState.didChange does not. Writing through ShadForm state is the
  // supported way to set non-text fields (selects, date pickers) in tests.
  tester.state<ShadFormState>(find.byType(ShadForm)).setValue(values);
}

/// Invoke a ShadButton's `onPressed` directly. Use instead of `tester.tap`
/// for buttons that may sit below the test viewport (dialogs, long forms,
/// stretched layouts) — `tap()` resolves to an offset outside the rendered
/// tree and silently no-ops, then the test times out waiting for state that
/// will never change. Walking the widget tree to invoke onPressed is what
/// the other workflow tests use for the same reason.
void _invokeShadButton(WidgetTester tester, Finder finder, {String? reason}) {
  expect(finder, findsOneWidget, reason: reason ?? 'expected one ShadButton');
  final btn = tester.widget<ShadButton>(finder);
  expect(
    btn.onPressed,
    isNotNull,
    reason: '${reason ?? 'button'} should be enabled',
  );
  btn.onPressed!.call();
}

String? _firstErrorToastMessage(WidgetTester tester) {
  final toasts = find.byType(ShadToast).evaluate();
  for (final el in toasts) {
    final w = el.widget as ShadToast;
    if (w.variant != ShadToastVariant.destructive) continue;
    final desc = w.description;
    if (desc is Text && desc.data != null) return desc.data;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Pump / wait helpers
// ---------------------------------------------------------------------------

Future<void> _settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 250),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
  } on Object catch (_) {
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() predicate, {
  required String description,
  Duration timeout = const Duration(seconds: 20),
  Duration interval = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await tester.pump(interval);
  }
  throw TestFailure('Timed out waiting for: $description');
}
