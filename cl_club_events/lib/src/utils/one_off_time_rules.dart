/// The server's time rules for calling off and reinstating a one-off
/// (club_server `OneOffService`), shared by the occurrence card and the
/// event page so the two offer the same actions.
library;

/// Whether a called-off one-off whose single occurrence starts at
/// [slotUtc] can be reinstated at [now] (default: now): until it starts,
/// for the event's managers; after that by nobody, a super-admin included
/// ("a passed occasion cannot be reinstated", one-off R7). No lead time
/// applies.
///
/// [slotUtc] is the occurrence's slot (`originalStartTimeUtc`): a one-off
/// is moved by its own reschedule, which moves the slot itself.
bool canReinstateOneOffAt(DateTime slotUtc, {DateTime? now}) =>
    slotUtc.isAfter((now ?? DateTime.now()).toUtc());
