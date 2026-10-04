import 'package:club_sdk_2/club_sdk_2.dart' show Event, UserPrivate;

/// Returns true if [user] may view or manage club-wide event screens
/// (`/memberzone/events/*`). Admins (including super-admins) and coaches
/// are allowed.
bool userAllowedForEvents(UserPrivate? user) {
  if (user == null) return false;
  return user.isCoachOrAdmin;
}

/// Whether [user] may manage [event]: edit it, and reschedule, cancel or
/// undo the cancellation of its occurrences or its series.
///
/// An admin (including a super-admin) or the event's organizer. A coach
/// assigned to the event is not enough: the server's event-coach tier is
/// attendance only, and every event and occurrence mutation calls
/// `require_organizer_or_admin` (club_server `routers/events.py`,
/// `routers/occurrences.py`; club_core#146).
bool canManageEvent(Event event, UserPrivate user) =>
    user.isAdmin || user.username == event.organizerName;

/// Whether [user] may manage enrollment on [event]: invite, assign, assign
/// a trial, approve or reject a request, remove, and decide a withdrawal.
///
/// The same rule as [canManageEvent]: an assigned coach may read the
/// enrollment list but not change it (club_server attendance R7b,
/// enrollment R10; club_core#136).
bool canManageEnrollments(Event event, UserPrivate user) =>
    canManageEvent(event, user);
