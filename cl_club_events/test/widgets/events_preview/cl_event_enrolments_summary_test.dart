import 'package:cl_club_events/src/widgets/events_preview/cl_event_enrolments_summary.dart';
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
  final now = DateTime.utc(2026, 5, 14);
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
  int previewLimit = 5,
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
          child: ClEventEnrolmentsSummary(
            eventId: _eventId,
            currentUser: currentUser,
            onManageEnrolments: onManageEnrolments,
            onMemberTap: onMemberTap,
            previewLimit: previewLimit,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Issue 537: only active enrolments appear '
    '(invited / requested / withdrawn excluded)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {
            'alice': EnrollmentStatus.assigned,
            'bob': EnrollmentStatus.accepted,
            'carol': EnrollmentStatus.assignedTrial,
            'dan': EnrollmentStatus.invited,
            'eve': EnrollmentStatus.requested,
            'frank': EnrollmentStatus.withdrawn,
          },
          users: {
            'alice': _userInfo(
              username: 'alice',
              firstName: 'Alice',
              lastName: 'A',
            ),
            'bob': _userInfo(username: 'bob', firstName: 'Bob', lastName: 'B'),
            'carol': _userInfo(
              username: 'carol',
              firstName: 'Carol',
              lastName: 'C',
            ),
            'dan': _userInfo(username: 'dan', firstName: 'Dan', lastName: 'D'),
            'eve': _userInfo(username: 'eve', firstName: 'Eve', lastName: 'E'),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice A'), findsOneWidget);
      expect(find.text('Bob B'), findsOneWidget);
      expect(find.text('Carol C'), findsOneWidget);
      expect(find.text('Dan D'), findsNothing);
      expect(find.text('Eve E'), findsNothing);
      expect(find.text('Enrolments (3)'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 537: empty active list shows "No enrolments yet" copy',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {
            'eve': EnrollmentStatus.requested,
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No enrolments yet.'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 537: non-admin / non-coach renders nothing',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(isCoachOrAdmin: false),
          enrollments: const {
            'alice': EnrollmentStatus.assigned,
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClEventEnrolmentsSummary), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Enrolments (1)'), findsNothing);
    },
  );

  testWidgets(
    'Issue 537: truncates to previewLimit and shows "+N more" hint',
    (tester) async {
      final enrollments = <String, EnrollmentStatus>{
        for (var i = 0; i < 7; i++) 'u$i': EnrollmentStatus.assigned,
      };
      final users = <String, UserInfo>{
        for (var i = 0; i < 7; i++)
          'u$i': _userInfo(username: 'u$i', firstName: 'User', lastName: '$i'),
      };

      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: enrollments,
          users: users,
          previewLimit: 3,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('User 0'), findsOneWidget);
      expect(find.text('User 1'), findsOneWidget);
      expect(find.text('User 2'), findsOneWidget);
      expect(find.text('User 3'), findsNothing);
      expect(find.text('+4 more — tap to see all'), findsOneWidget);
      expect(find.text('Enrolments (7)'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 537: heading icon fires onManageEnrolments with eventId',
    (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {'alice': EnrollmentStatus.assigned},
          users: {
            'alice': _userInfo(
              username: 'alice',
              firstName: 'A',
              lastName: 'A',
            ),
          },
          onManageEnrolments: (id) {
            expect(id, _eventId);
            tapped++;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Manage enrollments'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    },
  );

  testWidgets(
    'Issue 537: tapping "+N more" fires onManageEnrolments with eventId',
    (tester) async {
      var tapped = 0;
      final enrollments = <String, EnrollmentStatus>{
        for (var i = 0; i < 7; i++) 'u$i': EnrollmentStatus.assigned,
      };

      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: enrollments,
          previewLimit: 3,
          onManageEnrolments: (id) {
            expect(id, _eventId);
            tapped++;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+4 more — tap to see all'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    },
  );

  testWidgets(
    'Issue 537: tapping an active row fires onMemberTap with username',
    (tester) async {
      var tappedUsername = '';
      await tester.pumpWidget(
        _wrap(
          currentUser: _user(),
          enrollments: const {'alice': EnrollmentStatus.assigned},
          users: {
            'alice': _userInfo(
              username: 'alice',
              firstName: 'Alice',
              lastName: 'A',
            ),
          },
          onMemberTap: (u) {
            tappedUsername = u;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice A'));
      await tester.pumpAndSettle();
      expect(tappedUsername, 'alice');
    },
  );

  group('Issue 136: the summary acts only for organizer-or-admin', () {
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
    final alice = {
      'alice': _userInfo(username: 'alice', firstName: 'Alice', lastName: 'A'),
    };

    testWidgets('Issue 136: an assigned coach reads it, with no Remove', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: coach(assignedCoach),
          enrollments: const {'alice': EnrollmentStatus.assigned},
          users: alice,
          events: staffed,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice A'), findsOneWidget);
      expect(find.text('Remove'), findsNothing);
    });

    testWidgets('Issue 136: the organizer may remove', (tester) async {
      await tester.pumpWidget(
        _wrap(
          currentUser: coach(organizer),
          enrollments: const {'alice': EnrollmentStatus.assigned},
          users: alice,
          events: staffed,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice A'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });
  });
}
