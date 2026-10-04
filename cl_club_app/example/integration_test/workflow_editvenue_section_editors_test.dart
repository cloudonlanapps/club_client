// workflow_editvenue: focused coverage of the venue section editors and the
// description markdown editor on `/memberzone/venues/:id`, across roles.
//
// Flow:
//   0. Sudo creates three actors: an admin, a coach, and a member.
//   1. Admin creates a venue, opens it, and sees the editable sections.
//   2. Coach opens the venue — every section is read-only (no pencil, flags
//      disabled, no management section).
//   3. Member opens the venue — same read-only view; content is visible.
//   4. Admin edits location (inline), description (markdown) and a flag; each
//      change round-trips to the server AND the updated section reflects it
//      in place.
//   5. Member re-opens the venue and sees the updated content.
//   6. Cleanup: admin soft-deletes the venue; sudo soft-deletes the actors.

import 'package:cl_club_venues/cl_club_venues.dart'
    show VenueCard, VenueProfileView;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clVenuesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Role, Venue;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, MapEmbed;

import '_helpers/auth.dart';
import '_helpers/editors.dart';
import '_helpers/forms.dart';
import '_helpers/pump.dart';
import '_helpers/users.dart';
import '_helpers/venues.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

const _kAdmin = 'workflow_editvenue_admin';
const _kCoach = 'workflow_editvenue_coach';
const _kMember = 'workflow_editvenue_member';
const _kPwd = 'WfEditVenuePwd!2024';

const _kVenueName = 'workflow_editvenue_site';
const _kInitialAddress = 'workflow_editvenue address line 1';
const _kInitialDescription = 'workflow_editvenue initial description.';
const _kEditedAddress = 'workflow_editvenue edited address line 1';
const _kEditedMapUri = 'https://maps.google.com/?q=workflow_editvenue';
const _kEditedDescription =
    '# workflow_editvenue updated\n\nEdited inline by the admin.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  testWidgets(
    'venue section + markdown editors across admin/coach/member',
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

      // ─── Phase 1: admin creates the venue and sees editable sections ───
      await loginViaUi(tester, _kAdmin, _kPwd);
      await createVenueViaUi(
        tester,
        name: _kVenueName,
        address: _kInitialAddress,
        description: _kInitialDescription,
      );
      final venueId = await _waitForVenueId(tester, _kVenueName);

      await _openVenueDetail(tester, _kVenueName);
      expect(find.byType(VenueProfileView), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Venue Management'), findsOneWidget);
      // Admin sees the location pencil and an editable description.
      expectSectionEditable(tester, find.byType(VenueProfileView));
      expect(find.byTooltip('Edit Description'), findsOneWidget);
      await logout(tester);

      // ─── Phase 2: coach view is read-only ──────────────────────────────
      await loginViaUi(tester, _kCoach, _kPwd);
      await _openVenueDetail(tester, _kVenueName);
      expect(find.byType(VenueProfileView), findsOneWidget);
      expectSectionReadOnly(tester, find.byType(VenueProfileView));
      expect(
        find.byTooltip('Edit Description'),
        findsNothing,
        reason: 'coach must not get the description editor',
      );
      expect(
        find.text('Venue Management'),
        findsNothing,
        reason: 'coach must not see Rename/Delete management',
      );
      _expectFlagsDisabled(tester);
      // The content is still visible to the coach.
      expect(find.text(_kInitialAddress), findsOneWidget);
      await logout(tester);

      // ─── Phase 3: member view is read-only too ─────────────────────────
      await loginViaUi(tester, _kMember, _kPwd);
      await _openVenueDetail(tester, _kVenueName);
      expectSectionReadOnly(tester, find.byType(VenueProfileView));
      expect(find.text(_kInitialAddress), findsOneWidget);
      await logout(tester);

      // ─── Phase 4: admin edits location, description, and a flag ────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openVenueDetail(tester, _kVenueName);

      // Location — inline edit.
      await tapSectionPencil(tester, find.byType(VenueProfileView));
      await enterTextById(tester, 'address', _kEditedAddress);
      await enterTextById(tester, 'mapUri', _kEditedMapUri);
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () {
          final v = _venue(tester, venueId);
          return v.address == _kEditedAddress && v.mapUri == _kEditedMapUri;
        },
        description: 'location to round-trip to the server',
      );
      // The card returns to read mode showing the new address.
      expect(
        find.text(_kEditedAddress),
        findsOneWidget,
        reason: 'updated address must show in the card after save',
      );

      // Description — markdown editor.
      await editMarkdownField(
        tester,
        tooltip: 'Edit Description',
        markdown: _kEditedDescription,
      );
      await waitFor(
        tester,
        () => _venue(tester, venueId).description == _kEditedDescription,
        description: 'description to round-trip to the server',
      );

      // Flag — toggle default on.
      await _toggleFlag(tester, 'This is the default venue');
      await waitFor(
        tester,
        () => _venue(tester, venueId).isDefault,
        description: 'isDefault to become true on the server',
      );
      await logout(tester);

      // ─── Phase 5: member sees the updated content ──────────────────────
      await loginViaUi(tester, _kMember, _kPwd);
      await _openVenueDetail(tester, _kVenueName);
      expect(find.text(_kEditedAddress), findsOneWidget);
      await logout(tester);

      // ─── Phase 6: cleanup ──────────────────────────────────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openVenueDetail(tester, _kVenueName);
      await _deleteVenue(tester);
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

