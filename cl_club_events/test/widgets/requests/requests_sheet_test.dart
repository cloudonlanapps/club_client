import 'package:cl_club_events/src/widgets/requests/requests_sheet.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionIcon;

const _eventId = 437;
const _organizer = 'organizer437';
const _coach = 'coach437';

final DateTime _slot = DateTime.now().toUtc().add(const Duration(days: 3));

UserPrivate _user(String username) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isCoach: true),
  createdAtUtc: DateTime.utc(2026),
);

final _event = Event(
  id: _eventId,
  title: 'Issue 437 Camp',
  description: '',
  type: EventType.camp,
  visibility: sdk.Visibility.public,
  venueId: 1,
  organizerName: _organizer,
  coachNames: const [_coach],
  startTimeUtc: _slot,
  endTimeUtc: _slot.add(const Duration(hours: 1)),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

final _occurrence = Occurrence(
  eventId: _eventId,
  originalStartTimeUtc: _slot,
  actualStartTimeUtc: _slot,
  actualEndTimeUtc: _slot.add(const Duration(hours: 1)),
  status: OccurrenceStatus.scheduled,
  venueId: 1,
);

AttendanceRecord _record(String member, AttendanceStatus status) =>
    AttendanceRecord(
      id: member.hashCode,
      occurrenceId: 1,
      membername: member,
      status: status,
      recordedAtUtc: DateTime.utc(2026),
    );

class _Auth extends AuthNotifier {
  _Auth(this._user);
  final UserPrivate _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

class _Events extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async => {_eventId: _event};
}

class _Enrollments extends ClEnrollmentsMasterNotifier {
  _Enrollments(this._data);
  final Map<String, EnrollmentStatus> _data;
  @override
  Future<Map<String, EnrollmentStatus>> build(int arg) async => _data;
}

class _Records extends ClEnrollmentRecordsMasterNotifier {
  @override
  Future<Map<String, Enrollment>> build(int arg) async => const {};
}

class _Attendance extends ClAttendancesMasterNotifier {
  _Attendance(this._records, this.calls);
  final List<AttendanceRecord> _records;
  final List<String> calls;
  @override
  Future<List<AttendanceRecord>> build(ClAttendancesKey arg) async => _records;
  @override
  Future<void> approveLeave(String username) async =>
      calls.add('approve $username');
}

class _Users extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => const {};
}

Future<List<String>> _pump(
  WidgetTester tester, {
  required UserPrivate viewer,
  List<AttendanceRecord> leave = const [],
  Map<String, EnrollmentStatus> enrollments = const {},
}) async {
  final calls = <String>[];
  // A phone's width, where the three labels must still fit.
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _Auth(viewer)),
        clEventsMasterProvider.overrideWith(_Events.new),
        clEnrollmentsMasterProvider.overrideWith(
          () => _Enrollments(enrollments),
        ),
        clEnrollmentRecordsMasterProvider.overrideWith(_Records.new),
        clAttendancesMasterProvider.overrideWith(
          () => _Attendance(leave, calls),
        ),
        clUsersMasterProvider.overrideWith(_Users.new),
      ],
      child: ShadApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () =>
                  showRequestsSheet(context, ref, occurrence: _occurrence),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _openTab(tester, 'open');
  return calls;
}

/// Scrolls the tab bar to the tab labelled [label] and opens it.
Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// The Approve icon of a pending leave row.
final Finder _approveIcon = find.byWidgetPredicate(
  (w) => w is ActionIcon && w.label == 'Approve',
);

void main() {
  testWidgets(
    'Issue 437: Requests opens on Leave, tabs in order with their counts',
    (tester) async {
      await _pump(
        tester,
        viewer: _user(_organizer),
        leave: [
          _record('ann', AttendanceStatus.onLeaveRequested),
          _record('bob', AttendanceStatus.onLeave),
          _record('cy', AttendanceStatus.present),
        ],
        enrollments: const {
          'dee': EnrollmentStatus.requested,
          'eve': EnrollmentStatus.withdrawRequested,
          'fay': EnrollmentStatus.assigned,
        },
      );
      expect(find.text('Requests'), findsOneWidget);
      final labels = ['Leave (2)', 'Enrollment (1)', 'Withdrawal (1)'];
      final xs = [for (final l in labels) tester.getCenter(find.text(l)).dx];
      expect(xs, orderedEquals([...xs]..sort()));
      // Leave shows: pending with its actions, approved below it.
      expect(find.text('ann'), findsOneWidget);
      expect(find.text('bob'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('cy'), findsNothing);
      expect(find.text('dee'), findsNothing);
    },
  );

  testWidgets('Issue 437: each empty tab says so', (tester) async {
    await _pump(tester, viewer: _user(_organizer));
    expect(find.text('No leave requests for this session.'), findsOneWidget);
    await _openTab(tester, 'Enrollment (0)');
    expect(find.text('No enrollment requests.'), findsOneWidget);
    await _openTab(tester, 'Withdrawal (0)');
    expect(find.text('No withdrawal requests.'), findsOneWidget);
  });

  testWidgets(
    'Issue 437: an assigned coach approves leave but only reads enrollment '
    'and withdrawal requests',
    (tester) async {
      final calls = await _pump(
        tester,
        viewer: _user(_coach),
        leave: [_record('ann', AttendanceStatus.onLeaveRequested)],
        enrollments: const {
          'dee': EnrollmentStatus.requested,
          'eve': EnrollmentStatus.withdrawRequested,
        },
      );
      await tester.tap(_approveIcon);
      await tester.pumpAndSettle();
      expect(calls, ['approve ann']);

      for (final (tab, member) in [
        ('Enrollment (1)', 'dee'),
        ('Withdrawal (1)', 'eve'),
      ]) {
        await _openTab(tester, tab);
        expect(find.text(member), findsWidgets, reason: tab);
        expect(find.text('Approve'), findsNothing, reason: tab);
        expect(_approveIcon, findsNothing, reason: tab);
      }
    },
  );

  testWidgets(
    'Issue 437: the organizer is offered Approve on enrollment requests',
    (tester) async {
      await _pump(
        tester,
        viewer: _user(_organizer),
        enrollments: const {'dee': EnrollmentStatus.requested},
      );
      await _openTab(tester, 'Enrollment (1)');
      expect(
        find.text('Approve').evaluate().isNotEmpty ||
            _approveIcon.evaluate().isNotEmpty,
        isTrue,
      );
    },
  );
}
