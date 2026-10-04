// Audit-log history checks for integration tests (club_core#88).
//
// Owns:
//   * openHistoryViaTitleRow — invokes the history button in the current
//                              profile's TitleRow and waits for the scoped
//                              history screen to show the expected rows.
//   * openGlobalAuditLogViaDashboard — invokes the super-admin "Audit Log"
//                              tile on the dashboard and waits for the
//                              global feed to show the expected rows.
//   * expectNoGlobalAuditLogTile — the dashboard hides that tile from a
//                              viewer who is not a super-admin.
//   * backFromHistory       — invokes the history screen's back arrow and
//                              waits for the history screen to unmount.
//
// Workflows call these right after the action that writes the audit row,
// so the row asserted is the one the workflow just caused. Summaries are
// matched with `textContaining` on the server-composed sentence (actor,
// predicate, resource label); the timestamp suffix is never matched.

import 'package:cl_member_zone/cl_member_zone.dart'
    show AuditLogScreen, DashboardScreen;
import 'package:cl_member_zone/src/widgets/quick_action_tile.dart'
    show QuickActionTile;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump.dart';

/// Opens the audit history of the entity whose profile is on screen, via
/// the history button in its title row, and waits until the screen titled
/// [title] lists a row matching each of [rows].
///
/// The button is invoked through its `onPressed` rather than a synthesized
/// tap (off-screen safety).
Future<void> openHistoryViaTitleRow(
  WidgetTester tester, {
  required String title,
  required List<Pattern> rows,
}) async {
  final icon = find.byIcon(Icons.history);
  expect(
    icon,
    findsOneWidget,
    reason: 'the profile title row must show one history button',
  );
  final button = tester.widget<IconButton>(
    find.ancestor(of: icon, matching: find.byType(IconButton)),
  );
  expect(button.onPressed, isNotNull, reason: 'history button must be enabled');
  button.onPressed!.call();
  await settle(tester);
  await _expectHistory(tester, title: title, rows: rows);
}

/// From the dashboard, opens the super-admin global audit feed via its
/// "Audit Log" tile and waits until it lists a row matching each of [rows].
Future<void> openGlobalAuditLogViaDashboard(
  WidgetTester tester, {
  required List<Pattern> rows,
}) async {
  await waitFor(
    tester,
    () => find.byType(DashboardScreen).evaluate().isNotEmpty,
    description: 'dashboard to mount',
  );
  final tile = _auditLogTile();
  await waitFor(
    tester,
    () => tile.evaluate().isNotEmpty,
    description: 'super-admin "Audit Log" tile on the dashboard',
  );
  final onTap = tester.widget<QuickActionTile>(tile).onTap;
  expect(onTap, isNotNull, reason: '"Audit Log" tile must be tappable');
  onTap!.call();
  await settle(tester);
  await _expectHistory(tester, title: 'Audit Log', rows: rows);
}

/// Asserts the dashboard offers no global "Audit Log" tile — the feed is
/// super-admin only, so an admin (or member) must not see the entry.
Future<void> expectNoGlobalAuditLogTile(WidgetTester tester) async {
  await waitFor(
    tester,
    () => find.byType(DashboardScreen).evaluate().isNotEmpty,
    description: 'dashboard to mount',
  );
  expect(
    _auditLogTile(),
    findsNothing,
    reason: 'the global "Audit Log" tile is for super-admins only',
  );
}

Finder _auditLogTile() => find.byWidgetPredicate(
  (w) => w is QuickActionTile && w.label == 'Audit Log',
);

/// Invokes the history screen's back arrow and waits for it to unmount.
Future<void> backFromHistory(WidgetTester tester) async {
  final back = find.ancestor(
    of: find.descendant(
      of: find.byType(AuditLogScreen),
      matching: find.byIcon(Icons.arrow_back),
    ),
    matching: find.byType(IconButton),
  );
  expect(back, findsOneWidget, reason: 'history screen must show a back arrow');
  final button = tester.widget<IconButton>(back);
  expect(button.onPressed, isNotNull, reason: 'back arrow must be enabled');
  button.onPressed!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(AuditLogScreen).evaluate().isEmpty,
    description: 'history screen to unmount after Back',
  );
}

Future<void> _expectHistory(
  WidgetTester tester, {
  required String title,
  required List<Pattern> rows,
}) async {
  final screen = find.byType(AuditLogScreen);
  await waitFor(
    tester,
    () => screen.evaluate().isNotEmpty,
    description: '"$title" screen to mount',
  );
  expect(
    find.descendant(of: screen, matching: find.text(title)),
    findsOneWidget,
    reason: 'history screen must be titled "$title"',
  );
  for (final row in rows) {
    await waitFor(
      tester,
      () => find
          .descendant(of: screen, matching: find.textContaining(row))
          .evaluate()
          .isNotEmpty,
      description: '"$title" to list a row matching "$row"',
    );
  }
  expect(
    find.descendant(of: screen, matching: find.text('No activity yet.')),
    findsNothing,
    reason: '"$title" must not show the empty state',
  );
}
