import 'package:cl_club_events/src/models/withdrawal_reasons.dart';
import 'package:cl_club_events/src/widgets/my_enrollment_status_line.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

Enrollment _removed({String? reason, bool isTrial = true}) => Enrollment(
  id: 1,
  membername: 'm',
  eventId: 9,
  status: EnrollmentStatus.removed,
  createdAtUtc: DateTime.utc(2026),
  isTrial: isTrial,
  withdrawalReason: reason,
  enrolledAtUtc: DateTime(2026, 9, 12, 12).toUtc(),
  withdrawnAtUtc: DateTime(2026, 9, 23, 12).toUtc(),
);

void main() {
  group('Issue 100: an ended trial on the member status line', () {
    test('Issue 100: the trial dates, when credit ran out', () {
      expect(
        endedTrialDates(_removed(reason: trialCreditExhaustedReason)),
        '12 Sep – 23 Sep',
      );
    });

    test('Issue 100: an admin removing a trial member is a plain removal', () {
      final removed = _removed(reason: 'no-show');
      expect(endedTrialDates(removed), isNull);
      expect(
        statusMessage(removed, EventType.programme),
        'You have been removed',
      );
    });
  });
}
