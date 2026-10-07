import 'event_staff_member.dart';

/// Picks a new organizer. Returns the chosen user, or `null` on cancel.
typedef PickOrganizer = Future<EventStaffMember?> Function();

/// Picks additional coaches, given the set of usernames to exclude (those
/// already staged). Returns the chosen users, or `null` on cancel.
typedef PickCoaches =
    Future<List<EventStaffMember>?> Function(Set<String> exclude);
