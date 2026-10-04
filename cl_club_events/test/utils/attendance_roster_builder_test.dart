import 'package:cl_club_events/src/utils/attendance_roster_builder.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/credit_scope.dart';

final _session = DateTime.utc(2026, 9, 26, 12);

Enrollment _enrollment(String membername, EnrollmentStatus status) =>
    Enrollment(
      id: membername.length,
      eventId: programmeId,
      membername: membername,
      status: status,
      createdAtUtc: DateTime.utc(2026, 9),
      enrolledAtUtc: DateTime.utc(2026, 9),
    );

AttendanceRecord _record(String membername, AttendanceStatus status) =>
    AttendanceRecord(
      id: membername.length,
      occurrenceId: _session.millisecondsSinceEpoch,
      membername: membername,
      status: status,
      recordedAtUtc: _session,
    );

void main() {
  test('Issue 113: a member whose withdrawal is pending stays on the '
      'register', () {
    final roster = buildAttendanceRoster(
      enrollments: {
        'active': _enrollment('active', EnrollmentStatus.assigned),
        'leaving': _enrollment('leaving', EnrollmentStatus.withdrawRequested),
        'gone': _enrollment('gone', EnrollmentStatus.withdrawn),
      },
      records: const [],
      occurrenceTimeUtc: _session,
    );
    expect(roster.map((e) => e.username), ['active', 'leaving']);
  });

  group('Issue 99: who cannot be charged', () {
    final enrollments = {
      'broke': _enrollment('broke', EnrollmentStatus.assigned),
      'paid': _enrollment('paid', EnrollmentStatus.assigned),
      'on_leave': _enrollment('on_leave', EnrollmentStatus.assigned),
      'funded': _enrollment('funded', EnrollmentStatus.assigned),
    };
    final roster = buildAttendanceRoster(
      enrollments: enrollments,
      records: [
        _record('paid', AttendanceStatus.present),
        _record('on_leave', AttendanceStatus.onLeave),
      ],
      occurrenceTimeUtc: _session,
      creditRoster: {
        'broke': rosterRow('broke'),
        'paid': rosterRow('paid'),
        'on_leave': rosterRow('on_leave'),
        'funded': rosterRow('funded', usable: 4),
      },
    );
    bool blocked(String u) =>
        roster.firstWhere((e) => e.username == u).creditBlocked;

    test('Issue 99: no record and no credit is blocked', () {
      expect(blocked('broke'), isTrue);
    });
    test('Issue 99: an already charged record is never blocked', () {
      expect(blocked('paid'), isFalse);
    });
    test('Issue 99: leave is uncharged, so it is blocked like no record', () {
      expect(blocked('on_leave'), isTrue);
    });
    test('Issue 99: usable credit is not blocked', () {
      expect(blocked('funded'), isFalse);
    });
    test('Issue 99: without a credit roster nothing is blocked', () {
      final plain = buildAttendanceRoster(
        enrollments: enrollments,
        records: const [],
        occurrenceTimeUtc: _session,
      );
      expect(plain.any((e) => e.creditBlocked), isFalse);
    });
  });

  test('Issue 98: a trial this session ended stays, flagged', () {
    final roster = buildAttendanceRoster(
      enrollments: {'trial': _enrollment('trial', EnrollmentStatus.removed)},
      records: [_record('trial', AttendanceStatus.present)],
      occurrenceTimeUtc: _session,
      trialEnded: {'trial'},
    );
    expect(roster.single.trialEnded, isTrue);
    expect(roster.single.creditBlocked, isFalse);
  });

  test("Issue 137: a leave request carries the member's reason", () {
    final roster = buildAttendanceRoster(
      enrollments: {
        'away': _enrollment('away', EnrollmentStatus.assigned),
        'here': _enrollment('here', EnrollmentStatus.assigned),
      },
      records: [
        _record(
          'away',
          AttendanceStatus.onLeaveRequested,
        ).copyWith(leaveReason: () => 'Exams'),
        _record('here', AttendanceStatus.present),
      ],
      occurrenceTimeUtc: _session,
    );
    expect(roster.map((e) => e.leaveReason), ['Exams', null]);
  });
}
