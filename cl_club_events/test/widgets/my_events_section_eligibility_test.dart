import 'package:cl_club_events/src/models/event_display_status.dart';
import 'package:cl_club_events/src/providers/event_display_status.dart';
import 'package:cl_club_events/src/widgets/cards/event_card.dart';
import 'package:cl_club_events/src/widgets/my_events_section.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show NoLongerEligibleLabel;

/// The Events section of a member's profile as staff see it marks the
/// events the member no longer matches (club_client#43); a member's own
/// views do not.

const _member = 'workflow_member';

final DateTime _start = DateTime.now().toUtc().add(const Duration(days: 30));

Event _event(int id, String title, {EventType type = EventType.programme}) =>
    Event(
      id: id,
      title: title,
      description: '',
      type: type,
      visibility: Visibility.private,
      venueId: 1,
      // Still to come: the section lists current events (club_client#88).
      startTimeUtc: _start,
      endTimeUtc: _start.add(const Duration(hours: 2)),
      createdAtUtc: DateTime.utc(2026),
      updatedAtUtc: DateTime.utc(2026),
    );

Enrollment _enrollment(int eventId, {bool eligible = true}) => Enrollment(
  id: 100 + eventId,
  membername: _member,
  eventId: eventId,
  status: EnrollmentStatus.assigned,
  createdAtUtc: DateTime.utc(2026),
  eligible: eligible,
);

class _Events extends ClEventsMasterNotifier {
  _Events(this.events);
  final Map<int, Event> events;
  @override
  Future<Map<int, Event>> build() async => events;
}

class _MyEvents extends ClMyEventsMasterNotifier {
  _MyEvents(this.events);
  final List<Event> events;
  @override
  Future<List<Event>> build(String arg) async => events;
}

class _Auth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => UserPrivate(
    username: 'workflow_admin',
    displayName: 'Admin',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(isAdmin: true),
    createdAtUtc: DateTime.utc(2024),
  );
}

