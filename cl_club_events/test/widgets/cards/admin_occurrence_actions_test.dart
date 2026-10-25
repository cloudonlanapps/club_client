import 'package:cl_club_events/src/models/event_cancellation_messages.dart';
import 'package:cl_club_events/src/widgets/cards/actions/admin_occurrence_actions.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_cancellation_dialog.dart';
import 'package:cl_club_forms/src/widgets/event_cancellation/event_cancellation_form_validators.dart'
    show EventCancellationFormValidators;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem;

const _eventId = 101;
const _organizer = 'the_organizer';
const _assignedCoach = 'assigned_coach';

DateTime _futureUtc(Duration offset) => DateTime.now().toUtc().add(offset);

Occurrence _occurrence(OccurrenceStatus status, {int version = 1}) {
  // Original slot in 3 days; for a rescheduled day the effective start differs
  // from the original, but both stay comfortably inside the management window.
  final original = _futureUtc(const Duration(days: 3));
  final actualStart = status == OccurrenceStatus.rescheduled
      ? _futureUtc(const Duration(days: 5))
      : original;
  return Occurrence(
    eventId: _eventId,
    originalStartTimeUtc: original,
    actualStartTimeUtc: actualStart,
    actualEndTimeUtc: actualStart.add(const Duration(hours: 1)),
    status: status,
    venueId: 1,
    version: version,
  );
}

/// A cancelled or live occurrence starting [fromNow] from now (negative for
/// one already started).
Occurrence _occurrenceAt(Duration fromNow, OccurrenceStatus status) {
  final start = DateTime.now().toUtc().add(fromNow);
  return Occurrence(
    eventId: _eventId,
    originalStartTimeUtc: start,
    actualStartTimeUtc: start,
    actualEndTimeUtc: start.add(const Duration(hours: 1)),
    status: status,
    venueId: 1,
  );
}

/// Inside the attendance window: 30 minutes before the start until 15 days
/// after the end.
const _inAttendanceWindow = Duration(minutes: 10);

/// Past the attendance edit window, open only to a super-admin.
const _pastEditWindow = Duration(days: -20);

Event _camp({DateTime? untilTimeUtc, EventType type = EventType.camp}) => Event(
  id: _eventId,
  title: 'current camp',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: _futureUtc(const Duration(days: 3)),
  endTimeUtc: _futureUtc(const Duration(days: 3, hours: 1)),
  organizerName: _organizer,
  coachNames: const [_assignedCoach],
  untilTimeUtc: untilTimeUtc,
  createdAtUtc: DateTime.now().toUtc(),
  updatedAtUtc: DateTime.now().toUtc(),
);

class _StaticCampNotifier extends ClEventsMasterNotifier {
  _StaticCampNotifier(this._events);
  final Map<int, Event> _events;

  /// The `version` each undo-cancel sent.
  final List<int> undoVersions = [];

  /// When set, undo-cancel throws this.
  Exception? undoError;

  /// The occurrence-level and one-off calls made, in order.
  final List<String> calls = [];

  @override
  Future<Map<int, Event>> build() async => _events;

  @override
  Future<void> cancelOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
    required String reason,
  }) async {
    calls.add('cancelOccurrence(v$version, $reason)');
  }

  @override
  Future<Event> cancelSeries(
    int eventId, {
    required String reason,
    required DateTime effectiveDateTimeUtc,
    int? version,
  }) async {
    calls.add(
      'cancelSeries(${effectiveDateTimeUtc.toIso8601String()}, $reason)',
    );
    return _events[eventId]!;
  }

  @override
  Future<Event> drop(
    int eventId, {
    required int version,
    required String reason,
  }) async {
    calls.add('drop(v$version, $reason)');
    return _events[eventId]!;
  }

  @override
  Future<Event> reinstate(
    int eventId, {
    required int version,
    bool acceptConflicts = false,
  }) async {
    calls.add('reinstate(v$version)');
    return _events[eventId]!;
  }

  @override
  Future<void> undoCancelOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
  }) async {
    undoVersions.add(version);
    calls.add('undoCancelOccurrence(v$version)');
    if (undoError != null) throw undoError!;
  }
}

