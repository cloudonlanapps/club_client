import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show MapEmbed;

/// Venue section for the event detail preview.
///
/// Renders the venue name (optionally tappable), the address line when
/// present, and an embedded Google Maps preview when [Venue.mapUri] is
/// set. Falls back to the plain name row when neither a venue nor a
/// `mapUri` is available.
class ClEventVenueDetail extends StatelessWidget {
  const ClEventVenueDetail({
    required this.venueId,
    this.venue,
    this.onVenueTap,
    this.mapHeight = 200,
    super.key,
  });

  final int venueId;
  final Venue? venue;
  final ValueChanged<int>? onVenueTap;
  final double mapHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadTheme = ShadTheme.of(context);
    final displayName = venue?.name ?? 'Venue #$venueId';
    final address = venue?.address;
    final mapUri = venue?.mapUri;

    final header = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onVenueTap == null ? null : () => onVenueTap!(venueId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.place_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: theme.textTheme.titleMedium),
                  if (address != null && address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(address, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final body = (mapUri == null || mapUri.isEmpty)
        ? header
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 8),
              MapEmbed(mapUri: mapUri, height: mapHeight),
            ],
          );

    return ShadCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Venue', style: shadTheme.textTheme.h4),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }
}
