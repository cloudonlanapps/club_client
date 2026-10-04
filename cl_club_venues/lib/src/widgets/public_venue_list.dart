import 'package:club_sdk_2/club_sdk_2.dart' show PublicVenue;
import 'package:flutter/widgets.dart';

import 'cards/public_venue_card.dart';

/// The public venue list: one [PublicVenueCard] per venue.
class PublicVenueList extends StatelessWidget {
  const PublicVenueList({
    required this.venues,
    required this.onVenueTap,
    super.key,
  });

  /// Widest the list grows.
  static const double maxWidth = 1000;

  /// Gap below each card.
  static const double gap = 16;

  final List<PublicVenue> venues;

  /// Called with the tapped venue's public id.
  final ValueChanged<String> onVenueTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: Column(
        children: [
          for (final venue in venues)
            Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: PublicVenueCard(
                venue: venue,
                onTap: () => onVenueTap(venue.publicId),
              ),
            ),
        ],
      ),
    );
  }
}
