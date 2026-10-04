// User management UI flows for integration tests.
//
// Owns:
//   * createUserViaUi          — drives /memberzone/users → "+ Add user"
//                                form, fills every required field, submits.
//                                Creates a baseline active user with no
//                                roles assigned.
//   * assignRolesViaProfileViaUi — opens the user's admin profile page and
//                                  taps the RoleChips for each requested
//                                  role (Admin / Coach / Member). Waits
//                                  for each toggle to settle.
//   * softDeleteUserViaUi      — opens the user's admin profile and taps
//                                Delete. Fast-fails on destructive toast.
//
// Bootstrapping a real actor (admin / coach / member) is therefore a
// two-step UI walk: createUserViaUi(...) followed by
// assignRolesViaProfileViaUi(..., roles: {Role.admin}).

import 'package:cl_club_members/src/models/user_form_helpers.dart'
    show GenderToForm;
import 'package:cl_club_members/src/widgets/role_chip.dart' show RoleChip;
import 'package:cl_club_members/src/widgets/role_chips.dart' show RoleChips;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clUserPrivateProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Gender, Role;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import 'auth.dart';
import 'forms.dart';
import 'pump.dart';

/// Creates a baseline user via the admin Add User form. The created user
/// is active but has no roles assigned — call [assignRolesViaProfileViaUi]
/// afterward to grant admin / coach / member.
///
/// Caller must already be logged in with admin (or super-admin) privileges.
Future<void> createUserViaUi(
  WidgetTester tester, {
  required String username,
  required String password,
  String firstName = 'Integration',
  String lastName = 'Tester',
  String phone = '9876543210',
  String? email,
  Gender gender = Gender.preferNotToSay,
  DateTime? dateOfBirthUtc,
}) async {
  // Sub-flow start: go to the admin users list, then tap "+ Add user"
  // (the same path an admin uses in production).
  await go(tester, '/memberzone/users');
  final addUserButton = find.widgetWithText(ActionButton, '+ Add user');
  await waitFor(
    tester,
    () => addUserButton.evaluate().isNotEmpty,
    description: '"+ Add user" button on the admin users list',
  );
  await tester.tap(addUserButton);
  await settle(tester);

  await waitFor(
    tester,
    () => find
        .byWidgetPredicate(
          (w) => w is ShadInputFormField && w.id == 'username',
        )
        .evaluate()
        .isNotEmpty,
    description: 'admin Add User form to mount',
  );

  await enterTextById(tester, 'username', username);

  // The admin Create user button is gated by the username-availability
  // check (matches SignupView's contract). Run the check before submit.
  final checkButton = find.widgetWithText(ShadButton, 'Check availability');
  await waitFor(
    tester,
    () => checkButton.evaluate().isNotEmpty,
    description: '"Check availability" button to appear',
  );
  await tester.tap(checkButton);
  await settle(tester);
  await waitFor(
    tester,
    () => find.text('Available').evaluate().isNotEmpty,
    description: 'username availability check to report "Available"',
  );

  // The Add User form defaults `useDefaultPassword=true`, which hides the
  // password + confirmPassword fields. Invoke the checkbox's onChanged
  // directly (tapping the small hit-target is unreliable in widget tests).
  final useDefaultCheckbox = find.byWidgetPredicate(
    (w) => w is ShadCheckboxFormField && w.id == 'useDefaultPassword',
  );
  expect(
    useDefaultCheckbox,
    findsOneWidget,
    reason: 'expected "useDefaultPassword" checkbox on Add User form',
  );
  // Invoke the inner ShadCheckbox's onChanged (which is the form field's
  // didChange). That updates the field's value, propagates to the
  // ShadForm value map, AND triggers the parent's onChanged callback
  // that flips the local state controlling password-field visibility.
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
  await settle(tester);
  await waitFor(
    tester,
    () => find
        .byWidgetPredicate((w) => w is ShadInputFormField && w.id == 'password')
        .evaluate()
        .isNotEmpty,
    description: 'password field to appear after toggling off default password',
  );

  await enterTextById(tester, 'password', password);
  await enterTextById(tester, 'confirmPassword', password);
  await enterTextById(tester, 'firstName', firstName);
  await enterTextById(tester, 'lastName', lastName);
  await enterTextById(tester, 'phone', phone);
  await enterTextById(tester, 'email', email ?? '$username@example.com');

  // Gender (ShadSelectFormField<SignupGender>) and DOB
  // (ShadDatePickerFormField) open overlay popups that are awkward to drive
  // in widget tests. Write them straight into the parent ShadForm's value
  // map — that's the only path that flows through
  // ShadFormBuilderField.setValue(populateForm: true) and ends up in
  // `form.value` at submit time. The UserForm gender field speaks the
  // form-local `SignupGender` (Form Design Guidelines: forms hold form-local
  // types, not SDK models), so map the SDK `Gender` across before writing —
  // passing the raw `Gender` throws `type 'Gender' is not a subtype of
  // 'SignupGender?'` inside ShadFormBuilderSelectState.didChange.
  setShadFormValues(tester, {
    'gender': gender.toForm(),
    'dateOfBirthUtc': dateOfBirthUtc ?? DateTime.utc(1990, 1, 1),
  });
  await tester.pump();

  // Invoke the submit button's onPressed directly rather than tapping it:
  // on smaller surfaces (e.g. the 1280x720 Linux desktop window) the
  // "Create user" button sits below the fold, and a synthesized tap lands
  // off-screen and silently no-ops. The button is a dialog action rendered
  // outside the ShadForm, so a global finder (not submitFormContaining) is
  // the right tool here.
  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Create user'),
    reason: 'admin "Create user" submit button',
  );
  await settle(tester);

  // On success the form pops (the "Create user" button vanishes). On
  // failure the form stays mounted and shows a destructive toast like
  // "Could not create user." — surface that as a fast test failure with
  // the actual toast text so we don't spin until timeout.
  await waitFor(
    tester,
    () {
      final toast = firstErrorToastMessage(tester);
      if (toast != null) {
        throw TestFailure(
          'admin Add User form rejected the submission for "$username". '
          'Toast: "$toast"',
        );
      }
      return find.widgetWithText(ShadButton, 'Create user').evaluate().isEmpty;
    },
    description: 'admin Add User form to close after creating "$username"',
  );
}

