/// Upper bound on the admin user-review form's reason field. The reason is
/// optional for all three actions — the host receives null when the field
/// is empty.
const int kAdminReviewReasonMaxLength = 500;

/// How long a review page's Approve / Reject / Block stay off after the
/// page appears. A pending user who slides into the slot left by the one
/// just decided would otherwise be decided by a repeated tap (#149).
const Duration kAdminReviewArmDelay = Duration(milliseconds: 1500);
