import 'package:cl_club_events/src/models/enrollment_category.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Issue 267: EnrollmentCategory.values orders Pending before Active '
    'before Inactive (pending has actionable items, must surface first)',
    () {
      expect(
        EnrollmentCategory.values,
        const [
          EnrollmentCategory.pending,
          EnrollmentCategory.active,
          EnrollmentCategory.inactive,
        ],
      );
    },
  );

  test(
    'Issue 267: groupByCategory preserves the Pending → Active → Inactive '
    'key order so iteration renders Pending first',
    () {
      final grouped = groupByCategory({
        'user_active': EnrollmentStatus.accepted,
        'user_pending': EnrollmentStatus.requested,
        'user_inactive': EnrollmentStatus.withdrawn,
      });

      expect(
        grouped.keys.toList(),
        const [
          EnrollmentCategory.pending,
          EnrollmentCategory.active,
          EnrollmentCategory.inactive,
        ],
      );
      expect(grouped[EnrollmentCategory.pending]!.keys, ['user_pending']);
      expect(grouped[EnrollmentCategory.active]!.keys, ['user_active']);
      expect(grouped[EnrollmentCategory.inactive]!.keys, ['user_inactive']);
    },
  );
}
