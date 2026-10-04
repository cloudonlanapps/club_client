// Attendance register flows for integration tests (club_core#98, #99).
//
// Owns:
//   * openRegisterViaCalendarViaUi — from the Club Calendar (today), tap the
//     "Attendance" action on the occurrence card of [eventTitle]; lands on
//     EventOccurencesAttendanceView.
//   * registerTile — a member's row on the open register.
//   * markInRegisterViaUi / clearInRegisterViaUi — tap a row's toggle.

import 'package:cl_club_events/src/views/event_occurences_attendance_view.dart'
    show EventOccurencesAttendanceView;
import 'package:cl_club_events/src/widgets/attendance_member_tile.dart'
    show AttendanceMemberTile;
import 'package:cl_club_events/src/widgets/cards/occurrence_card.dart'
    show OccurrenceCard;
import 'package:club_sdk_2/club_sdk_2.dart' show AttendanceStatus;
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import 'auth.dart';
import 'pump.dart';

/// Opens today's register for [eventTitle] from the Club Calendar, as a
/// coach or admin who manages the event does.
Future<void> openRegisterViaCalendarViaUi(
  WidgetTester tester, {
  required String eventTitle,
}) async {
  await go(tester, '/memberzone/events/calendar');
  final card = find.ancestor(
    of: find.textContaining(eventTitle),
    matching: find.byType(OccurrenceCard),
  );
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: 'the "$eventTitle" occurrence on the Club Calendar',
  );
  final button = find.descendant(
    of: card.first,
    matching: find.widgetWithText(ActionButton, 'Attendance'),
  );
  await waitFor(
    tester,
    () => button.evaluate().isNotEmpty,
    description: 'the Attendance action on "$eventTitle"',
  );
  tester.widget<ActionButton>(button.first).onPressed!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(EventOccurencesAttendanceView).evaluate().isNotEmpty,
    description: 'the register to open',
  );
}

/// [username]'s row on the open register, once it is there.
Future<AttendanceMemberTile> registerTile(
  WidgetTester tester,
  String username, {
  bool Function(AttendanceMemberTile tile)? until,
  String? description,
}) async {
  final finder = find.byWidgetPredicate(
    (w) => w is AttendanceMemberTile && w.username == username,
  );
  await waitFor(
    tester,
    () {
      final found = finder.evaluate();
      if (found.isEmpty) return false;
      final tile = found.first.widget as AttendanceMemberTile;
      return until?.call(tile) ?? true;
    },
    description: description ?? '$username on the register',
  );
  return tester.widget<AttendanceMemberTile>(finder);
}

/// Marks [username] with [status] on the open register and waits for the
/// server's answer to settle into the row.
Future<void> markInRegisterViaUi(
  WidgetTester tester,
  String username,
  AttendanceStatus status,
) async {
  final tile = await registerTile(tester, username);
  expect(tile.blockedCredits, isNull, reason: '$username can be charged');
  tile.onStatusChanged(status);
  await registerTile(
    tester,
    username,
    until: (t) => t.currentStatus == status && !t.hasPending,
    description: '$username marked ${status.name}',
  );
}

/// Clears [username]'s mark on the open register.
Future<void> clearInRegisterViaUi(WidgetTester tester, String username) async {
  final tile = await registerTile(tester, username);
  tile.onClear();
  await registerTile(
    tester,
    username,
    until: (t) => t.currentStatus == null && !t.hasPending,
    description: '$username cleared',
  );
}
