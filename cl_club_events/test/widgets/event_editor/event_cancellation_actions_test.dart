import 'package:cl_club_events/src/models/event_cancellation_form_helpers.dart';
import 'package:cl_club_events/src/models/event_cancellation_messages.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_management_section.dart';
import 'package:cl_club_forms/src/widgets/event_cancellation/event_cancellation_form_validators.dart'
    show EventCancellationFormValidators;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEventsMasterNotifier,
        clEventsMasterProvider,
        clOccurrencesProvider,
        clSingleOccurrenceProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _organizer = 'the_organizer';
const _reason = 'The rink is closed';
const _occurrenceVersion = 6;

/// Midnight UTC, [days] ahead of today: the sessions stay in the future.
DateTime _day(int days) {
  final d = DateTime.now().toUtc().add(Duration(days: days));
  return DateTime.utc(d.year, d.month, d.day, 6);
}

Event _event(
  EventType type, {
  bool cancelled = false,
  bool archived = false,
}) => Event(
  id: 1,
  version: 3,
  title: 'workflow_cancel_${type.name}',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 7,
  organizerName: _organizer,
  rrule: type == EventType.camp ? 'FREQ=DAILY;COUNT=3' : null,
  startTimeUtc: _day(10),
  endTimeUtc: _day(10).add(const Duration(hours: 2)),
  untilTimeUtc: cancelled ? _day(11) : null,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  deletedAtUtc: archived ? DateTime.utc(2026, 2) : null,
);

Occurrence _occurrence(
  DateTime start, {
  OccurrenceStatus status = OccurrenceStatus.scheduled,
  int eventId = 1,
}) => Occurrence(
  eventId: eventId,
  originalStartTimeUtc: start,
  actualStartTimeUtc: start,
  actualEndTimeUtc: start.add(const Duration(hours: 2)),
  status: status,
  venueId: 7,
  version: _occurrenceVersion,
);

UserPrivate _person(
  String username, {
  bool admin = false,
  bool coach = false,
}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin, isCoach: coach),
  createdAtUtc: DateTime.utc(2024),
);

/// Records the calls the actions send; [refusal], when set, is thrown by
/// each instead.
class _RecordingEvents extends ClEventsMasterNotifier {
  _RecordingEvents(this.event);

  final Event event;
  final List<String> calls = [];
  Exception? refusal;

  @override
  Future<Map<int, Event>> build() async => {event.id: event};

  Event record(String call) {
    calls.add(call);
    final refused = refusal;
    if (refused != null) throw refused;
    return event;
  }

  @override
  Future<Event> cancelSeries(
    int eventId, {
    required String reason,
    required DateTime effectiveDateTimeUtc,
  }) async => record(
    'cancel($eventId, $reason, ${effectiveDateTimeUtc.toIso8601String()})',
  );

  @override
  Future<Event> undoCancelSeries(int eventId) async =>
      record('undoCancel($eventId)');

  @override
  Future<Event> drop(
    int eventId, {
    required int version,
    required String reason,
  }) async => record('drop($eventId, v$version, $reason)');

  @override
  Future<Event> reinstate(int eventId, {required int version}) async =>
      record('reinstate($eventId, v$version)');
}

