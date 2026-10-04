/// Shown when creating a venue fails. A write that may have landed shows
/// `uncertainWriteMessage` (cl_remote_store) instead; the raw error is never
/// shown (club_core#138).
const String venueCreateFailedMessage =
    'Could not create venue. Please try again.';
