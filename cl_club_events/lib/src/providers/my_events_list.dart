import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/my_events_list_filter.dart';

/// Filtered list of aggregated events for the My Events dashboard.
///
/// The host view owns its own [MyEventsListFilter] and passes it as the
/// family argument; instances do not share filter state.
final AsyncNotifierProviderFamily<
  MyEventsListNotifier,
  List<AggregatedMyEvent>,
  MyEventsListFilter
>
myEventsListProvider =
    AsyncNotifierProvider.family<
      MyEventsListNotifier,
      List<AggregatedMyEvent>,
      MyEventsListFilter
    >(
      MyEventsListNotifier.new,
    );

class MyEventsListNotifier
    extends FamilyAsyncNotifier<List<AggregatedMyEvent>, MyEventsListFilter> {
  MyEventsListFilter get filter => arg;

  @override
  Future<List<AggregatedMyEvent>> build(MyEventsListFilter arg) async {
    if (filter.selectedUsernames.isEmpty) return [];

    final aggregated = await ref.watch(
      clMyEventsAggregatedProvider(filter.selectedUsernames).future,
    );

    var results = aggregated.toList();

    // Filter out past events unless includePast is set.
    if (!filter.includePast) {
      final now = DateTime.now().toUtc();
      results = results
          .where(
            (a) =>
                a.event.status == EventStatus.active &&
                (a.event.endTimeUtc.isAfter(now) ||
                    isOpenEndedRecurring(a.event)),
          )
          .toList();
    }

    // Apply search filter on title and description.
    if (filter.searchTerm != null && filter.searchTerm!.isNotEmpty) {
      final term = filter.searchTerm!.toLowerCase();
      results = results
          .where(
            (a) =>
                a.event.title.toLowerCase().contains(term) ||
                a.event.description.toLowerCase().contains(term),
          )
          .toList();
    }

    return results;
  }

  /// Re-fetch all event data from the server.
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Returns true if the event has an open-ended recurrence rule
/// (RRULE with no COUNT and no UNTIL), meaning it recurs indefinitely.
bool isOpenEndedRecurring(Event e) {
  final rrule = e.rrule;
  if (rrule == null) return false;
  return !rrule.contains('COUNT') && !rrule.contains('UNTIL');
}
