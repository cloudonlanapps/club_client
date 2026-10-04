// workflow_venue: end-to-end coverage for the venue detail page
// `/memberzone/venues/:id`. Drives every editable affordance and asserts
// each mutation round-trips to the server via `clVenuesMasterProvider`.
//
// Bugs guarded:
//   1. The Description pencil must open the in-place markdown editor and
//      update only `description` — never push the full edit route. (The
//      `/memberzone/venues/:id/edit` route has been removed entirely as
//      part of this fix.)
//   2. Every modal that can render over the `MapEmbed` iframe on web must
//      sit inside a `PointerInterceptor` so clicks land on the dialog,
//      not the iframe. Structural ancestor check — actual pointer
//      fall-through cannot be reproduced in a widget test (no real
//      iframe is rendered), but the wrapper presence is the regression
//      signal.
//
// Audit history (club_core#88): Venue History lists the create row, and
// the super-admin global feed lists the delete.
//
// Cleanup: the venue is soft-deleted through the Management section.
//
// Recommended run (from the club_core root):
//   just app-test-one app_test_server1.conf \
//     workflow_venue_venue_detail_test.dart

import 'package:cl_club_venues/cl_club_venues.dart'
    show VenueCard, VenueProfileView;
import 'package:cl_member_zone/cl_member_zone.dart' show DashboardScreen;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clVenuesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Venue;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        ActionButton,
        EditableMarkdown,
        LoadingView,
        MapEmbed,
        SectionEditButton;

import '_helpers/audit_log.dart';
import '_helpers/auth.dart';
import '_helpers/forms.dart';
import '_helpers/pump.dart';
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

const _kVenueName = 'workflow_venue_site';
const _kVenueNameRenamed = 'workflow_venue_site_renamed';
const _kInitialDescription = 'workflow_venue initial description.';
const _kEditedDescription =
    '# workflow_venue updated\n\nThis description was edited inline.';
