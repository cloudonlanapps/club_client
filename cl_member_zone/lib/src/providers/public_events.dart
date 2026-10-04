import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'selected_day.dart';

/// Enrollment statuses that mean the user is committed to attending an
/// event — events with one of these are surfaced in My Events instead.
const Set<EnrollmentStatus> committedEnrollmentStatuses = {
  EnrollmentStatus.invited,
  EnrollmentStatus.accepted,
  EnrollmentStatus.assigned,
  EnrollmentStatus.assignedTrial,
  EnrollmentStatus.withdrawRequested,
};

/// Future occurrences for the Public Events panel's selected day, limited to
/// public events the user has not yet committed to.
///
/// Mirrors `todayMyOccurrencesProvider` for the My Events panel: filters
/// `clMyOccurrencesProvider` by:
///   - the underlying event has `visibility == public` (looked up via
///     `clMyEventsMasterProvider`),
///   - the user has no committed enrollment for the event (terminal /
///     `requested` / null all pass),
///   - the occurrence has not yet ended (no past public occurrences).
///
/// Endpoint dependency: the public-events list is derived from
/// `clMyEventsMasterProvider`, which is backed by
/// `GET /v1/myevents/by_id/{username}`. The server filters out public
/// events the user is ineligible for (per structured criteria) and has
/// no enrollment on. As a result the Public Events panel automatically
/// hides ineligible events without any additional client-side filtering;
/// enrolled events the user is no longer eligible for stay visible
/// (grandfathered) and are surfaced via the My Events panel instead.
final FutureProviderFamily<List<Occurrence>, String>
todayPublicOccurrencesProvider =
    FutureProvider.family<List<Occurrence>, String>((ref, username) async {
      final selected = ref.watch(selectedDayProvider);
      final from = startOfDayLocal(selected).toUtc();
      final to = endOfDayLocal(selected).toUtc();

      final occurrences = await ref.watch(
        clMyOccurrencesProvider((
          username: username,
          from: from,
          to: to,
        )).future,
      );
      if (occurrences.isEmpty) return const <Occurrence>[];

      final events = await ref.watch(clMyEventsMasterProvider(username).future);
      final publicEventIds = <int>{
        for (final e in events)
          if (e.visibility == Visibility.public) e.id,
      };
      if (publicEventIds.isEmpty) return const <Occurrence>[];

      final now = DateTime.now().toUtc();
      final candidates = occurrences
          .where(
            (o) =>
                publicEventIds.contains(o.eventId) &&
                o.actualEndTimeUtc.isAfter(now),
          )
          .toList();
      if (candidates.isEmpty) return const <Occurrence>[];

      final candidateEventIds = {for (final o in candidates) o.eventId};
      final enrollments = await Future.wait([
        for (final id in candidateEventIds)
          ref.watch(
            clMyEnrollmentProvider((username: username, eventId: id)).future,
          ),
      ]);
      final committedEventIds = <int>{
        for (var i = 0; i < candidateEventIds.length; i++)
          if (enrollments[i] != null &&
              committedEnrollmentStatuses.contains(enrollments[i]!.status))
            candidateEventIds.elementAt(i),
      };

      return candidates
          .where((o) => !committedEventIds.contains(o.eventId))
          .toList(growable: false);
    });
