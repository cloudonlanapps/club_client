import 'package:cl_club_events/src/models/event_management_messages.dart';
import 'package:cl_club_events/src/views/event_details_view.dart';
import 'package:cl_club_events/src/widgets/event_editor/archived_event_body.dart';
import 'package:cl_club_events/src/widgets/event_editor/editable_event_body.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_management_section.dart';
import 'package:cl_club_events/src/widgets/events_preview/cl_event_enrolments_summary.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

import '../support/credit_scope.dart';

Future<void> _pump(
  WidgetTester tester,
  UserPrivate user, {
  required bool archived,
}) async {
  final camp = staffed(campId, EventType.camp).copyWith(
    deletedAtUtc: () => archived ? DateTime.utc(2026, 2) : null,
  );
  await tester.pumpWidget(
    creditScope(
      user: user,
      creditSystem: false,
      events: {campId: camp},
      child: EventDetailsView(currentUser: user, eventId: campId),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('Issue 36: the detail page of an archived event', () {
    testWidgets(
      'Issue 36: it is read-only apart from Event Management',
      (tester) async {
        await _pump(tester, person('an_admin', admin: true), archived: true);

        expect(find.byType(ArchivedEventBody), findsOneWidget);
        expect(find.byType(EditableEventBody), findsNothing);
        expect(find.byType(SectionEditButton), findsNothing);
        expect(find.byType(ClEventEnrolmentsSummary), findsNothing);
        expect(find.byType(EventManagementSection), findsOneWidget);
        expect(
          find.text(EventManagementMessages.archivedNotice),
          findsOneWidget,
        );
        expect(find.text(EventManagementMessages.unarchive), findsOneWidget);
        expect(find.text(EventManagementMessages.rename), findsNothing);
      },
    );

    testWidgets('Issue 36: a live event keeps its editor', (tester) async {
      await _pump(tester, person('an_admin', admin: true), archived: false);

      expect(find.byType(EditableEventBody), findsOneWidget);
      expect(find.byType(ArchivedEventBody), findsNothing);
      expect(find.text(EventManagementMessages.archive), findsOneWidget);
    });
  });
}
