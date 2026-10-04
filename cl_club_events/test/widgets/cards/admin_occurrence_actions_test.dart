import 'package:cl_club_events/src/widgets/cards/actions/admin_occurrence_actions.dart';
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

Event _camp() => Event(
  id: _eventId,
  title: 'current camp',
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: _futureUtc(const Duration(days: 3)),
  endTimeUtc: _futureUtc(const Duration(days: 3, hours: 1)),
  organizerName: _organizer,
  coachNames: const [_assignedCoach],
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

  @override
  Future<Map<int, Event>> build() async => _events;

  @override
  Future<void> undoCancelOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
  }) async {
    undoVersions.add(version);
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
}) async => (await _resolveActions(
  tester,
  occurrence,
  user: user,
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
}
