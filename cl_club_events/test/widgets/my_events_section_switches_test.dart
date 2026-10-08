import 'package:cl_club_events/src/providers/event_display_status.dart';
import 'package:cl_club_events/src/widgets/cards/event_card.dart';
import 'package:cl_club_events/src/widgets/my_events_section.dart';
import 'package:cl_club_events/src/widgets/my_events_section_body.dart';
import 'package:cl_club_events/src/widgets/my_events_section_header.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The Events section of a profile lists the member's current events and
/// has a switch for the cancelled ones and one for the past ones
/// (club_client#88).

const _member = 'workflow_member';

final DateTime _now = DateTime.now().toUtc();

/// An event that starts [startsIn] from now and lasts two hours. A camp or
/// one-off with a negative [startsIn] is over; [cutoffIn] sets a cutoff
/// that far from now.
Event _event(
  int id,
  String title, {
  EventType type = EventType.programme,
  Duration startsIn = const Duration(days: 30),
  Duration? cutoffIn,
}) {
  final start = _now.add(startsIn);
  return Event(
    id: id,
    title: title,
    description: '',
    type: type,
    visibility: Visibility.public,
    venueId: 1,
    startTimeUtc: start,
    endTimeUtc: start.add(const Duration(hours: 2)),
    untilTimeUtc: cutoffIn == null ? null : _now.add(cutoffIn),
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
  );
}

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

const int _running = 1;
const int _upcomingCamp = 2;
const int _endedCamp = 3;
const int _cancelledCamp = 4;
const int _endedProgramme = 5;
const int _closingProgramme = 6;

/// One event of each kind the section tells apart.
final List<Event> _events = [
  _event(_running, 'Skating'),
  _event(_upcomingCamp, 'Summer camp', type: EventType.camp),
  _event(
    _endedCamp,
    'Winter camp',
    type: EventType.camp,
    startsIn: const Duration(days: -30),
  ),
  _event(
    _cancelledCamp,
    'Rained-off camp',
    type: EventType.camp,
    startsIn: const Duration(days: -20),
    cutoffIn: const Duration(days: -21),
  ),
  _event(
    _endedProgramme,
    'Old juniors',
    startsIn: const Duration(days: -200),
    cutoffIn: const Duration(days: -10),
  ),
  _event(
    _closingProgramme,
    'Closing seniors',
    startsIn: const Duration(days: -200),
    cutoffIn: const Duration(days: 10),
  ),
];

Map<int, Enrollment> _enrolledOnAll() => {
  for (final e in _events) e.id: _enrollment(e.id),
};

