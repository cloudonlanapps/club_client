import 'package:cl_club_events/src/widgets/cards/occurrence_card.dart';
import 'package:cl_club_events/src/widgets/requests_mark_icon.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _eventId = 441;
const _organizer = 'organizer441';
const _title = 'Ice Hockey Morning Batch 1';

final DateTime _slot = DateTime.now().toUtc().add(const Duration(days: 3));

final ({DateTime from, DateTime to}) _range = (
  from: DateTime.now().toUtc(),
  to: DateTime.now().toUtc().add(const Duration(days: 30)),
);

Event _programme() => Event(
  id: _eventId,
  title: _title,
  description: '',
  type: EventType.programme,
  visibility: Visibility.public,
  venueId: 1,
  organizerName: _organizer,
  rrule: 'FREQ=DAILY',
  startTimeUtc: _slot,
  endTimeUtc: _slot.add(const Duration(hours: 1)),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

Occurrence _session({int leave = 0, int marked = 0}) => Occurrence(
  eventId: _eventId,
  originalStartTimeUtc: _slot,
  actualStartTimeUtc: _slot,
  actualEndTimeUtc: _slot.add(const Duration(hours: 1)),
  status: OccurrenceStatus.scheduled,
  venueId: 1,
  attendanceExpected: 5,
  attendanceMarked: marked,
  leaveRequestsPending: leave,
  enrollmentRequestsPending: 0,
  withdrawalRequestsPending: 0,
);

class _Auth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => UserPrivate(
    username: _organizer,
    displayName: _organizer,
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(isCoach: true),
    createdAtUtc: DateTime.utc(2026),
  );
}

class _Events extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async => {_eventId: _programme()};
}

/// Draws the organizer's card of [session] at [width].
Future<void> _pump(
  WidgetTester tester,
  Occurrence session, {
  double width = 900,
}) async {
  tester.view
    ..physicalSize = Size(width, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(_Auth.new),
        clEventsMasterProvider.overrideWith(_Events.new),
        clOccurrencesProvider(
          (from: _range.from, to: _range.to),
        ).overrideWith((ref) async => [session]),
      ],
      child: ShadApp(
        home: Scaffold(
          body: OccurrenceCard(
            eventId: _eventId,
            occurrenceTime: _slot,
            range: _range,
            onMarkAttendance: (_, _) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Whether [label] is drawn as a button on the card, not inside ⋮.
bool _isButton(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(ShadButton))
    .evaluate()
    .isNotEmpty;

void main() {
  for (final width in [900.0, 360.0]) {
    final screen = width < 600 ? 'a phone' : 'a wide screen';

    testWidgets(
      'Issue 441: on $screen, a pending request makes Manage requests the '
      'button, Reschedule goes into the menu, and the title carries ⏳',
      (tester) async {
        await _pump(tester, _session(leave: 1), width: width);
        expect(_isButton('Manage requests'), isTrue);
        expect(find.text('Reschedule'), findsNothing);
        expect(find.byIcon(LucideIcons.hourglass), findsNWidgets(2));
        final title = tester.getRect(find.text(_title));
        final marks = find.byType(RequestsMarkIcon);
        expect(
          marks.evaluate().map((e) => tester.getRect(find.byWidget(e.widget))),
          contains(
            predicate<Rect>(
              (r) =>
                  r.left >= title.right &&
                  (r.center.dy - title.center.dy).abs() < title.height,
              'beside the title',
            ),
          ),
        );
      },
    );

    testWidgets(
      'Issue 441: on $screen, approved leave alone also leads with Manage '
      'requests and shows ◐ beside the title',
      (tester) async {
        await _pump(tester, _session(marked: 2), width: width);
        expect(_isButton('Manage requests'), isTrue);
        expect(find.text('Reschedule'), findsNothing);
        expect(find.byIcon(LucideIcons.contrast), findsNWidgets(2));
      },
    );

    testWidgets(
      'Issue 441: on $screen, with nothing waiting Reschedule stays the '
      'button and the card shows no mark',
      (tester) async {
        await _pump(tester, _session(), width: width);
        expect(_isButton('Reschedule'), isTrue);
        expect(find.text('Manage requests'), findsNothing);
        expect(find.byType(RequestsMarkIcon), findsNothing);
      },
    );
  }

  testWidgets(
    'Issue 441: with nothing waiting, Manage requests sits in the ⋮ menu '
    'without a mark',
    (
      tester,
    ) async {
      await _pump(tester, _session());
      expect(find.byType(RequestsMarkIcon), findsNothing);
      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();
      expect(find.text('Manage requests'), findsOneWidget);
      expect(find.byType(RequestsMarkIcon), findsNothing);
    },
  );

  testWidgets(
    'Issue 441: with a mark, Reschedule is still offered in the ⋮ menu',
    (tester) async {
      await _pump(tester, _session(leave: 1));
      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();
      expect(find.text('Reschedule'), findsOneWidget);
    },
  );
}
