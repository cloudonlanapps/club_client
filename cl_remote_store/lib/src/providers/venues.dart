import 'package:cl_remote_store/src/providers/venues_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter key for venue list queries.
typedef ClVenuesFilter = ({bool includeDeleted, String? searchTerm});

/// Filtered venue list provider.
///
/// Derives from [clVenuesMasterProvider] with client-side filtering.
/// No SDK calls — purely computed from master state.
///
/// Example:
/// ```dart
/// // Active venues only:
/// ref.watch(clVenuesProvider((includeDeleted: false, searchTerm: null)));
///
/// // All venues including deleted, with search:
/// ref.watch(clVenuesProvider((includeDeleted: true, searchTerm: 'rink')));
/// ```
final AutoDisposeFutureProviderFamily<List<Venue>, ClVenuesFilter>
clVenuesProvider = FutureProvider.autoDispose
    .family<List<Venue>, ClVenuesFilter>(
      (ref, filter) async {
        final venues = await ref.watch(clVenuesMasterProvider.future);
        var result = venues.values.toList();

        if (!filter.includeDeleted) {
          result = result.where((v) => v.isActive).toList();
        }

        final searchTerm = filter.searchTerm;
        if (searchTerm != null && searchTerm.isNotEmpty) {
          final lower = searchTerm.toLowerCase();
          result = result
              .where(
                (v) => v.name.toLowerCase().contains(lower),
              )
              .toList();
        }

        return result;
      },
    );