/// Pumps the section for [_member] as a staff profile shows it
/// ([enrolledOnly], the default) or as the member's own profile does.
Future<void> _pump(
  WidgetTester tester, {
  required Map<int, Enrollment> enrollments,
  List<Event>? events,
  bool enrolledOnly = true,
  bool markIneligible = false,
  List<int>? reads,
}) async {
  final shown = events ?? _events;
  await tester.binding.setSurfaceSize(const Size(900, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(
          () => _Events({for (final e in shown) e.id: e}),
        ),
        clMyEventsMasterProvider.overrideWith(() => _MyEvents(shown)),
        clMyEnrollmentProvider.overrideWith((ref, key) async {
          reads?.add(key.eventId);
          return enrollments[key.eventId];
        }),
        authStateProvider.overrideWith(_Auth.new),
        imageAuthHeadersProvider.overrideWith((ref) async => const {}),
        for (final e in shown) ...[
          eventCoverImageProvider(e.id).overrideWith((ref) async => null),
          eventDisplayStatusProvider(
            e.id,
          ).overrideWith((ref) async => computeDisplayStatus(e, const [])),
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
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _switchOf(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
  matching: find.byType(ShadSwitch),
);

Future<void> _turnOn(WidgetTester tester, String label) async {
  await tester.tap(_switchOf(label));
  await _settle(tester);
}

Set<int> _cards(WidgetTester tester) => tester
    .widgetList<EventCard>(find.byType(EventCard))
    .map((c) => c.eventId)
    .toSet();

Finder _cardOf(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(EventCard));

const Set<int> _current = {_running, _upcomingCamp, _closingProgramme};

void main() {
  group('Issue 88: the switches of the Events section', () {
    testWidgets('Issue 88: with both switches off only current events are '
        'listed, on a staff profile', (tester) async {
      await _pump(tester, enrollments: _enrolledOnAll());

      expect(_cards(tester), _current);
      expect(find.text(MyEventsSectionHeader.cancelledSwitchLabel), findsOne);
      expect(find.text(MyEventsSectionHeader.pastSwitchLabel), findsOne);
    });

    testWidgets('Issue 88: with both switches off only current events are '
        "listed, on the member's own profile", (tester) async {
      await _pump(
        tester,
        enrollments: _enrolledOnAll(),
        enrolledOnly: false,
      );

      expect(_cards(tester), _current);
    });

    testWidgets('Issue 88: a programme whose cutoff is still ahead is '
        'current', (tester) async {
      await _pump(tester, enrollments: _enrolledOnAll());

      expect(_cardOf('Closing seniors'), findsOneWidget);
    });

    testWidgets('Issue 88: Cancelled events adds the cancelled events and '
        'no past one', (tester) async {
      await _pump(tester, enrollments: _enrolledOnAll());

      await _turnOn(tester, MyEventsSectionHeader.cancelledSwitchLabel);

      expect(_cards(tester), {..._current, _cancelledCamp});
    });

    testWidgets('Issue 88: Past events adds the events that are over and '
        'no cancelled one', (tester) async {
      await _pump(tester, enrollments: _enrolledOnAll());

      await _turnOn(tester, MyEventsSectionHeader.pastSwitchLabel);

      expect(_cards(tester), {..._current, _endedCamp, _endedProgramme});
    });

    testWidgets('Issue 88: with both switches on every enrolled event is '
        'listed', (tester) async {
      await _pump(tester, enrollments: _enrolledOnAll());

      await _turnOn(tester, MyEventsSectionHeader.cancelledSwitchLabel);
      await _turnOn(tester, MyEventsSectionHeader.pastSwitchLabel);

      expect(_cards(tester), {for (final e in _events) e.id});
    });

    testWidgets('Issue 88: turning a switch off again hides its '
        'events', (tester) async {
      await _pump(tester, enrollments: _enrolledOnAll());

      await _turnOn(tester, MyEventsSectionHeader.pastSwitchLabel);
      expect(_cards(tester), contains(_endedCamp));
      await _turnOn(tester, MyEventsSectionHeader.pastSwitchLabel);

      expect(_cards(tester), _current);
    });
  });

  group('Issue 88: only events the member is enrolled on', () {
    testWidgets("Issue 88: on the member's own profile a cancelled or past "
        'event without an enrolment is never listed', (tester) async {
      await _pump(
        tester,
        enrollments: {
          _running: _enrollment(_running),
          _endedCamp: _enrollment(_endedCamp),
        },
        enrolledOnly: false,
      );

      await _turnOn(tester, MyEventsSectionHeader.cancelledSwitchLabel);
      await _turnOn(tester, MyEventsSectionHeader.pastSwitchLabel);

      // Current events show whether or not the member is enrolled, as
      // before; of the rest only the one with an enrolment.
      expect(_cards(tester), {..._current, _endedCamp});
    });

    testWidgets("Issue 88: on the member's own profile no enrolment is "
        'read while both switches are off', (tester) async {
      final reads = <int>[];
      await _pump(
        tester,
        enrollments: _enrolledOnAll(),
        enrolledOnly: false,
        reads: reads,
      );

      expect(
        reads.toSet().intersection({
          _endedCamp,
          _cancelledCamp,
          _endedProgramme,
        }),
        isEmpty,
      );
    });
  });

  group('Issue 88: what a cancelled or past event shows', () {
    testWidgets('Issue 88: they are listed after the current events, under '
        'headings that say what they are', (tester) async {
      await _pump(tester, enrollments: _enrolledOnAll());
      expect(find.text(MyEventsSectionBody.cancelledHeading), findsNothing);
      expect(find.text(MyEventsSectionBody.pastHeading), findsNothing);

      await _turnOn(tester, MyEventsSectionHeader.cancelledSwitchLabel);
      await _turnOn(tester, MyEventsSectionHeader.pastSwitchLabel);

      double top(Finder finder) => tester.getTopLeft(finder).dy;
      final cancelled = top(find.text(MyEventsSectionBody.cancelledHeading));
      final past = top(find.text(MyEventsSectionBody.pastHeading));
      for (final title in ['Skating', 'Summer camp', 'Closing seniors']) {
        expect(top(find.text(title)), lessThan(cancelled));
      }
      expect(top(find.text('Rained-off camp')), greaterThan(cancelled));
      expect(top(find.text('Rained-off camp')), lessThan(past));
      expect(top(find.text('Winter camp')), greaterThan(past));
      expect(top(find.text('Old juniors')), greaterThan(past));
    });

    testWidgets('Issue 88: staff see an enrolment the member no longer '
        'matches on a cancelled event counted once its switch is on', (
      tester,
    ) async {
      await _pump(
        tester,
        enrollments: {
          ..._enrolledOnAll(),
          _cancelledCamp: _enrollment(_cancelledCamp, eligible: false),
        },
        markIneligible: true,
      );
      expect(find.textContaining('no longer match'), findsNothing);

      await _turnOn(tester, MyEventsSectionHeader.cancelledSwitchLabel);

      expect(
        find.text(MyEventsSectionBody.ineligibleCountText(1)),
        findsOneWidget,
      );
    });
  });

  group('Issue 88: a member with no current events', () {
    testWidgets('Issue 88: the section says so and still offers the '
        'switches', (tester) async {
      final over = [_events[2], _events[3]];
      await _pump(
        tester,
        events: over,
        enrollments: {for (final e in over) e.id: _enrollment(e.id)},
      );

      expect(_cards(tester), isEmpty);
      expect(find.text(MyEventsSectionBody.emptyText), findsOneWidget);

      await _turnOn(tester, MyEventsSectionHeader.pastSwitchLabel);

      expect(_cards(tester), {_endedCamp});
      expect(find.text(MyEventsSectionBody.emptyText), findsNothing);
    });
  });
}