Future<_RecordingEvents> _pump(
  WidgetTester tester,
  Event event, {
  UserPrivate? user,
  OccurrenceStatus oneOffStatus = OccurrenceStatus.scheduled,
}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final events = _RecordingEvents(event);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        clSingleOccurrenceProvider.overrideWith(
          (ref, key) async =>
              _occurrence(key.occurrenceTimeUtc, status: oneOffStatus),
        ),
        // The camp's three sessions, a session of another event, and one
        // that is already over.
        clOccurrencesProvider.overrideWith(
          (ref, key) async => [
            _occurrence(_day(11)),
            _occurrence(_day(10)),
            _occurrence(_day(12)),
            _occurrence(_day(9), eventId: 2),
            _occurrence(_day(-1), status: OccurrenceStatus.completed),
          ],
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventManagementSection(
              event: event,
              currentUser: user ?? _person('an_admin', admin: true),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

Finder _button(String label) => find.widgetWithText(ShadButton, label);

Future<void> _press(WidgetTester tester, String label) async {
  await tester.tap(_button(label).last);
  await tester.pumpAndSettle();
}

Future<void> _typeReason(WidgetTester tester, String reason) async {
  await tester.enterText(find.byType(EditableText), reason);
  await tester.pump();
}

void _expectOnly(String? label) {
  for (final each in [
    EventCancellationMessages.cancelCamp,
    EventCancellationMessages.undoCancel,
    EventCancellationMessages.callOff,
    EventCancellationMessages.reinstate,
  ]) {
    expect(
      _button(each),
      each == label ? findsOneWidget : findsNothing,
      reason: each,
    );
  }
}

void main() {
  group('Issue 40: each action appears for its event type and state', () {
    testWidgets('Issue 40: a running camp offers Cancel camp', (tester) async {
      await _pump(tester, _event(EventType.camp));
      _expectOnly(EventCancellationMessages.cancelCamp);
    });

    testWidgets('Issue 40: a cancelled camp offers Undo cancel', (
      tester,
    ) async {
      await _pump(tester, _event(EventType.camp, cancelled: true));
      _expectOnly(EventCancellationMessages.undoCancel);
    });

    testWidgets('Issue 40: a one-off that is on offers Call off', (
      tester,
    ) async {
      await _pump(tester, _event(EventType.oneOff));
      _expectOnly(EventCancellationMessages.callOff);
    });

    testWidgets('Issue 40: a called-off one-off offers Reinstate', (
      tester,
    ) async {
      await _pump(
        tester,
        _event(EventType.oneOff),
        oneOffStatus: OccurrenceStatus.cancelled,
      );
      _expectOnly(EventCancellationMessages.reinstate);
    });

    testWidgets('Issue 40: a programme shows none of the four', (tester) async {
      await _pump(tester, _event(EventType.programme));
      _expectOnly(null);
      await _pump(tester, _event(EventType.programme, cancelled: true));
      _expectOnly(null);
    });

    testWidgets('Issue 40: the organizer gets them, as an admin does', (
      tester,
    ) async {
      await _pump(
        tester,
        _event(EventType.camp),
        user: _person(_organizer, coach: true),
      );
      _expectOnly(EventCancellationMessages.cancelCamp);
    });

    testWidgets('Issue 40: a coach who is not the organizer gets none', (
      tester,
    ) async {
      await _pump(
        tester,
        _event(EventType.camp),
        user: _person('other_coach', coach: true),
      );
      _expectOnly(null);
    });

    testWidgets('Issue 40: an archived camp shows none of the four', (
      tester,
    ) async {
      await _pump(tester, _event(EventType.camp, archived: true));
      _expectOnly(null);
    });
  });

  group('Issue 40: Cancel camp and Undo cancel', () {
    testWidgets(
      'Issue 40: it cancels from the next session, with the reason',
      (tester) async {
        final events = await _pump(tester, _event(EventType.camp));

        await _press(tester, EventCancellationMessages.cancelCamp);
        expect(
          find.text(EventCancellationMessages.cancelCampDescription),
          findsOneWidget,
        );
        expect(
          EventCancellationMessages.cancelCampDescription,
          contains('Enrolled members are notified'),
        );
        await _typeReason(tester, _reason);
        await _press(tester, EventCancellationMessages.cancelCamp);

        expect(events.calls, [
          'cancel(1, $_reason, ${_day(10).toIso8601String()})',
        ]);
        expect(
          find.text(EventCancellationMessages.campCancelled),
          findsOneWidget,
        );
      },
    );

    testWidgets('Issue 40: without a reason nothing is sent', (tester) async {
      final events = await _pump(tester, _event(EventType.camp));
      await _press(tester, EventCancellationMessages.cancelCamp);

      await _press(tester, EventCancellationMessages.cancelCamp);

      expect(events.calls, isEmpty);
      expect(
        find.text(EventCancellationFormValidators.reasonRequired),
        findsOneWidget,
      );
    });

    testWidgets('Issue 40: a refusal reads as a fixed message', (tester) async {
      final events = await _pump(tester, _event(EventType.camp));
      events.refusal = const ServerException(
        statusCode: 400,
        code: SdkErrorCode.cancellationLeadTimeViolated,
        message: 'raw server text',
      );
      await _press(tester, EventCancellationMessages.cancelCamp);
      await _typeReason(tester, _reason);

      await _press(tester, EventCancellationMessages.cancelCamp);

      expect(find.text(EventCancellationMessages.tooClose), findsOneWidget);
      expect(find.textContaining('raw server text'), findsNothing);
      expect(find.byType(ShadDialog), findsOneWidget);
    });

    testWidgets('Issue 40: Undo cancel asks, then undoes the cancellation', (
      tester,
    ) async {
      final event = _event(EventType.camp, cancelled: true);
      final events = await _pump(tester, event);

      await _press(tester, EventCancellationMessages.undoCancel);
      expect(
        find.text(EventCancellationMessages.undoCancelConfirm(event.title)),
        findsOneWidget,
      );
      expect(events.calls, isEmpty);
      await _press(tester, EventCancellationMessages.undoCancel);

      expect(events.calls, ['undoCancel(1)']);
      expect(
        find.text(EventCancellationMessages.cancelUndone),
        findsOneWidget,
      );
    });
  });

  group('Issue 40: Call off and Reinstate', () {
    testWidgets(
      'Issue 40: Call off sends the reason and the occurrence version',
      (tester) async {
        final events = await _pump(tester, _event(EventType.oneOff));

        await _press(tester, EventCancellationMessages.callOff);
        expect(
          find.text(EventCancellationMessages.callOffDescription),
          findsOneWidget,
        );
        expect(
          EventCancellationMessages.callOffDescription,
          contains('Enrolled members are notified'),
        );
        expect(find.text('Cancel from *'), findsNothing);
        await _typeReason(tester, _reason);
        await _press(tester, EventCancellationMessages.callOff);

        expect(events.calls, ['drop(1, v$_occurrenceVersion, $_reason)']);
        expect(find.text(EventCancellationMessages.calledOff), findsOneWidget);
      },
    );

    testWidgets('Issue 40: Reinstate asks, then sends the occurrence version', (
      tester,
    ) async {
      final events = await _pump(
        tester,
        _event(EventType.oneOff),
        oneOffStatus: OccurrenceStatus.cancelled,
      );

      await _press(tester, EventCancellationMessages.reinstate);
      expect(events.calls, isEmpty);
      await _press(tester, EventCancellationMessages.reinstate);

      expect(events.calls, ['reinstate(1, v$_occurrenceVersion)']);
      expect(find.text(EventCancellationMessages.reinstated), findsOneWidget);
    });

    testWidgets('Issue 40: a refused reinstate reads as a fixed message', (
      tester,
    ) async {
      final events = await _pump(
        tester,
        _event(EventType.oneOff),
        oneOffStatus: OccurrenceStatus.cancelled,
      );
      events.refusal = const ServerException(
        statusCode: 422,
        code: SdkErrorCode.invalidState,
        message: 'raw server text',
      );

      await _press(tester, EventCancellationMessages.reinstate);
      await _press(tester, EventCancellationMessages.reinstate);

      expect(
        find.text(EventCancellationMessages.cannotReinstate),
        findsOneWidget,
      );
      expect(find.textContaining('raw server text'), findsNothing);
    });
  });

  group('Issue 40: the sessions a camp can be cancelled from', () {
    test('Issue 40: this camp, upcoming, beyond the lead, earliest first', () {
      final now = DateTime.utc(2030, 6, 15, 6);
      final sessions = buildEventCancellationSessions(
        [
          _occurrence(now.add(const Duration(days: 2))),
          _occurrence(now.add(const Duration(days: 1))),
          _occurrence(now.add(const Duration(minutes: 30))),
          _occurrence(now.subtract(const Duration(days: 1))),
          _occurrence(now.add(const Duration(days: 1)), eventId: 2),
          _occurrence(
            now.add(const Duration(days: 3)),
            status: OccurrenceStatus.completed,
          ),
        ],
        eventId: 1,
        now: now,
      );

      expect(sessions.map((s) => s.start), [
        now.add(const Duration(days: 1)),
        now.add(const Duration(days: 2)),
      ]);
    });
  });
}
