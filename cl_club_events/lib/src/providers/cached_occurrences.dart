import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cached_value.dart';
import '../models/range_occurrences_key.dart';

/// Cached wrapper for the staff occurrence feed ([clOccurrencesProvider]),
/// which covers the event types the club runs.
/// Preserves last good data during loading to prevent "flash of loading".
final AutoDisposeStateNotifierProviderFamily<
  CachedOccurrencesNotifier,
  CachedValue<List<Occurrence>>,
  RangeOccurrencesKey
>
cachedOccurrencesProvider = StateNotifierProvider.autoDispose
    .family<
      CachedOccurrencesNotifier,
      CachedValue<List<Occurrence>>,
      RangeOccurrencesKey
    >(
      CachedOccurrencesNotifier.new,
    );

/// StateNotifier that preserves occurrences data during loading and error
/// states.
class CachedOccurrencesNotifier
    extends StateNotifier<CachedValue<List<Occurrence>>> {
  CachedOccurrencesNotifier(this.ref, this.key)
    : super((data: null, error: null, isLoading: true)) {
    subscribe();
  }

  final Ref ref;
  final RangeOccurrencesKey key;

  ClOccurrencesKey get _occKey => (
    from: key.range.start,
    to: key.range.end,
  );

  void subscribe() {
    // Read initial state immediately
    ref
      ..read(clOccurrencesProvider(_occKey)).when(
        data: (list) => state = (data: list, error: null, isLoading: false),
        loading: () => state = (data: null, error: null, isLoading: true),
        error: (e, _) => state = (data: null, error: e, isLoading: false),
      )
      // Listen for future changes
      ..listen(clOccurrencesProvider(_occKey), (_, next) {
        next.when(
          data: (list) => state = (data: list, error: null, isLoading: false),
          loading: () =>
              state = (data: state.data, error: null, isLoading: true),
          error: (e, _) =>
              state = (data: state.data, error: e, isLoading: false),
        );
      });
  }
}
