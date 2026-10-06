import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_list_filter.dart';

/// Filtered list of events, derived from [clEventsMasterProvider] and the
/// [EventListFilter] passed by the caller.
///
/// Each list-view instance keeps its own filter in widget state and passes
/// it as the family argument; instances do not share filter state.
final AsyncNotifierProviderFamily<
  EventListNotifier,
  List<Event>,
  EventListFilter
>
eventListProvider =
    AsyncNotifierProvider.family<
      EventListNotifier,
      List<Event>,
      EventListFilter
    >(
      EventListNotifier.new,
    );

class EventListNotifier
    extends FamilyAsyncNotifier<List<Event>, EventListFilter> {
  EventListFilter get filter => arg;

  @override
  Future<List<Event>> build(EventListFilter arg) async {
    final master = await ref.watch(clEventsMasterProvider.future);

    // Archived (soft-deleted) events are listed only when the filter asks
    // for them (club_client#36). The master map holds them for an admin,
    // and holds an event with deletedAtUtc set right after it is archived
    // (the notifier stores the server's echoed entity instead of dropping
    // the id), so a listing without them must filter them out.
    //
    // An event keeps one id across splits (club_core#16), so every event is
    // listed once.
    var events = master.values
        .where((e) => e.isActive || filter.showArchived)
        .toList();

    if (filter.eventType != null) {
      events = events.where((e) => e.type == filter.eventType).toList();
    }
    if (filter.visibility != null) {
      events = events.where((e) => e.visibility == filter.visibility).toList();
    }
    if (!filter.includePast) {
      final now = DateTime.now().toUtc();
      events = events
          .where(
            (e) =>
                e.status == EventStatus.active &&
                (e.endTimeUtc.isAfter(now) || isOpenEndedRecurring(e)),
          )
          .toList();
    }
    if (filter.searchTerm != null && filter.searchTerm!.isNotEmpty) {
      final term = filter.searchTerm!.toLowerCase();
      events = events
          .where((e) => e.title.toLowerCase().contains(term))
          .toList();
    }

    return events;
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
