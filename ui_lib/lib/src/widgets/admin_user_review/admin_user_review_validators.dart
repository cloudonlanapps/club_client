import '../../constants/admin_user_review.dart';
import 'admin_user_review_form_data.dart';

/// Validators used by the admin user-review form's Reason input.
///
/// The reason is optional for all three actions — the host receives null
/// when the field is empty. The only hard rule is a max length so the
/// callback never receives a runaway string.
abstract class AdminUserReviewFormValidators {
  /// Returns an error string for invalid input, or null when the value is
  /// acceptable. The only check is the upper bound on length.
  static String? reason(String? raw, AdminUserReviewAction action) {
    final value = (raw ?? '').trim();
    if (value.length > kAdminReviewReasonMaxLength) {
      return 'Please keep it under '
          '$kAdminReviewReasonMaxLength characters.';
    }
    return null;
  }

  /// Whether the Confirm button should be enabled. Reason is optional, so
  /// the button is enabled unless the user has typed past the max length.
  static bool canConfirm({
    required AdminUserReviewAction action,
    required String reason,
  }) {
    return reason.trim().length <= kAdminReviewReasonMaxLength;
  }
}
