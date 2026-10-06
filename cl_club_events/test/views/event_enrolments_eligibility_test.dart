import 'package:cl_club_events/src/views/event_enrolments_view.dart';
import 'package:cl_club_events/src/widgets/enrollment_tile.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEnrollmentRecordsMasterNotifier,
        ClEnrollmentsMasterNotifier,
        ClUsersMasterNotifier,
        clEnrollmentRecordsMasterProvider,
        clEnrollmentsMasterProvider,
        clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show AgeEligibilityText;

import '../support/credit_scope.dart';

const _outgrown = 'outgrown_member';
const _matching = 'matching_member';

class _Enrollments extends ClEnrollmentsMasterNotifier {
  @override
  Future<Map<String, EnrollmentStatus>> build(int arg) async => const {
    _outgrown: EnrollmentStatus.assigned,
    _matching: EnrollmentStatus.assigned,
  };
}

Enrollment _record(int id, String membername, {required bool eligible}) =>
    Enrollment(
      id: id,
      membername: membername,
      eventId: programmeId,
      status: EnrollmentStatus.assigned,
      createdAtUtc: DateTime.utc(2026),
      eligible: eligible,
    );

class _Records extends ClEnrollmentRecordsMasterNotifier {
  @override
  Future<Map<String, Enrollment>> build(int arg) async => {
    _outgrown: _record(1, _outgrown, eligible: false),
    _matching: _record(2, _matching, eligible: true),
  };
}

class _NoRecords extends ClEnrollmentRecordsMasterNotifier {
  @override
  Future<Map<String, Enrollment>> build(int arg) async => const {};
}

class _Users extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => const {};
}

Future<void> _pump(
  WidgetTester tester,
  ClEnrollmentRecordsMasterNotifier Function() records,
) async {
  final admin = person('club_admin', admin: true);
  await tester.pumpWidget(
    creditScope(
      user: admin,
      creditSystem: false,
      events: {programmeId: staffed(programmeId, EventType.programme)},
      extra: [
        clEnrollmentsMasterProvider.overrideWith(_Enrollments.new),
        clEnrollmentRecordsMasterProvider.overrideWith(records),
        clUsersMasterProvider.overrideWith(_Users.new),
      ],
      child: EventEnrolmentsView(currentUser: admin, eventId: programmeId),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _tile(String username) => find.byWidgetPredicate(
  (w) => w is EnrollmentTile && w.username == username,
);

Finder _markIn(String username) => find.descendant(
  of: _tile(username),
  matching: find.text(AgeEligibilityText.noLongerEligible),
);

void main() {
  group('Issue 42: the enrolment list marks who no longer matches', () {
    testWidgets(
      'Issue 42: a member reported with eligible false is marked',
      (tester) async {
        await _pump(tester, _Records.new);

        expect(_markIn(_outgrown), findsOneWidget);
      },
    );

    testWidgets('Issue 42: a member reported eligible is not marked', (
      tester,
    ) async {
      await _pump(tester, _Records.new);

      expect(_tile(_matching), findsOneWidget);
      expect(_markIn(_matching), findsNothing);
      expect(find.text(AgeEligibilityText.noLongerEligible), findsOneWidget);
    });

    testWidgets('Issue 42: nobody is marked while the records are not known', (
      tester,
    ) async {
      await _pump(tester, _NoRecords.new);

      expect(_tile(_outgrown), findsOneWidget);
      expect(find.text(AgeEligibilityText.noLongerEligible), findsNothing);
    });

    testWidgets('Issue 42: the marked member keeps the admin actions', (
      tester,
    ) async {
      await _pump(tester, _Records.new);

      expect(
        find.descendant(of: _tile(_outgrown), matching: find.text('Remove')),
        findsOneWidget,
      );
    });
  });
}
