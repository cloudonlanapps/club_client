import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manual refresh counter.
///
/// Every server-reading provider in this package watches this counter and
/// rebuilds when it changes. Bumping the counter (via [bumpManualRefresh])
/// forces a coordinated refetch across all domain resources without
/// invalidating providers individually.
final StateProvider<int> clManualRefreshProvider = StateProvider<int>(
  (ref) => 0,
);

/// Increment the manual refresh counter. Wires up to the top-bar refresh
/// button in the app shell.
void bumpManualRefresh(WidgetRef ref) {
  final current = ref.read(clManualRefreshProvider);
  ref.read(clManualRefreshProvider.notifier).state = current + 1;
}
