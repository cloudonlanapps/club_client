import 'package:club_sdk_2/club_sdk_2.dart' show EnrollmentStatus;

import 'withdrawal_reasons.dart';

/// Client-side filters inside the Inactive enrollment group (club_core#98).
enum InactiveEnrollmentFilter {
  all,
  trialEnded,
  removed,
  withdrawn;

  /// Whether an inactive member with [status] and [withdrawalReason] shows
  /// under this filter. A trial that ended is not counted as removed.
  bool matches(EnrollmentStatus status, String? withdrawalReason) {
    final trialEnded =
        status == EnrollmentStatus.removed &&
        isTrialCreditExhausted(withdrawalReason);
    return switch (this) {
      InactiveEnrollmentFilter.all => true,
      InactiveEnrollmentFilter.trialEnded => trialEnded,
      InactiveEnrollmentFilter.removed =>
        status == EnrollmentStatus.removed && !trialEnded,
      InactiveEnrollmentFilter.withdrawn =>
        status == EnrollmentStatus.withdrawn,
    };
  }
}
