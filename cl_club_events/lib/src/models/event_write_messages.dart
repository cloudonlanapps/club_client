// Fixed messages for event writes that fail with no more specific
// explanation. A write that may have landed shows `uncertainWriteMessage`
// (cl_remote_store) instead; the raw error is never shown (club_core#138).

/// Shown when a mark or clear fails.
const String attendanceSaveFailedMessage =
    'Could not save the attendance mark. Please try again.';

/// Shown when a leave approval or rejection fails.
const String leaveDecisionFailedMessage =
    'Could not record the leave decision. Please try again.';

/// Shown when an enrollment, occurrence or leave action fails.
const String eventActionFailedMessage =
    'Could not complete the action. Please try again.';

/// Shown when dismissing a notification fails.
const String dismissNotificationFailedMessage =
    'Could not dismiss the notification. Please try again.';
