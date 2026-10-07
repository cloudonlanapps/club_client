// Venue management UI flows for integration tests.
//
// Owns:
//   * createVenueViaUi — navigates to /memberzone/venues, taps the
//                        "+ New Venue" ActionButton (which `push`-es the
//                        VenueCreateView), fills the form, and taps the
//                        "Create venue" submit button that lives outside
//                        the ShadForm (so it can't be reached via
//                        submitFormContaining).
//
// Going to the list route first — rather than `go`-ing straight to
// /memberzone/venues/new — matters: VenueCreateView pops back to the
// list on success, and `go` to /new replaces the stack so the pop has
// nothing to return to and the form's submit raises
// `GoError: There is nothing to pop`. Walking through the list mirrors
// what a real admin does anyway.

import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, ActionIcon;

import 'auth.dart';
import 'forms.dart';
import 'pump.dart';

/// Creates a venue via the admin Add Venue form.
///
/// Caller must already be logged in with admin (or super-admin)
/// privileges.
Future<void> createVenueViaUi(
  WidgetTester tester, {
  required String name,
  String? address,
  String? description,
  String? mapUri,
}) async {
  // Sub-flow start: navigate to the admin venues list, then tap the
  // "create venue" affordance. The list renders an ActionIcon (+) on
  // narrow widths (< 600 logical px) and an ActionButton labelled
  // "+ New Venue" on wider layouts — we accept either and invoke its
  // onPressed directly to bypass narrow-viewport hit-test issues.
  await go(tester, '/memberzone/venues');
  await waitFor(
    tester,
    () =>
        find
            .widgetWithText(ActionButton, '+ New Venue')
            .evaluate()
            .isNotEmpty ||
        find
            .byWidgetPredicate((w) => w is ActionIcon && w.icon == Icons.add)
            .evaluate()
            .isNotEmpty,
    description: 'create-venue affordance on the admin venues list',
  );
  final wideButton = find.widgetWithText(ActionButton, '+ New Venue');
  if (wideButton.evaluate().isNotEmpty) {
    tester.widget<ActionButton>(wideButton).onPressed!.call();
  } else {
    final narrowIcon = find.byWidgetPredicate(
      (w) => w is ActionIcon && w.icon == Icons.add,
    );
    tester.widget<ActionIcon>(narrowIcon).onPressed!.call();
  }
  await settle(tester);

  await waitFor(
    tester,
    () => find
        .byWidgetPredicate(
          (w) => w is ShadInputFormField && w.id == 'name',
        )
        .evaluate()
        .isNotEmpty,
    description: 'admin Create Venue form to mount',
  );

  await enterTextById(tester, 'name', name);
  if (address != null) await enterTextById(tester, 'address', address);
  if (description != null) {
    await enterTextById(tester, 'description', description);
  }
  if (mapUri != null) await enterTextById(tester, 'mapUri', mapUri);

  // The "Create venue" button lives outside the ShadForm (the create-view
  // owns it and validates the form through its key), so we
  // can't reach it through submitFormContaining. Tapping by label is
  // unambiguous on this screen.
  final submit = find.widgetWithText(ShadButton, 'Create venue');
  await waitFor(
    tester,
    () => submit.evaluate().isNotEmpty,
    description: '"Create venue" submit button',
  );
  final btn = tester.widget<ShadButton>(submit);
  expect(
    btn.onPressed,
    isNotNull,
    reason: '"Create venue" button should be enabled before submit',
  );
  btn.onPressed!.call();
  await settle(tester);

  // On success the create route pops back to the venues list, so the
  // submit button vanishes. On failure the form stays mounted and a
  // destructive toast surfaces.
  await waitFor(
    tester,
    () {
      final toast = firstErrorToastMessage(tester);
      if (toast != null) {
        throw TestFailure(
          'admin Create Venue form rejected the submission for "$name". '
          'Toast: "$toast"',
        );
      }
      return find.widgetWithText(ShadButton, 'Create venue').evaluate().isEmpty;
    },
    description: 'admin Create Venue form to close after creating "$name"',
  );
}
