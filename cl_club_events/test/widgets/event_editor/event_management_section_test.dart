import 'package:cl_club_events/src/models/event_management_messages.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_management_section.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _title = 'workflow_archive_camp';
const _organizer = 'the_organizer';

Event _event({bool archived = false}) => Event(
  id: 1,
  version: 3,
  title: _title,
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 7,
  organizerName: _organizer,
  startTimeUtc: DateTime.utc(2030, 6, 15, 6),
  endTimeUtc: DateTime.utc(2030, 6, 15, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  deletedAtUtc: archived ? DateTime.utc(2026, 2) : null,
);

UserPrivate _person(
  String username, {
  bool admin = false,
  bool coach = false,
  bool superAdmin = false,
}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: superAdmin,
  roles: UserRoles(isAdmin: admin, isCoach: coach),
  createdAtUtc: DateTime.utc(2024),
);

/// Records the lifecycle writes the card sends; [refusal], when set, is
/// thrown by each instead.
class _RecordingEvents extends ClEventsMasterNotifier {
  _RecordingEvents(this.event);

  final Event event;
  final List<String> calls = [];
  Exception? refusal;

  @override
  Future<Map<int, Event>> build() async => {event.id: event};

  void record(String call) {
    calls.add(call);
    final refused = refusal;
    if (refused != null) throw refused;
  }

  @override
  Future<void> deleteEvent(int eventId) async => record('archive($eventId)');

  @override
  Future<Event> restoreEvent(int eventId) async {
    record('unarchive($eventId)');
    return event;
  }

  @override
  Future<void> hardDeleteEvent(int eventId) async => record('delete($eventId)');
}

typedef _Pumped = ({_RecordingEvents events, List<String> left});

Future<_Pumped> _pump(
  WidgetTester tester, {
  required UserPrivate user,
  bool archived = false,
}) async {
  final event = _event(archived: archived);
  final events = _RecordingEvents(event);
  final left = <String>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [clEventsMasterProvider.overrideWith(() => events)],
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventManagementSection(
              event: event,
              currentUser: user,
              onDeleted: () => left.add('left'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return (events: events, left: left);
}

Finder _button(String label) => find.widgetWithText(ShadButton, label);

Future<void> _confirm(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ShadButton, label).last);
  await tester.pumpAndSettle();
}

void main() {
  final admin = _person('an_admin', admin: true);
  final superAdmin = _person('root', superAdmin: true);
  final organizer = _person(_organizer, coach: true);

  group('Issue 36: which Event Management actions are offered', () {
    testWidgets('Issue 36: an admin sees Rename and Archive on a live event', (
      tester,
    ) async {
      await _pump(tester, user: admin);

      expect(_button(EventManagementMessages.rename), findsOneWidget);
      expect(_button(EventManagementMessages.archive), findsOneWidget);
      expect(_button(EventManagementMessages.unarchive), findsNothing);
      expect(_button(EventManagementMessages.delete), findsNothing);
    });

    testWidgets('Issue 36: an admin sees only Unarchive on an archived event', (
      tester,
    ) async {
      await _pump(tester, user: admin, archived: true);

      expect(_button(EventManagementMessages.unarchive), findsOneWidget);
      expect(_button(EventManagementMessages.rename), findsNothing);
      expect(_button(EventManagementMessages.archive), findsNothing);
      expect(_button(EventManagementMessages.delete), findsNothing);
    });

    testWidgets(
      'Issue 36: a super admin sees Delete on an archived event only',
      (tester) async {
        await _pump(tester, user: superAdmin);
        expect(_button(EventManagementMessages.archive), findsOneWidget);
        expect(_button(EventManagementMessages.delete), findsNothing);

        await _pump(tester, user: superAdmin, archived: true);
        expect(_button(EventManagementMessages.unarchive), findsOneWidget);
        expect(_button(EventManagementMessages.delete), findsOneWidget);
      },
    );

    testWidgets(
      'Issue 36: an organizer who is not an admin sees none of the three',
      (tester) async {
        await _pump(tester, user: organizer);

        expect(_button(EventManagementMessages.rename), findsOneWidget);
        expect(_button(EventManagementMessages.archive), findsNothing);
        expect(_button(EventManagementMessages.unarchive), findsNothing);
        expect(_button(EventManagementMessages.delete), findsNothing);
      },
    );
  });

  group('Issue 36: Archive', () {
    testWidgets('Issue 36: it asks first and says members are notified', (
      tester,
    ) async {
      final pumped = await _pump(tester, user: admin);

      await tester.tap(_button(EventManagementMessages.archive));
      await tester.pumpAndSettle();

      expect(
        find.text(EventManagementMessages.archiveConfirm(_title)),
        findsOneWidget,
      );
      expect(
        EventManagementMessages.archiveConfirm(_title),
        contains('enrolled members are notified'),
      );
      expect(pumped.events.calls, isEmpty);
    });

    testWidgets('Issue 36: cancelling the confirmation archives nothing', (
      tester,
    ) async {
      final pumped = await _pump(tester, user: admin);
      await tester.tap(_button(EventManagementMessages.archive));
      await tester.pumpAndSettle();

      await _confirm(tester, 'Cancel');

      expect(pumped.events.calls, isEmpty);
    });

    testWidgets('Issue 36: confirming archives the event and says so', (
      tester,
    ) async {
      final pumped = await _pump(tester, user: admin);
      await tester.tap(_button(EventManagementMessages.archive));
      await tester.pumpAndSettle();

      await _confirm(tester, EventManagementMessages.archive);

      expect(pumped.events.calls, ['archive(1)']);
      expect(find.text(EventManagementMessages.archived), findsOneWidget);
    });
  });

  group('Issue 36: Unarchive', () {
    testWidgets('Issue 36: it restores the event and says so', (tester) async {
      final pumped = await _pump(tester, user: admin, archived: true);

      await tester.tap(_button(EventManagementMessages.unarchive));
      await tester.pumpAndSettle();

      expect(pumped.events.calls, ['unarchive(1)']);
      expect(find.text(EventManagementMessages.unarchived), findsOneWidget);
    });

    testWidgets(
      'Issue 36: a deleted venue is named as what to restore first',
      (tester) async {
        final pumped = await _pump(tester, user: admin, archived: true);
        pumped.events.refusal = const ServerException(
          statusCode: 400,
          code: SdkErrorCode.venueIsDeleted,
          message: 'Cannot restore event: venue is deleted',
        );

        await tester.tap(_button(EventManagementMessages.unarchive));
        await tester.pumpAndSettle();

        expect(
          find.text(EventManagementMessages.venueIsDeleted),
          findsOneWidget,
        );
        expect(
          EventManagementMessages.venueIsDeleted,
          contains('Restore the venue first'),
        );
        expect(find.textContaining('Cannot restore event'), findsNothing);
      },
    );
  });

  group('Issue 36: Delete', () {
    testWidgets('Issue 36: it names the event and says it is permanent', (
      tester,
    ) async {
      final pumped = await _pump(tester, user: superAdmin, archived: true);

      await tester.tap(_button(EventManagementMessages.delete));
      await tester.pumpAndSettle();

      final message = EventManagementMessages.deleteConfirm(_title);
      expect(find.text(message), findsOneWidget);
      expect(message, contains(_title));
      expect(message, contains('enrolments and attendance'));
      expect(message, contains('permanently'));
      expect(pumped.events.calls, isEmpty);
      expect(pumped.left, isEmpty);
    });

    testWidgets('Issue 36: confirming deletes the event and leaves the page', (
      tester,
    ) async {
      final pumped = await _pump(tester, user: superAdmin, archived: true);
      await tester.tap(_button(EventManagementMessages.delete));
      await tester.pumpAndSettle();

      await _confirm(tester, EventManagementMessages.delete);

      expect(pumped.events.calls, ['delete(1)']);
      expect(pumped.left, ['left']);
    });

    testWidgets('Issue 36: a refused delete stays on the page', (tester) async {
      final pumped = await _pump(tester, user: superAdmin, archived: true);
      pumped.events.refusal = const ServerException(
        statusCode: 422,
        code: SdkErrorCode.hardDeleteNeedsSoftDelete,
        message: 'raw server text',
      );
      await tester.tap(_button(EventManagementMessages.delete));
      await tester.pumpAndSettle();

      await _confirm(tester, EventManagementMessages.delete);

      expect(pumped.left, isEmpty);
      expect(
        find.text(EventManagementMessages.deleteNeedsArchive),
        findsOneWidget,
      );
      expect(find.textContaining('raw server text'), findsNothing);
    });
  });
}