const _kInitialAddress = 'workflow_venue address line 1';
const _kEditedAddress = 'workflow_venue edited address line 1';
const _kEditedMapUri = 'https://maps.google.com/?q=workflow_venue';

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
    'venue detail page edits round-trip to the server',
    (tester) async {
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      expect(
        currentUser(tester),
        isNotNull,
        reason: 'sudo login should succeed',
      );

      // -----------------------------------------------------------------
      // Setup — create the venue via the admin UI (also exercises the
      // create flow). Initial description seeded so the inline editor
      // pre-loads non-empty content.
      // -----------------------------------------------------------------
      await createVenueViaUi(
        tester,
        name: _kVenueName,
        address: _kInitialAddress,
        description: _kInitialDescription,
      );
      final venueId = await _waitForVenueId(tester, _kVenueName);

      // -----------------------------------------------------------------
      // Open the detail page from the venues list (user-facing path; no
      // deep link).
      // -----------------------------------------------------------------
      await _openVenueDetailViaUi(tester, _kVenueName);
      // Widget-presence assertion — more robust than route-string parsing
      // across go_router versions and platforms. The detail page mounts
      // exactly one VenueProfileView per route entry.
      expect(
        find.byType(VenueProfileView),
        findsOneWidget,
        reason: 'tapping the venue card should land on the detail page',
      );
      // venueId is read for later mutation assertions against the master
      // provider.
      // ignore: unnecessary_statements
      venueId;

      // -----------------------------------------------------------------
      // Issue 88: the title row's history button opens Venue History,
      // scoped to this venue, listing the create row just written — its
      // summary names the venue (resource-label resolution). Back returns
      // to the venue profile.
      // -----------------------------------------------------------------
      await openHistoryViaTitleRow(
        tester,
        title: 'Venue History',
        rows: const ['created venue $_kVenueName'],
      );
      await backFromHistory(tester);
      await waitFor(
        tester,
        () => find.byType(VenueProfileView).evaluate().isNotEmpty,
        description: 'Issue 88: Back from Venue History to the venue profile',
      );

      // -----------------------------------------------------------------
      // Bug 1 regression — description pencil opens an inline markdown
      // editor and updates only `description`. The URL must not change.
      // -----------------------------------------------------------------
      final editableMarkdown = find.byType(EditableMarkdown);
      expect(
        editableMarkdown,
        findsOneWidget,
        reason: 'description must render via EditableMarkdown',
      );
      await tester.tap(
        find.descendant(
          of: editableMarkdown,
          matching: find.byTooltip('Edit Description'),
        ),
      );
      await settle(tester);

      expect(
        find.byKey(const Key('markdownEditorDialogFrame')),
        findsOneWidget,
        reason: 'description pencil must open MarkdownEditorDialog inline',
      );
      // Bug-1 guard: the pencil must NOT push a full edit route. With
      // the description editor open as a dialog, the underlying detail
      // page must still be mounted (it would have been unmounted by a
      // route push).
      expect(
        find.byType(VenueProfileView),
        findsOneWidget,
        reason:
            'description pencil must not push the full edit route — '
            'VenueProfileView should still be mounted behind the dialog',
      );
      // PointerInterceptor must wrap the dialog so clicks over the map
      // iframe on web land on the dialog instead of the iframe.
      expect(
        find.ancestor(
          of: find.byKey(const Key('markdownEditorDialogFrame')),
          matching: find.byType(PointerInterceptor),
        ),
        findsWidgets,
        reason:
            'MarkdownEditorDialog must sit inside a PointerInterceptor (web '
            'iframe stacking fix)',
      );

      final editor = find.descendant(
        of: find.byKey(const Key('markdownEditorDialogFrame')),
        matching: find.byType(TextField),
      );
      expect(
        editor,
        findsOneWidget,
        reason: 'editable TextField inside MarkdownEditorDialog',
      );
      await tester.enterText(editor, _kEditedDescription);
      await tester.pump();
      _invokeShadButton(
        tester,
        label: 'Save',
        reason: 'description editor Save',
      );
      await settle(tester);

      await waitFor(
        tester,
        () => _venue(tester, venueId).description == _kEditedDescription,
        description: 'description to round-trip to the server',
      );
      expect(
        find.byKey(const Key('markdownEditorDialogFrame')),
        findsNothing,
        reason: 'editor should close after Save',
      );

      // -----------------------------------------------------------------
      // Location — the pencil flips the card into an inline editor
      // (LocationEditForm). Editing happens in place: no dialog, no route
      // push. Save persists address + mapUri.
      // -----------------------------------------------------------------
      // The VenueLocationCard pencil is a `SectionEditButton` (a
      // GestureDetector wrapping a pencil Icon). Invoke its `onTap`
      // directly (`tester.tap` no-ops when the row scrolls below the
      // viewport on narrow widths, per app/CLAUDE.md "Off-screen buttons").
      _invokeLocationPencil(tester);
      await settle(tester);

      // The detail page stays mounted — inline edit, not a route or dialog.
      expect(
        find.byType(VenueProfileView),
        findsOneWidget,
        reason: 'location editing happens in place, not via a route',
      );

      await enterTextById(tester, 'address', _kEditedAddress);
      await enterTextById(tester, 'mapUri', _kEditedMapUri);
      _invokeShadButton(tester, label: 'Save', reason: 'location Save');
      await settle(tester);

      await waitFor(
        tester,
        () {
          final v = _venue(tester, venueId);
          return v.address == _kEditedAddress && v.mapUri == _kEditedMapUri;
        },
        description: 'location to round-trip to the server',
      );

      // -----------------------------------------------------------------
      // Flags — default and featured toggles persist via updateVenue.
      // -----------------------------------------------------------------
      await _toggleCheckboxByLabel(tester, 'This is the default venue');
      await waitFor(
        tester,
        () => _venue(tester, venueId).isDefault,
        description: 'isDefault to become true',
      );
      await _toggleCheckboxByLabel(tester, 'This is the default venue');
      await waitFor(
        tester,
        () => !_venue(tester, venueId).isDefault,
        description: 'isDefault to revert to false',
      );

      await _toggleCheckboxByLabel(tester, 'This venue is featured');
      await waitFor(
        tester,
        () => _venue(tester, venueId).isFeatured,
        description: 'isFeatured to become true',
      );

      // -----------------------------------------------------------------
      // Rename — shared RenameDialog with PointerInterceptor.
      // -----------------------------------------------------------------
      await _tapActionButton(tester, 'Rename');
      await settle(tester);
      expect(
        find.text('Rename venue'),
        findsOneWidget,
        reason: 'RenameDialog must mount',
      );
      expect(
        find.ancestor(
          of: find.text('Rename venue'),
          matching: find.byType(PointerInterceptor),
        ),
        findsWidgets,
        reason: 'RenameDialog must sit inside a PointerInterceptor',
      );
      await enterTextById(tester, 'value', _kVenueNameRenamed);
      _invokeShadButton(tester, label: 'Save', reason: 'rename Save');
      await settle(tester);
      await waitFor(
        tester,
        () => _venue(tester, venueId).name == _kVenueNameRenamed,
        description: 'name to round-trip to the server',
      );

      // -----------------------------------------------------------------
      // Delete — soft-delete via the confirm dialog. The dialog must
      // also sit inside a PointerInterceptor. After confirm the route
      // returns to the venues list and the venue is no longer active.
      // -----------------------------------------------------------------
      await _tapActionButton(tester, 'Delete');
      await settle(tester);
      expect(
        find.text('Delete venue?'),
        findsOneWidget,
        reason: 'delete confirm dialog must mount',
      );
      expect(
        find.ancestor(
          of: find.text('Delete venue?'),
          matching: find.byType(PointerInterceptor),
        ),
        findsWidgets,
        reason: 'delete confirm dialog must sit inside a PointerInterceptor',
      );
      _invokeShadButton(tester, label: 'Delete', reason: 'confirm soft-delete');
      await settle(tester);
      // After confirm, the detail page pops back to the list — assert
      // VenueProfileView is no longer mounted (widget-presence proxy for
      // "we're back on the list route").
      await waitFor(
        tester,
        () => find.byType(VenueProfileView).evaluate().isEmpty,
        description: 'venue detail page to unmount after delete',
      );
      // Verify the soft-delete actually persisted server-side, not just
      // optimistically in memory. deleteVenue stores the soft-deleted venue
      // echoed by the server (carrying `deletedAtUtc`), so the venue stays
      // in the map with `isActive == false`. Requiring `v != null &&
      // !v.isActive` — rather than tolerating `v == null` — means this can
      // only pass if the server genuinely returned a row carrying
      // `deletedAtUtc`. A blind local removal (the prior bug) would leave
      // `v == null` and fail here.
      await waitFor(
        tester,
        () {
          final v = container(
            tester,
          ).read(clVenuesMasterProvider).valueOrNull?[venueId];
          return v != null && !v.isActive;
        },
        description:
            'venue to be soft-deleted (isActive == false) on the '
            'server after a round-trip',
      );

      // -----------------------------------------------------------------
      // Issue 88: the super-admin global feed, reached from the
      // dashboard's "Audit Log" tile, lists the delete just made — under
      // the venue's current (renamed) label, resolved although the venue
      // is soft-deleted. Back returns to the dashboard.
      // -----------------------------------------------------------------
      await go(tester, '/');
      await openGlobalAuditLogViaDashboard(
        tester,
        rows: const ['deleted venue $_kVenueNameRenamed'],
      );
      await backFromHistory(tester);
      await waitFor(
        tester,
        () => find.byType(DashboardScreen).evaluate().isNotEmpty,
        description: 'Issue 88: Back from Audit Log to the dashboard',
      );

      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

// ---------------------------------------------------------------------------
// Local helpers — kept inline; no other workflow drives the venue detail
// page yet. Promote to _helpers/venues.dart when a second workflow needs
// the same vocabulary.
// ---------------------------------------------------------------------------

Venue _venue(WidgetTester tester, int venueId) {
  final map = container(tester).read(clVenuesMasterProvider).valueOrNull;
  expect(
    map,
    isNotNull,
    reason: 'clVenuesMasterProvider should be loaded by now',
  );
  final venue = map![venueId];
  expect(venue, isNotNull, reason: 'venue #$venueId must exist');
  return venue!;
}

Future<int> _waitForVenueId(WidgetTester tester, String name) async {
  await waitFor(
    tester,
    () {
      final map = container(tester).read(clVenuesMasterProvider).valueOrNull;
      if (map == null) return false;
      return map.values.any((v) => v.name == name);
    },
    description: 'clVenuesMasterProvider to contain "$name"',
  );
  final map = container(tester).read(clVenuesMasterProvider).valueOrNull!;
  return map.values.firstWhere((v) => v.name == name).id;
}

Future<void> _openVenueDetailViaUi(WidgetTester tester, String name) async {
  await go(tester, '/memberzone/venues');
  await waitFor(
    tester,
    () => find.byType(VenueCard).evaluate().isNotEmpty,
    description: 'the venues list to render',
  );
  // The list builds its cards lazily. In a full run, earlier files have
  // created venues on the same server, and this one's card can sit below
  // the fold, unbuilt and invisible to finders (club_core#188): scroll the
  // list until it is built, as a user would.
  final cardText = find.descendant(
    of: find.byType(VenueCard),
    matching: find.text(name),
  );
  await tester.scrollUntilVisible(
    cardText,
    200,
    scrollable: find
        .ancestor(
          of: find.byType(VenueCard).first,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  final card = find.ancestor(
    of: find.text(name),
    matching: find.byType(VenueCard),
  );
  expect(
    card,
    findsOneWidget,
    reason: 'expected one VenueCard rendering "$name"',
  );
  // Invoke onTap directly — small/narrow viewports place the card below
  // the visible area and `tester.tap` silently no-ops (see
  // app/CLAUDE.md "Off-screen buttons").
  tester.widget<VenueCard>(card).onTap!.call();
  await settle(tester);
  await waitFor(
    tester,
    () =>
        find.byType(MapEmbed).evaluate().isNotEmpty ||
        find.text('No map link provided.').evaluate().isNotEmpty,
    description: 'VenueLocationCard to render (map or empty-state)',
  );
}

/// Locates the Location card's pencil (a [SectionEditButton] next to the
/// 'Location' header) and invokes its `onTap` directly — bypasses
/// hit-testing so it works regardless of viewport height.
void _invokeLocationPencil(WidgetTester tester) {
  final locationHeader = find.text('Location');
  expect(
    locationHeader,
    findsOneWidget,
    reason: 'expected one "Location" header on the venue profile',
  );
  // Location is the only editable section card on the venue page, so its
  // pencil is the sole SectionEditButton.
  final pencil = find.byType(SectionEditButton);
  expect(
    pencil,
    findsOneWidget,
    reason: 'expected one SectionEditButton pencil on the venue profile',
  );
  tester.widget<SectionEditButton>(pencil).onTap.call();
}

Future<void> _toggleCheckboxByLabel(WidgetTester tester, String label) async {
  // The page renders from the venue's detail provider, which can still be
  // refetching after the previous edit (the round-trip waits above read the
  // master list), so the flags card may not be built yet (club_core#188).
  try {
    await waitFor(
      tester,
      () => find.text(label).evaluate().isNotEmpty,
      description: 'checkbox "$label" to render',
    );
  } on TestFailure {
    // Integration test diagnostic output: what the page showed instead.
    // ignore: avoid_print
    print(
      '[test] venue page without "$label": '
      'profile=${find.byType(VenueProfileView).evaluate().length} '
      'loading=${find.byType(LoadingView).evaluate().length} '
      'error=${find.textContaining('Could not load venue').evaluate().length}',
    );
    rethrow;
  }
  final cb = find.ancestor(
    of: find.text(label),
    matching: find.byType(ShadCheckbox),
  );
  expect(
    cb,
    findsOneWidget,
    reason: 'expected one ShadCheckbox with label "$label"',
  );
  // Invoke onChanged directly — narrow-viewport hit-test misses make
  // `tester.tap` silently no-op on real devices.
  final w = tester.widget<ShadCheckbox>(cb);
  expect(
    w.onChanged,
    isNotNull,
    reason: 'checkbox "$label" must be interactive',
  );
  w.onChanged!(!w.value);
  await settle(tester);
}

Future<void> _tapActionButton(WidgetTester tester, String label) async {
  final btn = find.widgetWithText(ActionButton, label);
  expect(
    btn,
    findsOneWidget,
    reason: 'expected one ActionButton with label "$label"',
  );
  // Invoke onPressed directly — buttons may sit below the viewport.
  tester.widget<ActionButton>(btn).onPressed!.call();
  await settle(tester);
}

void _invokeShadButton(
  WidgetTester tester, {
  required String label,
  required String reason,
}) {
  // Multiple Save buttons can be on-screen (form Save + dialog Save).
  // The dialog's Save is the most recently mounted, so prefer .last.
  final btn = find.widgetWithText(ShadButton, label);
  expect(btn, findsWidgets, reason: '$reason — expected a "$label" ShadButton');
  final w = tester.widget<ShadButton>(btn.last);
  expect(w.onPressed, isNotNull, reason: '$reason — "$label" must be enabled');
  w.onPressed!.call();
}
