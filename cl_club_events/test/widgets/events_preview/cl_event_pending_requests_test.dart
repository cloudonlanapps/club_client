import 'package:cl_club_events/src/widgets/events_preview/cl_event_pending_requests.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEnrollmentsMasterNotifier,
        ClEventsMasterNotifier,
        ClUsersMasterNotifier,
        clEnrollmentsMasterProvider,
        clEventsMasterProvider,
        clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _eventId = 7777;

UserPrivate _user({bool isCoachOrAdmin = true}) => UserPrivate(
  username: isCoachOrAdmin ? 'admin_user' : 'member_user',
  displayName: 'Test User',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(
    isAdmin: isCoachOrAdmin,
  ),
  createdAtUtc: DateTime.utc(2026, 5, 14),
);

UserInfo _userInfo({
  required String username,
  required String firstName,
  required String lastName,
}) => UserInfo(
  publicId: username,
  username: username,
  displayName: '$firstName $lastName',
  firstName: firstName,
  lastName: lastName,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
);

Event _event() {
  // Anchor to wall-clock now so the event always stays in the future and
  // passes the `canEnrollOnEvent` / `isPastEvent` gate that controls whether
  // EnrollmentAdminActionBar renders. A fixed past date silently hides the
  // Assign/Invite action bar once that date elapses.
  final now = DateTime.now().toUtc();
  return Event(
    id: _eventId,
    title: 'Test Camp',
    description: '',
    type: EventType.camp,
    visibility: sdk.Visibility.public,
    venueId: 1,
    startTimeUtc: now.add(const Duration(days: 1)),
    endTimeUtc: now.add(const Duration(days: 2)),
    createdAtUtc: now,
    updatedAtUtc: now,
  );
}

class _EnrollmentsStub extends ClEnrollmentsMasterNotifier {
  _EnrollmentsStub(this._data);
  final Map<String, EnrollmentStatus> _data;

  @override
  Future<Map<String, EnrollmentStatus>> build(int arg) async => _data;
}

class _UsersStub extends ClUsersMasterNotifier {
  _UsersStub(this._users);
  final Map<String, UserInfo> _users;

  @override
  Future<Map<String, UserInfo>> build() async => _users;
}

class _CampStub extends ClEventsMasterNotifier {
  _CampStub(this._events);
  final Map<int, Event> _events;

  @override
  Future<Map<int, Event>> build() async => _events;
}

