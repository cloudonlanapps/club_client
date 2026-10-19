import 'package:cl_club_events/src/views/event_details_view.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_marketing_link_card.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/credit_scope.dart';

Future<void> _pump(
  WidgetTester tester,
  UserPrivate user, {
  required void Function()? onOpenMarketing,
}) async {
  await tester.pumpWidget(
    creditScope(
      user: user,
      creditSystem: false,
      events: {campId: staffed(campId, EventType.camp)},
      child: EventDetailsView(
        currentUser: user,
        eventId: campId,
        onOpenMarketing: onOpenMarketing,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group("Issue 1: the way to an event's Marketing page", () {
    testWidgets('Issue 1: whoever manages the event gets it', (tester) async {
      var opened = 0;
      await _pump(
        tester,
        person('an_admin', admin: true),
        onOpenMarketing: () => opened++,
      );

      await tester.ensureVisible(find.byType(EventMarketingLinkCard));
      await tester.tap(find.text('Edit marketing'));

      expect(opened, 1);
    });

    testWidgets('Issue 1: a coach who is not the organizer does not', (
      tester,
    ) async {
      await _pump(
        tester,
        person(staffCoach, coach: true),
        onOpenMarketing: () {},
      );

      expect(find.byType(EventMarketingLinkCard), findsNothing);
    });
  });
}
