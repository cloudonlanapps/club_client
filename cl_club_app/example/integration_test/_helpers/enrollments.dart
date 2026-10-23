// Enrollment-management navigation for integration tests.
//
// Owns:
//   * navigateToEnrollmentManagementViaUi — from any starting point,
//     navigates to /memberzone/events/<type> and runs the "Enrollments"
//     action of the matching event's card. Lands on
//     EventEnrolmentsView. The `go` to the events list is a sub-flow start,
//     not a deep link — every step from there is a tap.
//
// The enrolment flows themselves (assign, invite, accept, request, approve,
// assign trial, withdraw, remove) are driven by
// workflow_credit_enrollment_attendance_test.dart, which folded in the
// former one-off happy path (club_core#108).

import 'package:cl_club_events/src/views/event_enrolments_view.dart'
    show EventEnrolmentsView;
import 'package:cl_club_events/src/widgets/cards/event_card.dart'
    show EventCard;
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem;

import 'actions.dart';
import 'auth.dart';
import 'pump.dart';

/// Sub-flow start: open the events list for [eventTypeSegment]
/// (`camps`, `programmes` or `one-off`), find the EventCard for
/// [eventTitle], and run its "Enrollments" action. Lands on
/// EventEnrolmentsView.
///
/// Caller must already be logged in as the event's organizer or as an
/// admin (the server enforces this; the affordance is hidden for
/// other roles).
Future<void> navigateToEnrollmentManagementViaUi(
  WidgetTester tester, {
  required String eventTitle,
  String eventTypeSegment = 'camps',
}) async {
  await go(tester, '/memberzone/events/$eventTypeSegment');

  final cardFinder = find.ancestor(
    of: find.text(eventTitle),
    matching: find.byType(EventCard),
  );
  await waitForInList(
    tester,
    cardFinder,
    within: find.byType(Scaffold),
    description: 'EventCard for "$eventTitle" on /events/$eventTypeSegment',
  );

  // Enrollments is one of the card's actions: a button on a wide screen,
  // and on a phone the first action or an entry of its overflow menu
  // (#291). Its handler is called directly.
  ActionItem? enrollments() {
    for (final a in cardActions(tester, cardFinder.first)) {
      if (a.label == 'Enrollments') return a;
    }
    return null;
  }

  await waitFor(
    tester,
    () => enrollments() != null,
    description: '"Enrollments" action on EventCard for "$eventTitle"',
  );
  expect(
    enrollments()!.onPressed,
    isNotNull,
    reason: '"Enrollments" should be enabled for organizer/admin',
  );
  enrollments()!.onPressed!.call();
  await settle(tester);

  await waitFor(
    tester,
    () => find.byType(EventEnrolmentsView).evaluate().isNotEmpty,
    description: 'EventEnrolmentsView to mount',
  );
}
