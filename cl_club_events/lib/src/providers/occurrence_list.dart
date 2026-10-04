import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Date range for occurrence queries.
final occurrenceDateRangeProvider =
    StateProvider<({DateTime from, DateTime to})>(
      (ref) {
        final now = DateTime.now().toUtc();
        final today = DateTime.utc(now.year, now.month, now.day);
        return (from: today, to: today.add(const Duration(days: 1)));
      },
    );

/// List of occurrences for the selected date range.
///
/// Watches [occurrenceDateRangeProvider] and derives from
/// [clOccurrencesProvider] in `cl_remote_store`.
final occurrenceListProvider =
    AsyncNotifierProvider<OccurrenceListNotifier, List<Occurrence>>(
      OccurrenceListNotifier.new,
    );

class OccurrenceListNotifier extends AsyncNotifier<List<Occurrence>> {
  @override
  Future<List<Occurrence>> build() async {
    final range = ref.watch(occurrenceDateRangeProvider);
    return ref.watch(clOccurrencesProvider(range).future);
  }

  Future<void> refresh() async {
    final range = ref.read(occurrenceDateRangeProvider);
    ref.invalidate(clOccurrencesProvider(range));
  }
}
