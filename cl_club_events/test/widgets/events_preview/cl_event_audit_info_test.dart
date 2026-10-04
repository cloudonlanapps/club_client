import 'package:cl_club_events/src/models/event_display_status.dart';
import 'package:cl_club_events/src/providers/event_display_status.dart';
import 'package:cl_club_events/src/widgets/events_preview/cl_event_audit_info.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

DateTime _ts(int day) => DateTime.utc(2026, 5, day);

Event eventFixture({
  String? organizerName,
  DateTime? deletedAtUtc,
  EventType type = EventType.camp,
}) {
  return Event(
    id: 1,
    title: 'Test Event',
    description: '',
    type: type,
    visibility: Visibility.public,
    venueId: 1,
    startTimeUtc: _ts(20),
    endTimeUtc: _ts(20).add(const Duration(hours: 2)),
    createdAtUtc: _ts(1),
    updatedAtUtc: _ts(5),
    organizerName: organizerName,
    deletedAtUtc: deletedAtUtc,
  );
}

UserPrivate userFixture({
  bool isAdmin = false,
  bool isCoach = false,
}) {
  return UserPrivate(
    username: 'u1',
    displayName: 'U One',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: UserRoles(isAdmin: isAdmin, isCoach: isCoach),
    createdAtUtc: _ts(1),
  );
}

Widget wrap(
  Widget child, {
  required Event event,
  EventDisplayStatus? status,
}) {
  return ProviderScope(
    overrides: [
      eventDisplayStatusProvider(event.id).overrideWith(
        (ref) async => status ?? EventDisplayStatus.comingSoon,
      ),
    ],
    child: ShadApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets(
    'Issue 263: non-admin non-coach renders nothing',
    (tester) async {
      final event = eventFixture(organizerName: 'Coach Pat');
      await tester.pumpWidget(
        wrap(
          ClEventAuditInfo(event: event, currentUser: userFixture()),
          event: event,
        ),
      );
      await tester.pump();
      expect(find.text('Event Info'), findsNothing);
      expect(find.text('Coach Pat'), findsNothing);
    },
  );

  testWidgets(
    'Issue 263: null currentUser renders nothing',
    (tester) async {
      final event = eventFixture(organizerName: 'Coach Pat');
      await tester.pumpWidget(
        wrap(
          ClEventAuditInfo(event: event, currentUser: null),
          event: event,
        ),
      );
      await tester.pump();
      expect(find.text('Event Info'), findsNothing);
    },
  );

  testWidgets(
    'Issue 263: admin viewing active event sees organizer, status, timestamps',
    (tester) async {
      final event = eventFixture(organizerName: 'Coach Pat');
      await tester.pumpWidget(
        wrap(
          ClEventAuditInfo(
            event: event,
            currentUser: userFixture(isAdmin: true),
          ),
          event: event,
          status: EventDisplayStatus.ongoing,
        ),
      );
      await tester.pump();

      expect(find.text('Event Info'), findsOneWidget);
      expect(find.text('Organizer'), findsOneWidget);
      expect(find.text('Coach Pat'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
      expect(find.text('Last updated'), findsOneWidget);
      expect(find.text('Deleted'), findsNothing);
    },
  );

  testWidgets(
    'Issue 263: coach viewing event sees the audit card',
    (tester) async {
      final event = eventFixture(organizerName: 'Coach Pat');
      await tester.pumpWidget(
        wrap(
          ClEventAuditInfo(
            event: event,
            currentUser: userFixture(isCoach: true),
          ),
          event: event,
        ),
      );
      await tester.pump();
      expect(find.text('Event Info'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 263: deleted event shows Deleted row',
    (tester) async {
      final event = eventFixture(
        organizerName: 'Coach Pat',
        deletedAtUtc: _ts(10),
      );
      await tester.pumpWidget(
        wrap(
          ClEventAuditInfo(
            event: event,
            currentUser: userFixture(isAdmin: true),
          ),
          event: event,
        ),
      );
      await tester.pump();
      expect(find.text('Deleted'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 263: null organizerName suppresses the organizer row',
    (tester) async {
      final event = eventFixture();
      await tester.pumpWidget(
        wrap(
          ClEventAuditInfo(
            event: event,
            currentUser: userFixture(isAdmin: true),
          ),
          event: event,
        ),
      );
      await tester.pump();
      expect(find.text('Organizer'), findsNothing);
      expect(find.text('Event Info'), findsOneWidget);
    },
  );
}
