import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_club_events/src/widgets/attendance_roster_list.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _eventId = 211;
const _coach = 'coach211';
const _member = 'member211';

UserPrivate _user(String username, {bool superAdmin = false}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: superAdmin,
  roles: const UserRoles(isCoach: true),
  createdAtUtc: DateTime.utc(2026),
);

class _Events extends ClEventsMasterNotifier {
  _Events(this.event);
  final Event event;
  @override
  Future<Map<int, Event>> build() async => {event.id: event};
}

class _Enrollments extends ClEnrollmentRecordsMasterNotifier {
  @override
  Future<Map<String, Enrollment>> build(int arg) async => {
    _member: Enrollment(
      id: 1,
      eventId: _eventId,
      membername: _member,
      status: EnrollmentStatus.assigned,
      createdAtUtc: DateTime.utc(2026),
      enrolledAtUtc: DateTime.utc(2026),
    ),
  };
}

class _Attendance extends ClAttendancesMasterNotifier {
  @override
  Future<List<AttendanceRecord>> build(ClAttendancesKey arg) async => const [];
}

class _Users extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => const {};
}

class _NoCredit extends ClEventCreditRosterNotifier {
  @override
  Future<Map<String, MemberCreditStatus>> build(int arg) async => const {};
}

/// Pumps the register for a one-hour session that started at [startUtc],
/// viewed by [viewer].
Future<void> _pumpRegister(
  WidgetTester tester, {
  required UserPrivate viewer,
  required DateTime startUtc,
}) async {
  final endUtc = startUtc.add(const Duration(hours: 1));
  final event = Event(
    id: _eventId,
    title: 'Issue 211 Camp',
    description: '',
    type: EventType.camp,
    visibility: sdk.Visibility.public,
    venueId: 1,
    coachNames: const [_coach],
    startTimeUtc: startUtc,
    endTimeUtc: endUtc,
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => _Events(event)),
        clEnrollmentRecordsMasterProvider.overrideWith(_Enrollments.new),
        clAttendancesMasterProvider.overrideWith(_Attendance.new),
        clUsersMasterProvider.overrideWith(_Users.new),
        clEventCreditRosterProvider.overrideWith(_NoCredit.new),
        clSingleOccurrenceProvider.overrideWith(
          (ref, key) async => Occurrence(
            eventId: _eventId,
            originalStartTimeUtc: startUtc,
            actualStartTimeUtc: startUtc,
            actualEndTimeUtc: endUtc,
            status: OccurrenceStatus.scheduled,
            venueId: 1,
          ),
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: EventOccurencesAttendanceView(
            currentUser: viewer,
            eventId: _eventId,
            occurrenceTimeUtc: startUtc,
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

bool _rowsEditable(WidgetTester tester) => tester
    .widget<AttendanceRosterList>(find.byType(AttendanceRosterList))
    .isEditable;

void main() {
  final now = DateTime.now().toUtc();

  testWidgets(
    'Issue 211: a super-admin edits a session that ended 20 days ago',
    (tester) async {
      await _pumpRegister(
        tester,
        viewer: _user('root211', superAdmin: true),
        startUtc: now.subtract(const Duration(days: 20, hours: 1)),
      );

      expect(_rowsEditable(tester), isTrue);
      expect(find.textContaining('Edit window closed'), findsNothing);
      expect(find.textContaining('Attendance opens'), findsNothing);
    },
  );

  testWidgets(
    'Issue 211: a coach cannot edit 15 days 23 hours after the session',
    (tester) async {
      await _pumpRegister(
        tester,
        viewer: _user(_coach),
        startUtc: now.subtract(const Duration(days: 15, hours: 24)),
      );

      expect(_rowsEditable(tester), isFalse);
      expect(find.textContaining('Edit window closed'), findsOneWidget);
      expect(find.textContaining('Attendance opens'), findsNothing);
    },
  );

  testWidgets(
    'Issue 211: before the window opens the banner says when it opens',
    (tester) async {
      await _pumpRegister(
        tester,
        viewer: _user(_coach),
        startUtc: now.add(const Duration(hours: 2)),
      );

      expect(_rowsEditable(tester), isFalse);
      expect(find.textContaining('Attendance opens'), findsOneWidget);
      expect(find.textContaining('Edit window closed'), findsNothing);
    },
  );
}
