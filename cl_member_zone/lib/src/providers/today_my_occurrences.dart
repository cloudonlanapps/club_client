import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'committed_event_ids.dart';
import 'selected_day.dart';

/// Occurrences for the My Events panel's selected day, restricted to events
/// the user is actively enrolled in.
///
/// The server's `/myevents/{username}/occurrences` returns occurrences for
/// both enrolled events **and** public events, and the response does not
/// carry per-occurrence enrollment status. To filter precisely on the client
/// we look up the user's enrollment for each unique `eventId`
/// ([committedEventIds]) and keep only the occurrences of events the user
/// is committed to.
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

  final committed = await committedEventIds(ref, username, [
    for (final o in occurrences) o.eventId,
  ]);

  return occurrences
      .where((o) => committed.contains(o.eventId))
      .toList(growable: false);
});