class _StaticAuthNotifier extends AuthNotifier {
  _StaticAuthNotifier(this._user);
  final UserPrivate _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

UserPrivate _adminUser() => UserPrivate(
  username: 'admin_user',
  displayName: 'Admin User',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.now().toUtc(),
);

UserPrivate _superAdmin() => UserPrivate(
  username: 'super_user',
  displayName: 'Super User',
  status: UserStatus.active,
  isSuperAdmin: true,
  roles: const UserRoles(),
  createdAtUtc: DateTime.now().toUtc(),
);

UserPrivate _coach(String username) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isCoach: true),
  createdAtUtc: DateTime.now().toUtc(),
);

/// Pumps [AdminOccurrenceActions] and returns the resolved actions.
Future<List<ActionItem>> _resolveActions(
  WidgetTester tester,
  Occurrence occurrence, {
  _StaticCampNotifier? camp,
  UserPrivate? user,
}) async {
  late List<ActionItem> captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(
          () => camp ?? _StaticCampNotifier({_eventId: _camp()}),
        ),
        authStateProvider.overrideWith(
          () => _StaticAuthNotifier(user ?? _adminUser()),
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: AdminOccurrenceActions(
            occurrence: occurrence,
            onMarkAttendance: (_, _) {},
            builder: (context, actions) {
              captured = actions;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return captured;
}

/// Pumps [AdminOccurrenceActions] and returns the resolved action labels.
Future<List<String>> _resolveLabels(
  WidgetTester tester,
  Occurrence occurrence, {
  UserPrivate? user,
  Event? event,
}) async => (await _resolveActions(
  tester,
  occurrence,
  user: user,
  camp: event == null ? null : _StaticCampNotifier({_eventId: event}),
)).map((a) => a.label).toList();

void main() {
  testWidgets(
    'Issue 750: a rescheduled occurrence offers the same actions as a '
    'scheduled one',
    (tester) async {
      final scheduled = await _resolveLabels(
        tester,
        _occurrence(OccurrenceStatus.scheduled),
      );
      final rescheduled = await _resolveLabels(
        tester,
        _occurrence(OccurrenceStatus.rescheduled),
      );

      expect(scheduled, contains('Reschedule'));
      expect(rescheduled, scheduled);
    },
  );

  testWidgets('Issue 750: a completed occurrence offers no actions', (
    tester,
  ) async {
    final labels = await _resolveLabels(
      tester,
      _occurrence(OccurrenceStatus.completed),
    );
    expect(labels, isEmpty);
  });

  testWidgets('Issue 69: Undo Cancel sends the occurrence version', (
    tester,
  ) async {
    final camp = _StaticCampNotifier({_eventId: _camp()});
    final actions = await _resolveActions(
      tester,
      _occurrence(OccurrenceStatus.cancelled, version: 3),
      camp: camp,
    );

    actions.singleWhere((a) => a.label == 'Undo Cancel').onPressed!();
    await tester.pump();

    expect(camp.undoVersions, [3]);
  });

  testWidgets('Issue 69: a stale Undo Cancel says who changed the session', (
    tester,
  ) async {
    final camp = _StaticCampNotifier({_eventId: _camp()})
      ..undoError = StaleVersionException(
        message: 'raw server text',
        version: 4,
        updatedAtUtc: DateTime.utc(2026, 9, 1, 10),
        updatedBy: 'coach_a',
      );
    final actions = await _resolveActions(
      tester,
      _occurrence(OccurrenceStatus.cancelled),
      camp: camp,
    );

    actions.singleWhere((a) => a.label == 'Undo Cancel').onPressed!();
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('This session was changed by coach_a'),
      findsOneWidget,
    );
    expect(find.text('raw server text'), findsNothing);
  });

  group('Issue 146: occurrence management is organizer-or-admin', () {
    const managed = [
      'Reschedule',
      'Cancel this occurrence',
      'Cancel entire series',
      'Manage requests',
    ];

    testWidgets('Issue 146: a coach assigned to the event is offered none', (
      tester,
    ) async {
      final user = _coach(_assignedCoach);
      expect(
        await _resolveLabels(
          tester,
          _occurrence(OccurrenceStatus.scheduled),
          user: user,
        ),
        isEmpty,
      );
      expect(
        await _resolveLabels(
          tester,
          _occurrence(OccurrenceStatus.cancelled),
          user: user,
        ),
        isEmpty,
      );
    });

    testWidgets('Issue 146: a coach not on the event is offered none', (
      tester,
    ) async {
      final user = _coach('other_coach');
      expect(
        await _resolveLabels(
          tester,
          _occurrence(OccurrenceStatus.scheduled),
          user: user,
        ),
        isEmpty,
      );
      expect(
        await _resolveLabels(
          tester,
          _occurrence(OccurrenceStatus.cancelled),
          user: user,
        ),
        isEmpty,
      );
    });

    testWidgets('Issue 146: the organizer is offered every action', (
      tester,
    ) async {
      final user = _coach(_organizer);
      expect(
        await _resolveLabels(
          tester,
          _occurrence(OccurrenceStatus.scheduled),
          user: user,
        ),
        managed,
      );
      expect(
        await _resolveLabels(
          tester,
          _occurrence(OccurrenceStatus.cancelled),
          user: user,
        ),
        ['Undo Cancel'],
      );
    });

    testWidgets('Issue 146: an admin not organizing it is offered every '
        'action', (tester) async {
      expect(
        await _resolveLabels(tester, _occurrence(OccurrenceStatus.scheduled)),
        managed,
      );
      expect(
        await _resolveLabels(tester, _occurrence(OccurrenceStatus.cancelled)),
        ['Undo Cancel'],
      );
    });
  });

  group('Issue 177: a cancelled occurrence in the attendance window', () {
    testWidgets('Issue 177: offers an admin nothing', (tester) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrenceAt(_inAttendanceWindow, OccurrenceStatus.cancelled),
        ),
        isEmpty,
      );
    });

    testWidgets('Issue 177: offers the organizer nothing', (tester) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrenceAt(_inAttendanceWindow, OccurrenceStatus.cancelled),
          user: _coach(_organizer),
        ),
        isEmpty,
      );
    });

    testWidgets('Issue 177: offers a super-admin Undo Cancel only', (
      tester,
    ) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrenceAt(_inAttendanceWindow, OccurrenceStatus.cancelled),
          user: _superAdmin(),
        ),
        ['Undo Cancel'],
      );
    });

    testWidgets('Issue 177: offers a super-admin Undo Cancel after the edit '
        'window too', (tester) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrenceAt(_pastEditWindow, OccurrenceStatus.cancelled),
          user: _superAdmin(),
        ),
        ['Undo Cancel'],
      );
    });

    testWidgets('Issue 177: a live occurrence there still offers Attendance', (
      tester,
    ) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrenceAt(_inAttendanceWindow, OccurrenceStatus.scheduled),
        ),
        ['Attendance'],
      );
    });
  });

  group('Issue 177: a slot cut off by a series cancellation', () {
    testWidgets('Issue 177: offers no Undo Cancel before the attendance '
        'window', (tester) async {
      final occurrence = _occurrence(OccurrenceStatus.cancelled);
      expect(
        await _resolveLabels(
          tester,
          occurrence,
          event: _camp(untilTimeUtc: occurrence.originalStartTimeUtc),
        ),
        isEmpty,
      );
    });

    testWidgets('Issue 177: offers a super-admin no Undo Cancel in the '
        'attendance window', (tester) async {
      final occurrence = _occurrenceAt(
        _inAttendanceWindow,
        OccurrenceStatus.cancelled,
      );
      expect(
        await _resolveLabels(
          tester,
          occurrence,
          user: _superAdmin(),
          event: _camp(
            untilTimeUtc: occurrence.originalStartTimeUtc.subtract(
              const Duration(days: 1),
            ),
          ),
        ),
        isEmpty,
      );
    });

    testWidgets('Issue 177: a slot before the cutoff still offers Undo '
        'Cancel', (tester) async {
      final occurrence = _occurrence(OccurrenceStatus.cancelled);
      expect(
        await _resolveLabels(
          tester,
          occurrence,
          event: _camp(
            untilTimeUtc: occurrence.originalStartTimeUtc.add(
              const Duration(days: 7),
            ),
          ),
        ),
        ['Undo Cancel'],
      );
    });
  });

  group('Issue 178: the actions follow the event type', () {
    testWidgets('Issue 178: a programme ends from here instead of cancelling '
        'its series', (tester) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrence(OccurrenceStatus.scheduled),
          event: _camp(type: EventType.programme),
        ),
        [
          'Reschedule',
          'Cancel this occurrence',
          'End programme from here',
          'Manage requests',
        ],
      );
    });

    testWidgets('Issue 178: a one-off is called off, with no series and no '
        'reschedule', (tester) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrence(OccurrenceStatus.scheduled),
          event: _camp(type: EventType.oneOff),
        ),
        ['Call off', 'Manage requests'],
      );
    });

    testWidgets('Issue 178: a camp keeps every action', (tester) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrence(OccurrenceStatus.scheduled),
          event: _camp(),
        ),
        [
          'Reschedule',
          'Cancel this occurrence',
          'Cancel entire series',
          'Manage requests',
        ],
      );
    });
  });

  group('Issue 183: a one-off is called off and reinstated as on its event '
      'page', () {
    Event oneOff() => _camp(type: EventType.oneOff);

    testWidgets('Issue 183: a called-off one-off offers Reinstate, not Undo '
        'Cancel', (tester) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrence(OccurrenceStatus.cancelled),
          event: oneOff(),
        ),
        ['Reinstate'],
      );
    });

    testWidgets('Issue 183: Reinstate is offered to an admin until the '
        'start, inside the last 30 minutes too', (tester) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrenceAt(_inAttendanceWindow, OccurrenceStatus.cancelled),
          event: oneOff(),
        ),
        ['Reinstate'],
      );
    });

    testWidgets('Issue 183: a called-off one-off that has started offers a '
        'super-admin nothing', (tester) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrenceAt(const Duration(hours: -1), OccurrenceStatus.cancelled),
          user: _superAdmin(),
          event: oneOff(),
        ),
        isEmpty,
      );
    });

    testWidgets('Issue 183: a coach on the event is not offered Reinstate', (
      tester,
    ) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrence(OccurrenceStatus.cancelled),
          user: _coach(_assignedCoach),
          event: oneOff(),
        ),
        isEmpty,
      );
    });

    testWidgets('Issue 183: Reinstate asks the event page question and '
        'sends reinstate with the occurrence version', (tester) async {
      final events = _StaticCampNotifier({_eventId: oneOff()});
      final actions = await _resolveActions(
        tester,
        _occurrence(OccurrenceStatus.cancelled, version: 3),
        camp: events,
      );

      actions.singleWhere((a) => a.label == 'Reinstate').onPressed!();
      await tester.pumpAndSettle();
      expect(
        find.text(EventCancellationMessages.reinstateConfirm('current camp')),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(ShadButton, 'Reinstate'));
      await tester.pumpAndSettle();

      expect(events.calls, ['reinstate(v3)']);
      expect(find.text(EventCancellationMessages.reinstated), findsOneWidget);
    });

    testWidgets('Issue 183: Back at the Reinstate question sends nothing', (
      tester,
    ) async {
      final events = _StaticCampNotifier({_eventId: oneOff()});
      final actions = await _resolveActions(
        tester,
        _occurrence(OccurrenceStatus.cancelled),
        camp: events,
      );

      actions.singleWhere((a) => a.label == 'Reinstate').onPressed!();
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ShadButton, EventCancellationMessages.back),
      );
      await tester.pumpAndSettle();

      expect(events.calls, isEmpty);
    });

    testWidgets('Issue 183: Call off opens the event page Call off dialog '
        'and sends drop with the occurrence version', (tester) async {
      final events = _StaticCampNotifier({_eventId: oneOff()});
      final actions = await _resolveActions(
        tester,
        _occurrence(OccurrenceStatus.scheduled, version: 5),
        camp: events,
      );

      actions.singleWhere((a) => a.label == 'Call off').onPressed!();
      await tester.pumpAndSettle();
      expect(find.byType(EventCancellationDialog), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(EventCancellationDialog),
          matching: find.byType(EditableText),
        ),
        'Rink closed',
      );
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(EventCancellationDialog),
          matching: find.widgetWithText(ShadButton, 'Call off'),
        ),
      );
      await tester.pumpAndSettle();

      expect(events.calls, ['drop(v5, Rink closed)']);
      expect(find.byType(EventCancellationDialog), findsNothing);
      expect(find.text(EventCancellationMessages.calledOff), findsOneWidget);
    });
  });

  group('Issue 187: the card calls a one-off off by the same rule as the '
      'event page', () {
    Event oneOff() => _camp(type: EventType.oneOff);

    testWidgets('Issue 187: an admin is offered no Call off inside the last '
        '30 minutes', (tester) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrenceAt(_inAttendanceWindow, OccurrenceStatus.scheduled),
          event: oneOff(),
        ),
        ['Attendance'],
      );
    });

    testWidgets('Issue 187: a super-admin is offered Call off on a one-off '
        'that has started', (tester) async {
      expect(
        await _resolveLabels(
          tester,
          _occurrenceAt(const Duration(hours: -1), OccurrenceStatus.scheduled),
          user: _superAdmin(),
          event: oneOff(),
        ),
        ['Attendance', 'Call off'],
      );
    });
  });

  group(
    'Issue 312: a super-admin manages a session whose register is open',
    () {
      const lateActions = [
        'Attendance',
        'Reschedule',
        'Cancel this occurrence',
        'Manage requests',
      ];

      for (final type in [EventType.camp, EventType.programme]) {
        for (final (moment, fromNow) in [
          ('inside the last 30 minutes', _inAttendanceWindow),
          ('once it has started', const Duration(hours: -1)),
          ('past the attendance edit window', _pastEditWindow),
        ]) {
          testWidgets(
            'Issue 312: a ${type.name} offers Attendance first, then '
            'Reschedule, Cancel this occurrence and Manage requests, $moment',
            (
              tester,
            ) async {
              expect(
                await _resolveLabels(
                  tester,
                  _occurrenceAt(fromNow, OccurrenceStatus.scheduled),
                  user: _superAdmin(),
                  event: _camp(type: type),
                ),
                lateActions,
              );
            },
          );
        }
      }

      testWidgets('Issue 312: an admin and the organizer still see Attendance '
          'alone', (tester) async {
        for (final user in [_adminUser(), _coach(_organizer)]) {
          expect(
            await _resolveLabels(
              tester,
              _occurrenceAt(
                const Duration(hours: -1),
                OccurrenceStatus.scheduled,
              ),
              user: user,
              event: _camp(type: EventType.programme),
            ),
            ['Attendance'],
          );
        }
      });

      /// Presses Cancel this occurrence on a programme session that started an
      /// hour ago, as a super-admin, and returns the master.
      Future<_StaticCampNotifier> pressCancel(WidgetTester tester) async {
        final events = _StaticCampNotifier({
          _eventId: _camp(type: EventType.programme),
        });
        final actions = await _resolveActions(
          tester,
          _occurrenceAt(const Duration(hours: -1), OccurrenceStatus.scheduled),
          camp: events,
          user: _superAdmin(),
        );
        actions
            .singleWhere((a) => a.label == 'Cancel this occurrence')
            .onPressed!();
        await tester.pumpAndSettle();
        return events;
      }

      testWidgets('Issue 312: Cancel this occurrence first asks to confirm '
          'that the marks go and the credit is refunded; Back sends nothing', (
        tester,
      ) async {
        final events = await pressCancel(tester);

        expect(find.byType(EventCancellationDialog), findsNothing);
        expect(
          find.text(EventCancellationMessages.cancelOpenRegisterConfirm),
          findsOneWidget,
        );
        expect(
          EventCancellationMessages.cancelOpenRegisterConfirm,
          allOf(contains('attendance marks'), contains('refunds')),
        );

        await tester.tap(
          find.widgetWithText(ShadButton, EventCancellationMessages.back),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EventCancellationDialog), findsNothing);
        expect(events.calls, isEmpty);
      });

      testWidgets('Issue 312: once confirmed, the cancellation dialog says '
          'members are not notified and cancels the session', (tester) async {
        final events = await pressCancel(tester);

        await tester.tap(
          find.widgetWithText(
            ShadButton,
            EventCancellationMessages.cancelOpenRegisterContinue,
          ),
        );
        await tester.pumpAndSettle();

        final dialog = find.byType(EventCancellationDialog);
        expect(dialog, findsOneWidget);
        expect(
          find.descendant(
            of: dialog,
            matching: find.text(
              EventCancellationMessages.cancelOpenRegisterDescription,
            ),
          ),
          findsOneWidget,
        );
        expect(
          EventCancellationMessages.cancelOpenRegisterDescription,
          contains('not notified'),
        );

        await tester.enterText(
          find.descendant(of: dialog, matching: find.byType(EditableText)),
          'Wrong day',
        );
        await tester.pump();
        await tester.tap(
          find.descendant(
            of: dialog,
            matching: find.widgetWithText(
              ShadButton,
              EventCancellationMessages.cancelOccurrence,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(events.calls, ['cancelOccurrence(v1, Wrong day)']);
      });
    },
  );

  group('Issue 189: a series action on a rescheduled day is offered by the '
      'start it sends', () {
    /// A day whose slot is 10 minutes away, moved to tomorrow.
    Occurrence movedDay() {
      final slot = DateTime.now().toUtc().add(const Duration(minutes: 10));
      final moved = slot.add(const Duration(days: 1));
      return Occurrence(
        eventId: _eventId,
        originalStartTimeUtc: slot,
        actualStartTimeUtc: moved,
        actualEndTimeUtc: moved.add(const Duration(hours: 1)),
        status: OccurrenceStatus.rescheduled,
        venueId: 1,
      );
    }

    testWidgets('Issue 189: an admin is offered no Cancel entire series when '
        'the original start is within 30 minutes', (tester) async {
      expect(await _resolveLabels(tester, movedDay()), [
        'Reschedule',
        'Cancel this occurrence',
        'Manage requests',
      ]);
    });

    testWidgets('Issue 189: a super-admin is still offered Cancel entire '
        'series there', (tester) async {
      expect(
        await _resolveLabels(tester, movedDay(), user: _superAdmin()),
        contains('Cancel entire series'),
      );
    });

    testWidgets('Issue 189: End programme from here is not offered when the '
        'original start is within 30 minutes, to a super-admin either', (
      tester,
    ) async {
      final programme = _camp(type: EventType.programme);
      expect(
        await _resolveLabels(tester, movedDay(), event: programme),
        ['Reschedule', 'Cancel this occurrence', 'Manage requests'],
      );
      expect(
        await _resolveLabels(
          tester,
          movedDay(),
          event: programme,
          user: _superAdmin(),
        ),
        isNot(contains('End programme from here')),
      );
    });
  });

  group('Issue 213: the card cancels through the cancellation dialog, worded '
      'for the action that opened it', () {
    /// Presses [label] on [occurrence] of [event] and returns the master.
    Future<_StaticCampNotifier> open(
      WidgetTester tester,
      String label, {
      Event? event,
      Occurrence? occurrence,
    }) async {
      final events = _StaticCampNotifier({_eventId: event ?? _camp()});
      final actions = await _resolveActions(
        tester,
        occurrence ?? _occurrence(OccurrenceStatus.scheduled, version: 4),
        camp: events,
      );
      actions.singleWhere((a) => a.label == label).onPressed!();
      await tester.pumpAndSettle();
      expect(find.byType(EventCancellationDialog), findsOneWidget);
      return events;
    }

    Finder inDialog(Finder finder) => find.descendant(
      of: find.byType(EventCancellationDialog),
      matching: finder,
    );

    Future<void> typeReason(WidgetTester tester, String reason) async {
      await tester.enterText(inDialog(find.byType(EditableText)), reason);
      await tester.pump();
    }

    Future<void> confirm(WidgetTester tester, String label) async {
      await tester.tap(inDialog(find.widgetWithText(ShadButton, label)));
      await tester.pumpAndSettle();
    }

    void expectWording({
      required String title,
      required String description,
      required String confirmLabel,
    }) {
      expect(inDialog(find.text(title)), findsWidgets);
      expect(inDialog(find.text(description)), findsOneWidget);
      expect(
        inDialog(find.widgetWithText(ShadButton, confirmLabel)),
        findsOneWidget,
      );
      expect(find.textContaining('cannot be undone'), findsNothing);
    }

    testWidgets('Issue 213: Cancel this occurrence is worded for one session '
        'and says Undo Cancel restores it', (tester) async {
      await open(tester, 'Cancel this occurrence');

      expectWording(
        title: EventCancellationMessages.cancelOccurrenceTitle,
        description: EventCancellationMessages.cancelOccurrenceDescription,
        confirmLabel: EventCancellationMessages.cancelOccurrence,
      );
      expect(
        EventCancellationMessages.cancelOccurrenceDescription,
        contains('Undo Cancel'),
      );
    });

    testWidgets('Issue 213: a blank reason keeps Cancel this occurrence open '
        'on the required message and sends nothing', (tester) async {
      final events = await open(tester, 'Cancel this occurrence');

      await typeReason(tester, '   ');
      await confirm(tester, EventCancellationMessages.cancelOccurrence);

      expect(find.byType(EventCancellationDialog), findsOneWidget);
      expect(
        find.text(EventCancellationFormValidators.reasonRequired),
        findsOneWidget,
      );
      expect(events.calls, isEmpty);
    });

    testWidgets('Issue 213: Cancel this occurrence sends the session cancel '
        'with the reason and the occurrence version', (tester) async {
      final events = await open(tester, 'Cancel this occurrence');

      await typeReason(tester, 'Coach unavailable');
      await confirm(tester, EventCancellationMessages.cancelOccurrence);

      expect(events.calls, ['cancelOccurrence(v4, Coach unavailable)']);
      expect(find.byType(EventCancellationDialog), findsNothing);
      expect(
        find.text(EventCancellationMessages.occurrenceCancelled),
        findsOneWidget,
      );
    });

    testWidgets('Issue 213: Cancel entire series is worded for the series '
        'and says Undo cancel takes it back', (tester) async {
      await open(tester, 'Cancel entire series');

      expectWording(
        title: EventCancellationMessages.cancelSeriesTitle,
        description: EventCancellationMessages.cancelSeriesDescription,
        confirmLabel: EventCancellationMessages.cancelSeries,
      );
      expect(
        EventCancellationMessages.cancelSeriesDescription,
        contains('Undo cancel'),
      );
    });

    testWidgets('Issue 213: a blank reason keeps Cancel entire series open '
        'and sends nothing; a reason cancels from this session', (
      tester,
    ) async {
      final occurrence = _occurrence(OccurrenceStatus.scheduled);
      final events = await open(
        tester,
        'Cancel entire series',
        occurrence: occurrence,
      );

      await confirm(tester, EventCancellationMessages.cancelSeries);
      expect(find.byType(EventCancellationDialog), findsOneWidget);
      expect(
        find.text(EventCancellationFormValidators.reasonRequired),
        findsOneWidget,
      );
      expect(events.calls, isEmpty);

      await typeReason(tester, 'Rink closed');
      await confirm(tester, EventCancellationMessages.cancelSeries);

      final from = occurrence.originalStartTimeUtc.toIso8601String();
      expect(events.calls, ['cancelSeries($from, Rink closed)']);
      expect(
        find.text(EventCancellationMessages.campCancelled),
        findsOneWidget,
      );
    });

    testWidgets('Issue 213: a one-off Call off is worded for calling off '
        'and says it can be reinstated', (tester) async {
      final events = await open(
        tester,
        'Call off',
        event: _camp(type: EventType.oneOff),
      );

      expectWording(
        title: EventCancellationMessages.callOff,
        description: EventCancellationMessages.callOffDescription,
        confirmLabel: EventCancellationMessages.callOff,
      );
      expect(
        EventCancellationMessages.callOffDescription,
        contains('reinstate'),
      );

      await confirm(tester, EventCancellationMessages.callOff);
      expect(find.byType(EventCancellationDialog), findsOneWidget);
      expect(events.calls, isEmpty);
    });
  });
}
