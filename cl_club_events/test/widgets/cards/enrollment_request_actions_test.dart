import 'package:cl_club_events/src/widgets/buttons/enrollment_action_buttons.dart';
import 'package:cl_club_events/src/widgets/cards/actions/user_event_actions.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, ActionGroup, ActionItem;

import '../../support/credit_scope.dart';

const _member = 'member212';

Enrollment _enrollment(int eventId, EnrollmentStatus status) => Enrollment(
  id: 1,
  membername: _member,
  eventId: eventId,
  status: status,
  createdAtUtc: DateTime.utc(2026),
);

/// Records the withdrawals asked of it.
class _RecordingEnrollments extends ClMyEnrollmentsMasterNotifier {
  _RecordingEnrollments(this.withdrawals);
  final List<ClMyEnrollmentsKey> withdrawals;

  @override
  Future<Enrollment> build(ClMyEnrollmentsKey arg) async =>
      _enrollment(arg.eventId, EnrollmentStatus.requested);

  @override
  Future<void> withdraw({String? reason}) async => withdrawals.add(key);
}

void main() {
  testWidgets(
    'Issue 212: the event page offers Cancel Request for a pending request',
    (tester) async {
      final withdrawals = <ClMyEnrollmentsKey>[];
      final camp = event(campId, EventType.camp);
      await tester.pumpWidget(
        creditScope(
          user: person(_member),
          creditSystem: false,
          extra: [
            clMyEnrollmentProvider.overrideWith(
              (ref, key) async =>
                  _enrollment(campId, EnrollmentStatus.requested),
            ),
            clMyEventDetailProvider.overrideWith((ref, key) async => camp),
            clMyEnrollmentsMasterProvider.overrideWith(
              () => _RecordingEnrollments(withdrawals),
            ),
          ],
          child: const EnrollmentActionButtons(
            username: _member,
            eventId: campId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cancel = find.widgetWithText(ActionButton, 'Cancel Request');
      expect(cancel, findsOneWidget);
      expect(find.text('Requested'), findsNothing);

      await tester.tap(cancel);
      await tester.pumpAndSettle();

      expect(withdrawals, [(username: _member, eventId: campId)]);
    },
  );

  testWidgets(
    'Issue 212: the event card offers no Accept when the member cannot '
    'enroll',
    (tester) async {
      final now = DateTime.now().toUtc();
      final ended = event(campId, EventType.camp).copyWith(
        startTimeUtc: now.subtract(const Duration(days: 2)),
        endTimeUtc: now.subtract(const Duration(days: 2, hours: -1)),
      );
      var actions = <ActionItem>[];
      await tester.pumpWidget(
        creditScope(
          user: person(_member),
          creditSystem: false,
          extra: [
            clMyEnrollmentProvider.overrideWith(
              (ref, key) async => _enrollment(campId, EnrollmentStatus.invited),
            ),
          ],
          child: UserEventActions(
            username: _member,
            event: ended,
            builder: (context, resolved) {
              actions = resolved;
              return ActionGroup(actions: resolved);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(actions.map((a) => a.label), ['Decline']);
    },
  );
}
