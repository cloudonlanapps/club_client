import 'package:cl_remote_store/src/providers/venues_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single venue detail, keyed by venue ID.
///
/// Derives from [clVenuesMasterProvider] — selects a single venue from
/// the master map. Throws if the venue is not in the master.
final AutoDisposeFutureProviderFamily<Venue, int> clVenueDetailProvider =
    FutureProvider.autoDispose.family<Venue, int>(
      (ref, venueId) async {
        final venues = await ref.watch(clVenuesMasterProvider.future);
        final venue = venues[venueId];
        if (venue == null) {
          throw StateError('Venue $venueId not found in master');
        }
        return venue;
      },
    );
