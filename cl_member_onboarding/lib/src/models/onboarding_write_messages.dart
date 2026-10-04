// Fixed messages for onboarding writes that fail. A write that may have
// landed shows `uncertainWriteMessage` (cl_remote_store) instead; the raw
// error is never shown (club_core#138).

/// Shown when submitting the application for review fails.
const String submissionFailedMessage =
    'Could not submit your application. Please try again.';

/// Shown when resubmitting changed details fails.
const String reapplyFailedMessage =
    'Could not submit your changes. Please try again.';
