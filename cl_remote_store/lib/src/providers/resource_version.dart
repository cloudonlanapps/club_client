import 'package:cl_remote_store/src/models/resource_version_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared version state for date-range query invalidation.
///
/// Masters bump specific versions after mutations. Read-only providers
/// watch specific versions via `.select()` and refetch when bumped.
///
/// Example:
/// ```dart
/// // Master bumps after occurrence mutation:
/// final current = ref.read(clResourceVersionProvider);
/// ref.read(clResourceVersionProvider.notifier).state = current.copyWith(
///   occurrencesVersion: current.occurrencesVersion + 1,
/// );
///
/// // Read-only provider watches:
/// ref.watch(clResourceVersionProvider.select((s) => s.occurrencesVersion));
/// ```
final StateProvider<ResourceVersionState> clResourceVersionProvider =
    StateProvider<ResourceVersionState>(
      (ref) => const ResourceVersionState(),
    );
