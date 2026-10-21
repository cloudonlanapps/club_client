import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/date_items_key.dart';
import '../models/selected_occurrence.dart';
import 'event_notifier.dart';

/// Family provider for date items notifier.
/// Combines occurrences and events for a specific date.
final AutoDisposeAsyncNotifierProviderFamily<
  DateItemsNotifier,
  List<SelectedOccurrence>,
  DateItemsKey
>
dateItemsNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<DateItemsNotifier, List<SelectedOccurrence>, DateItemsKey>(
      DateItemsNotifier.new,
    );

/// AsyncNotifier that combines occurrences and events for a specific date.
/// Watches both [clOccurrencesProvider] (the event types the club runs) and
/// [eventNotifierProvider] to build a reactive list of (Occurrence, Event)
/// tuples for the given date.
class DateItemsNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<List<SelectedOccurrence>, DateItemsKey> {
  /// Key is available via [arg] property from Riverpod family notifier.
  DateItemsKey get key => arg;

  @override
  Future<List<SelectedOccurrence>> build(DateItemsKey key) async {
    return buildDateItems();
  }

  Future<List<SelectedOccurrence>> buildDateItems() async {
    final occKey = (
      from: key.range.start,
      to: key.range.end,
    );

    // Watch occurrences for the range
    final occurrences = await ref.watch(clOccurrencesProvider(occKey).future);

    // Filter to only occurrences on this specific date
    final dateOnly = DateUtils.dateOnly(key.date);
    final dateOccurrences = occurrences.where((occ) {
      return DateUtils.dateOnly(occ.actualStartTimeUtc) == dateOnly;
    }).toList();

    // Fetch corresponding events - watching each event individually
    final items = <SelectedOccurrence>[];

    for (final occ in dateOccurrences) {
      try {
        final event = await ref.watch(
          eventNotifierProvider(occ.eventId).future,
        );
        items.add((occ, event));
      } on Object {
        // Skip occurrences where event fetch fails
        continue;
      }
    }

    // Sort by start time
    items.sort(
      (a, b) => a.$1.actualStartTimeUtc.compareTo(b.$1.actualStartTimeUtc),
    );

    return items;
  }
}
