import 'package:club_sdk_2/club_sdk_2.dart' show PublicVenue;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show MapEmbed;

class PublicEventVenueMapSection extends StatelessWidget {
  const PublicEventVenueMapSection({required this.venue, super.key});
  final PublicVenue venue;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(venue.name, style: theme.textTheme.h4),
                ],
              ),
              const SizedBox(height: 16),
              MapEmbed(mapUri: venue.mapUri!, height: isMobile ? 300 : 400),
            ],
          ),
        ),
      ),
    );
  }
}
