import 'package:cl_remote_store/cl_remote_store.dart'
    show clVenueDetailProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Compact icon + venue name line for use inside EventCard's `extra` slot.
///
/// Watches the venue master via [clVenueDetailProvider]; renders nothing
/// while loading or if the venue is missing from the master.
class EventVenueLine extends ConsumerWidget {
  const EventVenueLine({required this.venueId, super.key});

  final int venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final venueName = ref
        .watch(clVenueDetailProvider(venueId))
        .whenOrNull(data: (v) => v.name);
    if (venueName == null) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          LucideIcons.mapPin,
          size: 12,
          color: theme.colorScheme.mutedForeground,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            venueName,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
