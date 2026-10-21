import 'package:cl_remote_store/src/providers/venues_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single venue detail, keyed by venue ID.
///
/// A synchronous select of [clVenuesMasterProvider]'s entry for the venue:
/// a write to the master arrives here as data, never as a reload, so a page
/// built on it keeps its state while one section saves (club_client#229).
/// The master's own loading and error pass through. A venue absent from the
/// master is a `StateError('Venue X not found in master')`.
final AutoDisposeProviderFamily<AsyncValue<Venue>, int> clVenueDetailProvider =
    Provider.autoDispose.family<AsyncValue<Venue>, int>((ref, venueId) {
      final entry = ref.watch(
        clVenuesMasterProvider.select((s) => s.whenData((m) => m[venueId])),
      );
      return entry.whenData(
        (venue) =>
            venue ?? (throw StateError('Venue $venueId not found in master')),
      );
    });
