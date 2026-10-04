import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Displays created and updated timestamps for a venue.
class VenueTimestamps extends StatelessWidget {
  const VenueTimestamps({required this.venue, super.key});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final mutedStyle = theme.textTheme.muted.copyWith(fontSize: 12);

    return Row(
      children: [
        Icon(
          LucideIcons.clock,
          size: 12,
          color: theme.colorScheme.mutedForeground,
        ),
        const SizedBox(width: 6),
        Text(
          'Created ${venue.createdAtUtc.toLocalDateMedium()}',
          style: mutedStyle,
        ),
        const SizedBox(width: 16),
        Text(
          'Updated ${venue.updatedAtUtc.toLocalDateMedium()}',
          style: mutedStyle,
        ),
      ],
    );
  }
}