Widget _wrap({
  required UserPrivate currentUser,
  required Map<String, EnrollmentStatus> enrollments,
  Map<String, UserInfo> users = const {},
  Map<int, Event>? events,
  ValueChanged<int>? onManageEnrolments,
  ValueChanged<String>? onMemberTap,
}) {
  return ProviderScope(
    overrides: [
      clEnrollmentsMasterProvider.overrideWith(
        () => _EnrollmentsStub(enrollments),
      ),
      clUsersMasterProvider.overrideWith(() => _UsersStub(users)),
      clEventsMasterProvider.overrideWith(
        () => _CampStub(events ?? {_eventId: _event()}),
      ),
    ],
    child: ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ClEventPendingRequests(
            eventId: _eventId,
            currentUser: currentUser,
            onManageEnrolments: onManageEnrolments,
            onMemberTap: onMemberTap,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Issue 264: only requested-to-join enrollments appear (invited / withdrawRequested excluded)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {
            'alice': EnrollmentStatus.requested,
            'bob': EnrollmentStatus.invited,
            'carol': EnrollmentStatus.withdrawRequested,
            'dave': EnrollmentStatus.assigned,
            'eve': EnrollmentStatus.accepted,
            'frank': EnrollmentStatus.withdrawn,
          },
          users: {
            for (final u in ['alice', 'bob', 'carol', 'dave', 'eve', 'frank'])
              u: _userInfo(username: u, firstName: u, lastName: 'X'),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending requests (1)'), findsOneWidget);
      expect(find.text('alice X'), findsOneWidget);
      expect(find.text('bob X'), findsNothing);
      expect(find.text('carol X'), findsNothing);
      expect(find.text('dave X'), findsNothing);
    },
  );

  testWidgets(
    'Issue 264: empty state shows "No pending requests" with manage link',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {
            'alice': EnrollmentStatus.assigned,
            'bob': EnrollmentStatus.invited,
          },
          users: {
            'alice': _userInfo(
              username: 'alice',
              firstName: 'Alice',
              lastName: 'Smith',
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending requests (0)'), findsOneWidget);
      expect(find.text('No pending requests.'), findsOneWidget);
      expect(find.text('Alice Smith'), findsNothing);
    },
  );

  testWidgets(
    'Issue 264: non-admin / non-coach renders nothing',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(isCoachOrAdmin: false),
          enrollments: const {'alice': EnrollmentStatus.requested},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Pending requests'), findsNothing);
      expect(find.text('alice'), findsNothing);
    },
  );

  testWidgets(
    'Issue 264: tapping a request row fires onMemberTap with username',
    (tester) async {
      String? tappedUsername;
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {'alice': EnrollmentStatus.requested},
          users: {
            'alice': _userInfo(
              username: 'alice',
              firstName: 'Alice',
              lastName: 'Smith',
            ),
          },
          onMemberTap: (username) => tappedUsername = username,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice Smith'));
      await tester.pumpAndSettle();

      expect(tappedUsername, 'alice');
    },
  );

  testWidgets(
    'Issue 264: tapping the top-right icon fires onManageEnrolments '
    'with eventId',
    (tester) async {
      int? tappedEventId;
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {'alice': EnrollmentStatus.requested},
          onManageEnrolments: (id) => tappedEventId = id,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.squareArrowOutUpRight));
      await tester.pumpAndSettle();

      expect(tappedEventId, _eventId);
    },
  );

  testWidgets(
    'Issue 265: each pending row shows Approve and Reject actions',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {
            'alice': EnrollmentStatus.requested,
            'bob': EnrollmentStatus.requested,
          },
          users: {
            'alice': _userInfo(
              username: 'alice',
              firstName: 'Alice',
              lastName: 'Smith',
            ),
            'bob': _userInfo(
              username: 'bob',
              firstName: 'Bob',
              lastName: 'Jones',
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Approve'), findsNWidgets(2));
      expect(find.text('Reject'), findsNWidgets(2));
    },
  );

  testWidgets(
    'Issue 265: tapping Reject opens a reason-capture dialog',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {'alice': EnrollmentStatus.requested},
          users: {
            'alice': _userInfo(
              username: 'alice',
              firstName: 'Alice',
              lastName: 'Smith',
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(find.text('Reject Request'), findsOneWidget);
      expect(find.textContaining('Alice Smith'), findsWidgets);
    },
  );

  testWidgets(
    'Issue 265: empty pending list shows explicit "No pending requests." copy',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {
            'alice': EnrollmentStatus.assigned,
          },
          users: {
            'alice': _userInfo(
              username: 'alice',
              firstName: 'Alice',
              lastName: 'Smith',
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pending requests.'), findsOneWidget);
    },
  );

  group('Issue 136: pending requests are organizer-or-admin', () {
    const organizer = 'the_organizer';
    const assignedCoach = 'assigned_coach';
    final staffed = {
      _eventId: _event().copyWith(
        organizerName: () => organizer,
        coachNames: () => const [assignedCoach],
      ),
    };
    UserPrivate coach(String username) => UserPrivate(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: const UserRoles(isCoach: true),
      createdAtUtc: DateTime.utc(2026, 5, 14),
    );

    testWidgets('Issue 136: a coach assigned to the event sees nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: coach(assignedCoach),
          enrollments: const {'alice': EnrollmentStatus.requested},
          events: staffed,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Pending requests'), findsNothing);
      expect(find.text('Approve'), findsNothing);
      expect(find.textContaining('Assign'), findsNothing);
    });

    testWidgets('Issue 136: the organizer sees the requests and actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: coach(organizer),
          enrollments: const {'alice': EnrollmentStatus.requested},
          events: staffed,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending requests (1)'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.textContaining('Assign'), findsOneWidget);
    });
  });

  testWidgets(
    'Issue 264: Assign and Invite buttons render above the list',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {'alice': EnrollmentStatus.requested},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Assign'), findsOneWidget);
      expect(find.textContaining('Invite'), findsOneWidget);
    },
  );
}
