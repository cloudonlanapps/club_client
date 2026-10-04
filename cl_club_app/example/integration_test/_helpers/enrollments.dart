// Enrollment-management navigation for integration tests.
//
// Owns:
//   * navigateToEnrollmentManagementViaUi — from any starting point,
//     navigates to /memberzone/events/<type> and taps the "Enrollments"
//     ActionButton on the matching event's card. Lands on
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
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import 'auth.dart';
import 'pump.dart';

/// Sub-flow start: open the events list for [eventTypeSegment]
/// (`camps`, `programmes` or `one-off`), find the EventCard for
/// [eventTitle], and tap its "Enrollments" ActionButton. Lands on
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
  await waitFor(
    tester,
    () => cardFinder.evaluate().isNotEmpty,
    description: 'EventCard for "$eventTitle" on /events/$eventTypeSegment',
  );

  // The Enrollments button lives inside the EventCard's primaryAction
  // slot. Tapping ActionButton's onPressed directly mirrors workflow1's
  // pattern for off-screen buttons (the events list scrolls on long
  // event lists, so the card may sit below the fold).
  final enrollmentsBtn = find.descendant(
    of: cardFinder,
    matching: find.widgetWithText(ActionButton, 'Enrollments'),
  );
  await waitFor(
    tester,
    () => enrollmentsBtn.evaluate().isNotEmpty,
    description: '"Enrollments" ActionButton on EventCard for "$eventTitle"',
  );
  final btn = tester.widget<ActionButton>(enrollmentsBtn);
  expect(
    btn.onPressed,
    isNotNull,
    reason: '"Enrollments" ActionButton should be enabled for organizer/admin',
  );
  btn.onPressed!.call();
  await settle(tester);

  await waitFor(
    tester,
    () => find.byType(EventEnrolmentsView).evaluate().isNotEmpty,
    description: 'EventEnrolmentsView to mount',
  );
}
