import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cached_value.dart';
import '../models/date_items_key.dart';
import '../models/selected_occurrence.dart';
import 'date_items_notifier.dart';

/// Cached wrapper for date items notifier.
/// Preserves last good data during loading to prevent "flash of loading".
final AutoDisposeStateNotifierProviderFamily<
  CachedDateItemsNotifier,
  CachedValue<List<SelectedOccurrence>>,
  DateItemsKey
>
cachedDateItemsProvider = StateNotifierProvider.autoDispose
    .family<
      CachedDateItemsNotifier,
      CachedValue<List<SelectedOccurrence>>,
      DateItemsKey
    >(
      CachedDateItemsNotifier.new,
    );

/// StateNotifier that preserves date items data during loading and error
/// states.
class CachedDateItemsNotifier
    extends StateNotifier<CachedValue<List<SelectedOccurrence>>> {
  CachedDateItemsNotifier(this.ref, this.key)
    : super((data: null, error: null, isLoading: true)) {
    subscribe();
  }

  final Ref ref;
  final DateItemsKey key;

  void subscribe() {
    ref
      ..read(dateItemsNotifierProvider(key)).when(
        data: (items) => state = (data: items, error: null, isLoading: false),
        loading: () => state = (data: null, error: null, isLoading: true),
        error: (e, _) => state = (data: null, error: e, isLoading: false),
      )
      ..listen(dateItemsNotifierProvider(key), (_, next) {
        next.when(
          data: (items) => state = (data: items, error: null, isLoading: false),
          loading: () =>
              state = (data: state.data, error: null, isLoading: true),
          error: (e, _) =>
              state = (data: state.data, error: e, isLoading: false),
        );
      });
  }
}
