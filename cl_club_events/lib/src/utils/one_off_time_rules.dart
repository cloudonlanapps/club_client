/// The server's time rules for calling off and reinstating a one-off
/// (club_server `OneOffService`), shared by the occurrence card and the
/// event page so the two offer the same actions (club_client#187).
library;

import 'package:club_sdk_2/club_sdk_2.dart'
    show UserPrivate, isInScheduleManagementWindow;

/// Whether [actingUser], one of the event's managers, can call off a
/// one-off whose single occurrence starts at [startUtc] (its effective
/// start): more than 30 minutes before it (one-off R5,
/// `CANCELLATION_LEAD_TIME_VIOLATED`; after the start `PAST_OCCURRENCE`),
/// or any time for a super-admin, after the start too (R5a, a
/// retrospective drop).
bool canCallOffOneOffAt(DateTime startUtc, UserPrivate actingUser) =>
    actingUser.isSuperAdmin || isInScheduleManagementWindow(startUtc);

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
