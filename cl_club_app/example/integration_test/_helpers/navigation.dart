// The member zone's sidebar, whatever the screen width.
//
// Owns:
//   * revealSidebarEntry — the sidebar entry named [label]. On a wide screen
//                          the sidebar is always there; on a narrow one (a
//                          phone) it lives in a drawer that is built only
//                          once the menu button opens it (#264).
//   * openSidebarEntry   — opens that entry, as a tap on it would.
//   * sidebarBadge       — the entry's badge count, read without leaving the
//                          drawer open.

import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump.dart';

/// The shell's menu button, shown on a narrow screen only.
final Finder _menuButton = find.byTooltip('Open menu');

/// The sidebar entry [label], opening the drawer first when the sidebar is
/// in one.
Future<Finder> revealSidebarEntry(WidgetTester tester, String label) async {
  final entry = find.widgetWithText(SidebarItem, label);
  if (entry.evaluate().isEmpty && _menuButton.evaluate().isNotEmpty) {
    await tapVisible(tester, _menuButton.first);
    await settle(tester);
  }
  expect(entry, findsWidgets, reason: 'sidebar entry "$label"');
  return entry;
}

/// Opens the sidebar entry [label], as a tap on it would. The entry closes
/// the drawer itself when it is in one.
Future<void> openSidebarEntry(WidgetTester tester, String label) async {
  final entry = await revealSidebarEntry(tester, label);
  tester.widget<SidebarItem>(entry.first).onTap();
  await settle(tester);
}

/// The badge count on the sidebar entry [label] (0 for none). A drawer
/// opened to read it is closed again.
Future<int> sidebarBadge(WidgetTester tester, String label) async {
  final entry = await revealSidebarEntry(tester, label);
  final count = tester.widget<SidebarItem>(entry.first).badgeCount ?? 0;
  await closeDrawer(tester);
  return count;
}

/// Closes the member zone's drawer if it is open.
Future<void> closeDrawer(WidgetTester tester) async {
  for (final element in find.byType(Scaffold).evaluate()) {
    final state = (element as StatefulElement).state as ScaffoldState;
    if (state.isDrawerOpen) {
      state.closeDrawer();
      await settle(tester);
      return;
    }
  }
}
