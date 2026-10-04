import 'package:cl_club_events/src/widgets/cards/actions/user_occurrence_actions.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, ActionGroup, ActionItem;

import '../../support/credit_scope.dart';

const _member = 'leave_member';

/// Fails its first [failures] reads with [error], then answers [record].
class _Attendance extends ClMyAttendancesMasterNotifier {
  _Attendance(this.error, {this.failures = 1 << 30, this.record});
  final ServerException error;
  final AttendanceRecord? record;
  int failures;
  int reads = 0;

  @override
  Future<AttendanceRecord?> build(ClMyAttendancesKey arg) async {
    reads++;
    if (failures-- > 0) throw error;
    return record;
  }
}

class _MyEvents extends ClMyEventsMasterNotifier {
  @override
  Future<List<Event>> build(String arg) async => [
    event(campId, EventType.camp),
  ];
}

/// A failed read with [statusCode], as the SDK throws it since 0.6.0.
ServerException _refusal(int statusCode) =>
    ServerException(statusCode: statusCode, code: 'refused', message: 'no');

Occurrence _occurrence() {
  final start = DateTime.now().toUtc().add(const Duration(days: 3));
  return Occurrence(
    eventId: campId,
    originalStartTimeUtc: start,
    actualStartTimeUtc: start,
    actualEndTimeUtc: start.add(const Duration(hours: 1)),
    status: OccurrenceStatus.scheduled,
    venueId: 1,
  );
}

Enrollment _accepted() => Enrollment(
  id: 1,
  membername: _member,
  eventId: campId,
  status: EnrollmentStatus.accepted,
  createdAtUtc: DateTime.utc(2026),
);

Future<List<ActionItem>> _pump(
  WidgetTester tester,
  _Attendance attendance,
) async {
  var actions = <ActionItem>[];
  await tester.pumpWidget(
    creditScope(
      user: person(_member),
      creditSystem: false,
      extra: [
        clMyEnrollmentProvider.overrideWith((ref, key) async => _accepted()),
        clMyEventsMasterProvider.overrideWith(_MyEvents.new),
        clMyAttendancesMasterProvider.overrideWith(() => attendance),
      ],
      child: UserOccurrenceActions(
        username: _member,
        occurrence: _occurrence(),
        builder: (context, resolved) {
          actions = resolved;
          return ActionGroup(actions: resolved);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return actions;
}

void main() {
  group('Issue 139: a failed attendance read on the member occurrence', () {
    testWidgets('Issue 139: no record offers Apply Leave', (tester) async {
      final actions = await _pump(
        tester,
        _Attendance(_refusal(500), failures: 0),
      );
      expect(actions.map((a) => a.label), ['Apply Leave', 'Withdraw']);
    });

    testWidgets(
      'Issue 139: a server error does not read as no attendance — it offers '
      'a reload, not Apply Leave',
      (tester) async {
        final actions = await _pump(
          tester,
          _Attendance(_refusal(500)),
        );
        final labels = actions.map((a) => a.label);
        expect(labels, isNot(contains('Apply Leave')));
        expect(labels, contains(UserOccurrenceActions.reloadLeaveLabel));
        expect(labels, contains('Withdraw'));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Issue 139: reloading after the error reads the record again', (
      tester,
    ) async {
      final attendance = _Attendance(
        _refusal(403),
        failures: 1,
        record: AttendanceRecord(
          id: 1,
          occurrenceId: 1,
          membername: _member,
          status: AttendanceStatus.onLeaveRequested,
          recordedAtUtc: DateTime.utc(2026),
        ),
      );
      await _pump(tester, attendance);

      await tester.tap(
        find.widgetWithText(
          ActionButton,
          UserOccurrenceActions.reloadLeaveLabel,
        ),
      );
      await tester.pumpAndSettle();

      expect(attendance.reads, 2);
      expect(
        find.widgetWithText(ActionButton, 'Cancel Leave Request'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          ActionButton,
          UserOccurrenceActions.reloadLeaveLabel,
        ),
        findsNothing,
      );
    });
  });
}