Venue _venue(WidgetTester tester, int venueId) {
  final map = container(tester).read(clVenuesMasterProvider).valueOrNull;
  expect(map, isNotNull, reason: 'clVenuesMasterProvider should be loaded');
  final venue = map![venueId];
  expect(venue, isNotNull, reason: 'venue #$venueId must exist');
  return venue!;
}

Future<int> _waitForVenueId(WidgetTester tester, String name) async {
  await waitFor(
    tester,
    () {
      final map = container(tester).read(clVenuesMasterProvider).valueOrNull;
      return map != null && map.values.any((v) => v.name == name);
    },
    description: 'clVenuesMasterProvider to contain "$name"',
  );
  final map = container(tester).read(clVenuesMasterProvider).valueOrNull!;
  return map.values.firstWhere((v) => v.name == name).id;
}

Future<void> _openVenueDetail(WidgetTester tester, String name) async {
  await go(tester, '/memberzone/venues');
  await waitFor(
    tester,
    () => find
        .descendant(of: find.byType(VenueCard), matching: find.text(name))
        .evaluate()
        .isNotEmpty,
    description: 'VenueCard for "$name" to render',
  );
  final card = find.ancestor(
    of: find.text(name),
    matching: find.byType(VenueCard),
  );
  tester.widget<VenueCard>(card.first).onTap!.call();
  await settle(tester);
  await waitFor(
    tester,
    () =>
        find.byType(MapEmbed).evaluate().isNotEmpty ||
        find.text('No map link provided.').evaluate().isNotEmpty,
    description: 'VenueLocationCard to render',
  );
}

void _expectFlagsDisabled(WidgetTester tester) {
  for (final label in const [
    'This is the default venue',
    'This venue is featured',
  ]) {
    final cb = find.ancestor(
      of: find.text(label),
      matching: find.byType(ShadCheckbox),
    );
    expect(cb, findsOneWidget, reason: 'flag "$label" must render');
    expect(
      tester.widget<ShadCheckbox>(cb).enabled,
      isFalse,
      reason: 'flag "$label" must be disabled for a read-only viewer',
    );
  }
}

Future<void> _toggleFlag(WidgetTester tester, String label) async {
  final cb = find.ancestor(
    of: find.text(label),
    matching: find.byType(ShadCheckbox),
  );
  expect(cb, findsOneWidget, reason: 'flag "$label" must render');
  final w = tester.widget<ShadCheckbox>(cb);
  expect(w.onChanged, isNotNull, reason: 'flag "$label" must be editable');
  w.onChanged!(!w.value);
  await settle(tester);
}

Future<void> _deleteVenue(WidgetTester tester) async {
  // The management section's Delete ActionButton opens a confirm dialog.
  final managementCard = find.ancestor(
    of: find.text('Venue Management'),
    matching: find.byType(ShadCard),
  );
  final trigger = find.descendant(
    of: managementCard,
    matching: find.widgetWithText(ActionButton, 'Delete'),
  );
  expect(trigger, findsOneWidget, reason: 'management Delete button');
  tester.widget<ActionButton>(trigger).onPressed!.call();
  await settle(tester);
  expect(find.text('Delete venue?'), findsOneWidget);
  // Scope to the confirm dialog — the management Delete ActionButton also
  // wraps a 'Delete' ShadButton, so an unscoped finder matches two.
  invokeShadButton(
    tester,
    find.descendant(
      of: find.byType(ShadDialog),
      matching: find.widgetWithText(ShadButton, 'Delete'),
    ),
    reason: 'confirm venue soft-delete',
  );
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(VenueProfileView).evaluate().isEmpty,
    description: 'venue detail to pop after delete',
  );
}
