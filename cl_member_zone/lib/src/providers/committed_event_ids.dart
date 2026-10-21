import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enrollment statuses that commit the user to an event: its occurrences
/// belong in My Events, and not in Public Events.
const Set<EnrollmentStatus> committedEnrollmentStatuses = {
  EnrollmentStatus.invited,
  EnrollmentStatus.accepted,
  EnrollmentStatus.assigned,
  EnrollmentStatus.assignedTrial,
  EnrollmentStatus.withdrawRequested,
};

/// Of [eventIds], the events [username] is committed to, by their
/// enrollment ([clMyEnrollmentProvider]; none, `requested` and the
/// terminal statuses are not committed). Watches each enrollment through
/// [ref], so the caller rebuilds when one changes.
Future<Set<int>> committedEventIds(
  Ref ref,
  String username,
  Iterable<int> eventIds,
) async {
  final ids = eventIds.toSet().toList(growable: false);
  final enrollments = await Future.wait([
    for (final id in ids)
      ref.watch(
        clMyEnrollmentProvider((username: username, eventId: id)).future,
      ),
  ]);
  return {
    for (final (i, id) in ids.indexed)
      if (committedEnrollmentStatuses.contains(enrollments[i]?.status)) id,
  };
}