/// Opens the admin profile for [username] and toggles RoleChips to grant
/// every role in [roles]. Each chip tap triggers a server `assignRole`
/// call and a master-state refresh; the helper waits for each chip to
/// flip to its selected variant before moving on.
///
/// Caller must already be logged in with admin privileges. The targeted
/// user must already exist (created via [createUserViaUi]).
Future<void> assignRolesViaProfileViaUi(
  WidgetTester tester, {
  required String username,
  required Set<Role> roles,
}) async {
  // Sub-flow start: open the admin users list, then tap into the user's
  // profile card.
  await go(tester, '/memberzone/users');
  final userCard = find.byKey(ValueKey(username));
  await waitFor(
    tester,
    () => userCard.evaluate().isNotEmpty,
    description: 'user card "$username" to appear in the admin list',
  );
  await tester.tap(userCard);
  await settle(tester);

  await waitFor(
    tester,
    () => find.byType(RoleChips).evaluate().isNotEmpty,
    description: 'RoleChips on admin profile for "$username"',
  );

  for (final role in roles) {
    final chipFinder = find.byWidgetPredicate(
      (w) => w is RoleChip && w.role == role,
    );
    expect(
      chipFinder,
      findsOneWidget,
      reason: 'expected one RoleChip for $role on profile of "$username"',
    );

    final chip = tester.widget<RoleChip>(chipFinder);
    if (chip.selected) {
      // Already assigned — nothing to do. This makes the helper safe to
      // re-run if a previous attempt partially completed.
      continue;
    }

    // RoleChip renders a ShadButton.outline when unselected; tapping the
    // chip's button onPressed avoids hit-testing fragility for
    // wrap-laid-out chips that may sit just below the viewport.
    final chipButton = find.descendant(
      of: chipFinder,
      matching: find.byType(ShadButton),
    );
    expect(
      chipButton,
      findsOneWidget,
      reason: 'expected one ShadButton inside RoleChip for $role',
    );
    final btn = tester.widget<ShadButton>(chipButton);
    expect(
      btn.onPressed,
      isNotNull,
      reason: 'RoleChip for $role should be enabled',
    );
    btn.onPressed!.call();
    await settle(tester);

    // Wait for the new selected state to propagate: parent calls
    // assignRole, refreshes user, and rebuilds the chip with selected=true.
    await waitFor(
      tester,
      () {
        final updated = tester.widgetList<RoleChip>(chipFinder);
        return updated.isNotEmpty && updated.first.selected;
      },
      description: 'RoleChip for $role on "$username" to flip to selected',
    );

    final toast = firstErrorToastMessage(tester);
    if (toast != null) {
      throw TestFailure(
        'role assignment for "$username" failed. Toast: "$toast"',
      );
    }
  }
}

