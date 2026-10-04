import 'package:club_sdk_2/club_sdk_2.dart';

/// Logical grouping of enrollment statuses for display.
enum EnrollmentCategory {
  pending('Pending', 'Awaiting action'),
  active('Active', 'Assigned or accepted members'),
  inactive('Inactive', 'No longer enrolled');

  const EnrollmentCategory(this.label, this.description);

  final String label;
  final String description;
}

/// Returns the category for a given enrollment status.
EnrollmentCategory categoryFor(EnrollmentStatus status) {
  return switch (status) {
    EnrollmentStatus.assigned ||
    EnrollmentStatus.accepted ||
    EnrollmentStatus.assignedTrial => EnrollmentCategory.active,
    EnrollmentStatus.invited ||
    EnrollmentStatus.requested ||
    EnrollmentStatus.withdrawRequested => EnrollmentCategory.pending,
    EnrollmentStatus.withdrawn ||
    EnrollmentStatus.removed ||
    EnrollmentStatus.rejected ||
    EnrollmentStatus.declined => EnrollmentCategory.inactive,
  };
}

/// Groups a flat enrollment map into categories.
Map<EnrollmentCategory, Map<String, EnrollmentStatus>> groupByCategory(
  Map<String, EnrollmentStatus> enrollments,
) {
  final result = <EnrollmentCategory, Map<String, EnrollmentStatus>>{
    EnrollmentCategory.pending: {},
    EnrollmentCategory.active: {},
    EnrollmentCategory.inactive: {},
  };

  for (final entry in enrollments.entries) {
    final category = categoryFor(entry.value);
    result[category]![entry.key] = entry.value;
  }

  return result;
}