/// Pumps the section for [_member]. [enrollments] is the member's enrolment
/// per event id (none = not enrolled); each read of one is added to
/// [reads].
Future<void> _pump(
  WidgetTester tester, {
  required List<Event> events,
  required Map<int, Enrollment> enrollments,
  bool enrolledOnly = true,
  bool markIneligible = false,
  List<int>? reads,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(
          () => _Events({for (final e in events) e.id: e}),
        ),
        clMyEventsMasterProvider.overrideWith(() => _MyEvents(events)),
        clMyEnrollmentProvider.overrideWith((ref, key) async {
          reads?.add(key.eventId);
          return enrollments[key.eventId];
        }),
        authStateProvider.overrideWith(_Auth.new),
        imageAuthHeadersProvider.overrideWith((ref) async => const {}),
        for (final e in events) ...[
          eventCoverImageProvider(e.id).overrideWith((ref) async => null),
          eventDisplayStatusProvider(
            e.id,
          ).overrideWith((ref) async => EventDisplayStatus.ongoing),
        ],
      ],
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MyEventsSection(
              username: _member,
              enrolledOnly: enrolledOnly,
              markIneligible: markIneligible,
            ),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _cardOf(String title) => find.ancestor(
  of: find.text(title),
  matching: find.byType(EventCard),
);

List<int> _cardOrder(WidgetTester tester) => tester
    .widgetList<EventCard>(find.byType(EventCard))
    .map((c) => c.eventId)
    .toList();

final List<Event> _events = [
  _event(1, 'Skating'),
  _event(2, 'Juniors hockey'),
  _event(3, 'Summer camp', type: EventType.camp),
  _event(4, 'Minis camp', type: EventType.camp),
];

void main() {
  group("Issue 43: the Events section of a member's profile, for staff", () {
    testWidgets('Issue 43: an event whose enrolment is reported not '
        'eligible carries the outlined label; the others have none', (
      tester,
    ) async {
      await _pump(
        tester,
        events: _events,
        enrollments: {
          1: _enrollment(1),
          2: _enrollment(2, eligible: false),
          3: _enrollment(3),
          4: _enrollment(4),
        },
        markIneligible: true,
      );

      expect(find.byType(NoLongerEligibleLabel), findsOneWidget);
      final label = find.descendant(
        of: _cardOf('Juniors hockey'),
        matching: find.byType(NoLongerEligibleLabel),
      );
      expect(label, findsOneWidget);
      expect(
        find.descendant(
          of: label,
          matching: find.text(NoLongerEligibleLabel.text),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _cardOf('Skating'),
          matching: find.byType(NoLongerEligibleLabel),
        ),
        findsNothing,
      );
    });

    testWidgets('Issue 43: such events are listed first, whatever their '
        'type, and each event shows once', (tester) async {
      await _pump(
        tester,
        events: _events,
        enrollments: {
          1: _enrollment(1),
          2: _enrollment(2, eligible: false),
          3: _enrollment(3),
          4: _enrollment(4, eligible: false),
        },
        markIneligible: true,
      );

      expect(_cardOrder(tester), [2, 4, 1, 3]);
      // The ones the member still matches stay under their type.
      expect(find.text('Programmes'), findsOneWidget);
      expect(find.text('Camps'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Minis camp')).dy,
        lessThan(tester.getTopLeft(find.text('Programmes')).dy),
      );
    });

    testWidgets('Issue 43: the section counts them above the cards', (
      tester,
    ) async {
      await _pump(
        tester,
        events: _events,
        enrollments: {
          1: _enrollment(1),
          2: _enrollment(2, eligible: false),
          3: _enrollment(3),
          4: _enrollment(4, eligible: false),
        },
        markIneligible: true,
      );

      final count = find.text('2 events no longer match this member');
      expect(count, findsOneWidget);
      expect(
        tester.getTopLeft(count).dy,
        lessThan(tester.getTopLeft(find.text('Juniors hockey')).dy),
      );
      expect(
        tester.getTopLeft(count).dy,
        greaterThan(tester.getTopLeft(find.text('Events')).dy),
      );
    });

    testWidgets('Issue 43: one such event reads in the singular', (
      tester,
    ) async {
      await _pump(
        tester,
        events: _events,
        enrollments: {1: _enrollment(1), 2: _enrollment(2, eligible: false)},
        markIneligible: true,
      );

      expect(
        find.text('1 event no longer matches this member'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 43: with every enrolment eligible there is no label '
        'and no count, and the order is unchanged', (tester) async {
      await _pump(
        tester,
        events: _events,
        enrollments: {for (final e in _events) e.id: _enrollment(e.id)},
        markIneligible: true,
      );

      expect(find.byType(NoLongerEligibleLabel), findsNothing);
      expect(find.textContaining('no longer match'), findsNothing);
      expect(_cardOrder(tester), [1, 2, 3, 4]);
    });

    testWidgets('Issue 43: the mark comes from the enrolments the section '
        'already reads: one read per event', (tester) async {
      final reads = <int>[];
      await _pump(
        tester,
        events: _events,
        enrollments: {
          1: _enrollment(1),
          2: _enrollment(2, eligible: false),
          3: _enrollment(3),
          4: _enrollment(4),
        },
        markIneligible: true,
        reads: reads,
      );

      expect(reads..sort(), [1, 2, 3, 4]);
    });
  });

  group("Issue 43: a member's own events views are unchanged", () {
    testWidgets('Issue 43: without markIneligible there is no label, no '
        'count, no reordering and no extra read', (tester) async {
      final reads = <int>[];
      await _pump(
        tester,
        events: _events,
        enrollments: {
          1: _enrollment(1),
          2: _enrollment(2, eligible: false),
          3: _enrollment(3),
          4: _enrollment(4, eligible: false),
        },
        reads: reads,
      );

      expect(find.byType(NoLongerEligibleLabel), findsNothing);
      expect(find.textContaining('no longer match'), findsNothing);
      expect(_cardOrder(tester), [1, 2, 3, 4]);
      expect(reads..sort(), [1, 2, 3, 4]);
    });

    testWidgets('Issue 43: the full list (not enrolledOnly) shows no label '
        'and no count either', (tester) async {
      await _pump(
        tester,
        events: _events,
        enrollments: {
          1: _enrollment(1),
          2: _enrollment(2, eligible: false),
        },
        enrolledOnly: false,
      );

      expect(_cardOrder(tester), [1, 2, 3, 4]);
      expect(find.byType(NoLongerEligibleLabel), findsNothing);
      expect(find.textContaining('no longer match'), findsNothing);
    });
  });
}