/// Grants each role in [roles] to [username] via the profile's RolesSection
/// checkboxes ('Make this user an Admin' / 'This user is a coach'). Waits for
/// each grant to take effect on the user's `clUserPrivateProvider` roles.
///
/// Caller must already be logged in with admin (or super-admin) privileges,
/// and [username] must already exist. (This is the checkbox-based counterpart
/// to [assignRolesViaProfileViaUi], which targets the unused RoleChips card.)
Future<void> grantRolesViaCheckboxViaUi(
  WidgetTester tester, {
  required String username,
  required Set<Role> roles,
}) async {
  await go(tester, '/memberzone/users');
  final userCard = find.byKey(ValueKey(username));
  await waitFor(
    tester,
    () => userCard.evaluate().isNotEmpty,
    description: 'user card "$username" to appear in the admin list',
  );
  await tester.tap(userCard);
  await settle(tester);

  await waitFor(
    tester,
    () => find
        .text('Toggle the roles assigned to this user.')
        .evaluate()
        .isNotEmpty,
    description: 'RolesSection on admin profile for "$username"',
  );

  const labels = {
    Role.admin: 'Make this user an Admin',
    Role.coach: 'This user is a coach',
  };
  for (final role in roles) {
    final label = labels[role]!;
    final checkbox = find.byWidgetPredicate(
      (w) =>
          w is ShadCheckbox &&
          w.label is Text &&
          (w.label! as Text).data == label,
    );
    expect(
      checkbox,
      findsOneWidget,
      reason: 'expected one "$label" checkbox on profile of "$username"',
    );
    final cb = tester.widget<ShadCheckbox>(checkbox);
    if (cb.value) continue; // already granted
    expect(
      cb.onChanged,
      isNotNull,
      reason: '"$label" checkbox must be enabled',
    );
    cb.onChanged!.call(true);
    await settle(tester);

    await waitFor(
      tester,
      () {
        final destructive = firstErrorToastMessage(tester);
        if (destructive != null) {
          throw TestFailure(
            'role grant failed for "$username". '
            'Toast: "$destructive"',
          );
        }
        final v = container(
          tester,
        ).read(clUserPrivateProvider(username)).valueOrNull;
        if (v == null) return false;
        return role == Role.admin ? v.roles.isAdmin : v.roles.isCoach;
      },
      description: 'role $role on "$username" to take effect',
    );
  }
}

Future<void> softDeleteUserViaUi(
  WidgetTester tester,
  String username,
) async {
  // Sub-flow start: go to the admin users list, then tap into the user's
  // profile through the same UI an admin would use.
  await go(tester, '/memberzone/users');
  final userCard = find.byKey(ValueKey(username));
  await waitFor(
    tester,
    () => userCard.evaluate().isNotEmpty,
    description: 'user card "$username" to appear in the admin list',
  );
  await tester.tap(userCard);
  await settle(tester);

  // The admin user-profile renders two ActionButton(label: 'Delete')
  // instances — one in the User Management section, one in the legacy
  // ProfileActionsSection — so we can't match on label alone. Scope the
  // finder to the User Management card by walking up from its heading
  // text to the enclosing ShadCard and back down to the Delete button.
  await waitFor(
    tester,
    () => find.text('User Management').evaluate().isNotEmpty,
    description: 'admin user-profile screen with User Management section',
  );
  final managementCard = find.ancestor(
    of: find.text('User Management'),
    matching: find.byType(ShadCard),
  );
  expect(
    managementCard,
    findsOneWidget,
    reason: 'expected one ShadCard containing the User Management section',
  );
  final deleteFinder = find.descendant(
    of: managementCard,
    matching: find.widgetWithText(ActionButton, 'Delete'),
  );
  // The Delete button can sit below the viewport (the profile is a long
  // page). Calling its onPressed directly avoids both the off-screen tap
  // failure and the need to bake scroll behaviour into the test.
  expect(
    deleteFinder,
    findsOneWidget,
    reason:
        'expected one Delete ActionButton inside the User Management section',
  );
  final deleteButton = tester.widget<ActionButton>(deleteFinder);
  expect(
    deleteButton.onPressed,
    isNotNull,
    reason:
        'Delete ActionButton should be enabled when admin is viewing '
        'an active user',
  );
  deleteButton.onPressed!.call();
  await settle(tester);

  // Fast-fail if the action handler showed a destructive toast.
  // Otherwise pump enough for the async chain (server DELETE +
  // getUserInfo refresh) to complete. The next step in a workflow that
  // uses this helper — typically attempting to log in as the deleted
  // user — is the authoritative proof that the soft-delete actually
  // took effect.
  final toast = firstErrorToastMessage(tester);
  if (toast != null) {
    throw TestFailure('soft-delete failed for "$username". Toast: "$toast"');
  }
  await tester.pump(const Duration(seconds: 2));
  await settle(tester);
}
