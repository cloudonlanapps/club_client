import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for all venue data.
///
/// Holds the canonical `Map<int, Venue>` state. All venue mutations
/// go through this notifier. Widgets and derived providers watch this
/// for venue data.
final AsyncNotifierProvider<ClVenuesMasterNotifier, Map<int, Venue>>
clVenuesMasterProvider =
    AsyncNotifierProvider<ClVenuesMasterNotifier, Map<int, Venue>>(
      ClVenuesMasterNotifier.new,
    );

/// Notifier managing all venue state and mutations.
class ClVenuesMasterNotifier extends AsyncNotifier<Map<int, Venue>> {
  @override
  Future<Map<int, Venue>> build() async {
    ref.watch(clManualRefreshProvider);
    final client = await ref.watch(secureClientProvider.future);
    final items = await fetchAllPages(
      client.venues.getVenues,
    );
    return {for (final v in items) v.id: v};
  }

  /// Create a new venue.
  Future<Venue> createVenue({
    required String name,
    bool isDefault = false,
    String? address,
    String? description,
    String? mapUri,
    bool isFeatured = false,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final created = await client.venues.createVenue(
        name: name,
        isDefault: isDefault,
        address: address,
        description: description,
        mapUri: mapUri,
        isFeatured: isFeatured,
      );

      replaceLocally(created);
      return created;
    }, refetch: ref.invalidateSelf);
  }

  /// Update a venue. Uses ValueGetter pattern for nullable fields.
  Future<Venue> updateVenue(
    int id, {
    String? name,
    bool? isDefault,
    String? Function()? address,
    String? Function()? description,
    String? Function()? mapUri,
    bool? isFeatured,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.venues.updateVenue(
        id,
        name: name,
        isDefault: isDefault,
        address: address,
        description: description,
        mapUri: mapUri,
        isFeatured: isFeatured,
      );

      replaceLocally(updated);
      return updated;
    }, refetch: ref.invalidateSelf);
  }

  /// Soft-delete a venue.
  ///
  /// The server echoes the soft-deleted venue (with `deletedAtUtc` set), so
  /// the local map is updated from that response rather than blindly
  /// dropping the id. A blind removal would hide whether the server actually
  /// persisted the delete; keeping the inactive venue in the map means
  /// derived views (which filter on `isActive`) reflect true server state.
  Future<void> deleteVenue(int id) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final deleted = await client.venues.deleteVenue(id);
      replaceLocally(deleted);
    }, refetch: ref.invalidateSelf);
  }

  /// Restore a soft-deleted venue.
  Future<Venue> restoreVenue(int id) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final restored = await client.venues.restoreVenue(id);
      replaceLocally(restored);
      return restored;
    }, refetch: ref.invalidateSelf);
  }

  /// Permanently delete a venue (super admin only).
  Future<void> hardDeleteVenue(int id) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.venues.hardDeleteVenue(id);
      removeLocally(id);
    }, refetch: ref.invalidateSelf);
  }

  /// Replace or add a venue in the local map.
  void replaceLocally(Venue venue) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData({...current, venue.id: venue});
  }

  /// Remove a venue from the local map.
  void removeLocally(int id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(Map.of(current)..remove(id));
  }
}
