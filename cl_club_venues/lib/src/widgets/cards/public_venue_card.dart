import 'package:cl_remote_store/cl_remote_store.dart'
    show clPublicMediaUrlProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show PublicVenue;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/venue_badge_labels.dart';
import 'venue_display_card.dart';

/// The venue card for a [PublicVenue] — the public website's venue list.
///
/// The member list's card (`VenueDisplayCard`) on the public projection: the
/// venue's public photo, name, address, description preview and badges. The
/// default venue's badge is the server's own `primaryVenueBadge` text.
class PublicVenueCard extends ConsumerWidget {
  const PublicVenueCard({required this.venue, this.onTap, super.key});

  final PublicVenue venue;

  /// Whole-row tap. The host wires this to the venue page.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultBadge = venue.primaryVenueBadge;
    return VenueDisplayCard(
      name: venue.name,
      address: venue.address,
      description: venue.description,
      imageUrl: ref.watch(clPublicMediaUrlProvider)(venue.image),
      badges: [
        if (defaultBadge != null && defaultBadge.isNotEmpty) defaultBadge,
        if (venue.isFeatured) VenueBadgeLabels.featured,
      ],
      onTap: onTap,
    );
  }
}
