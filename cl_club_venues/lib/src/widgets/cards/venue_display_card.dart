import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart' show EntityCard, EntityImage;

import 'venue_card_body.dart';

/// The venue list-row card, on display fields.
///
/// One design for every venue list: the member card (`VenueCard`, which
/// resolves a venue id) and the public card (`PublicVenueCard`, over a
/// `PublicVenue`) both render through this — an `EntityCard` with the venue's
/// photo (or the placeholder), its name and address, and a body of
/// description preview and badges.
class VenueDisplayCard extends StatelessWidget {
  const VenueDisplayCard({
    required this.name,
    this.address,
    this.description,
    this.imageUrl,
    this.httpHeaders = const {},
    this.badges = const [],
    this.onTap,
    super.key,
  });

  final String name;
  final String? address;

  /// The venue's description, as markdown; the card previews its lead
  /// paragraph.
  final String? description;

  /// The venue photo, or `null` for the placeholder.
  final String? imageUrl;

  /// Headers for [imageUrl] when it is auth-protected.
  final Map<String, String> httpHeaders;

  /// Badge labels, in order.
  final List<String> badges;

  /// Whole-row tap.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return EntityCard(
      image: url != null
          ? EntityImage.network(url, httpHeaders: httpHeaders)
          : EntityImage.placeholder(),
      title: name,
      caption: address,
      body: VenueCardBody(description: description, badges: badges),
      onTap: onTap,
    );
  }
}
