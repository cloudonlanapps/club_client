import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'selected_day.dart';

const Set<EnrollmentStatus> activeEnrollmentStatuses = {
  EnrollmentStatus.invited,
  EnrollmentStatus.accepted,
  EnrollmentStatus.assigned,
  EnrollmentStatus.assignedTrial,
  EnrollmentStatus.withdrawRequested,
};

/// Occurrences for the My Events panel's selected day, restricted to events
/// the user is actively enrolled in.
///
/// The server's `/myevents/{username}/occurrences` returns occurrences for
/// both enrolled events **and** public events, and the response does not
/// carry per-occurrence enrollment status. To filter precisely on the client
/// we look up the user's enrollment for each unique `eventId` via
/// [clMyEnrollmentProvider] and keep only the occurrences whose enrollment
/// exists and is in an active (non-terminal) state.
final FutureProviderFamily<List<Occurrence>, String>
todayMyOccurrencesProvider = FutureProvider.family<List<Occurrence>, String>((
  ref,
  username,
) async {
  final selected = ref.watch(selectedDayProvider);
  final from = startOfDayLocal(selected).toUtc();
  final to = endOfDayLocal(selected).toUtc();

  final occurrences = await ref.watch(
    clMyOccurrencesProvider((username: username, from: from, to: to)).future,
  );

  if (occurrences.isEmpty) return const <Occurrence>[];

  final eventIds = {for (final o in occurrences) o.eventId};
  final enrollments = await Future.wait([
    for (final id in eventIds)
      ref.watch(
        clMyEnrollmentProvider((username: username, eventId: id)).future,
      ),
  ]);

  final activeEventIds = <int>{
    for (var i = 0; i < eventIds.length; i++)
      if (enrollments[i] != null &&
          activeEnrollmentStatuses.contains(enrollments[i]!.status))
        eventIds.elementAt(i),
  };

  return occurrences
      .where((o) => activeEventIds.contains(o.eventId))
      .toList(growable: false);
});
