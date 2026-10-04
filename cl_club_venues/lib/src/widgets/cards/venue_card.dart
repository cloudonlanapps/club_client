import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clVenuesMasterProvider, venueImageProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show EntityCard, EntityImage;

import '../../models/venue_badge_labels.dart';
import 'venue_display_card.dart';

/// List-row card for a single venue.
///
/// Caller passes only [venueId] and an [onTap] callback. The card resolves
/// the venue from `clVenuesMasterProvider` and renders it as a
/// [VenueDisplayCard]. Edit and delete affordances live on the venue
/// profile, not the list card.
///
/// When the venue is loading or has been deleted from the master, the card
/// renders a placeholder with the bare ID — callers do not need to gate on
/// availability.
class VenueCard extends ConsumerWidget {
  const VenueCard({
    required this.venueId,
    this.onTap,
    super.key,
  });

  final int venueId;

  /// Whole-row tap. The host wires this to the venue profile view.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venue = ref.watch(clVenuesMasterProvider).valueOrNull?[venueId];
    if (venue == null) {
      return EntityCard(
        image: EntityImage.placeholder(),
        title: 'Venue #$venueId',
        onTap: onTap,
      );
    }

    return VenueDisplayCard(
      name: venue.name,
      address: venue.address,
      description: venue.description,
      imageUrl: ref.watch(venueImageProvider(venueId)).value,
      httpHeaders: ref.watch(imageAuthHeadersProvider).value ?? const {},
      badges: [
        if (venue.isDefault) VenueBadgeLabels.defaultVenue,
        if (venue.isFeatured) VenueBadgeLabels.featured,
      ],
      onTap: onTap,
    );
  }
}
