import 'package:cl_club_events/src/views/event_details_view.dart';
import 'package:cl_club_events/src/widgets/event_editor/editable_event_body.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_schedule_section.dart';
import 'package:cl_club_events/src/widgets/events_preview/cl_event_preview.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/credit_scope.dart';

Future<void> _pump(WidgetTester tester, UserPrivate user) async {
  await tester.pumpWidget(
    creditScope(
      user: user,
      creditSystem: false,
      events: {campId: staffed(campId, EventType.camp)},
      child: EventDetailsView(currentUser: user, eventId: campId),
    ),
  );
  await tester.pump();
  await tester.pump();
}

bool _scheduleEditable(Widget w) => w is EventScheduleSection && w.canEdit;

void main() {
  group('Issue 150: the organizer edits their own event', () {
    testWidgets('Issue 150: an organizer who is a coach gets the editor', (
      tester,
    ) async {
      await _pump(tester, person(staffOrganizer, coach: true));

      expect(find.byType(EditableEventBody), findsOneWidget);
      expect(find.byType(ClEventPreview), findsNothing);
      expect(find.byWidgetPredicate(_scheduleEditable), findsOneWidget);
    });

    testWidgets(
      'Issue 150: an admin who is not the organizer gets the editor',
      (
        tester,
      ) async {
        await _pump(tester, person('an_admin', admin: true));

        expect(find.byType(EditableEventBody), findsOneWidget);
        expect(find.byWidgetPredicate(_scheduleEditable), findsOneWidget);
      },
    );

    testWidgets('Issue 150: an assigned coach reads the event, no editor', (
      tester,
    ) async {
      await _pump(tester, person(staffCoach, coach: true));

      expect(find.byType(EditableEventBody), findsNothing);
      expect(find.byType(ClEventPreview), findsOneWidget);
    });

    testWidgets('Issue 150: any other coach reads the event, no editor', (
      tester,
    ) async {
      await _pump(tester, person('other_coach', coach: true));

      expect(find.byType(EditableEventBody), findsNothing);
      expect(find.byType(ClEventPreview), findsOneWidget);
    });
  });
}
