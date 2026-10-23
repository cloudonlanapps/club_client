import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clVenueDetailProvider, venueImageProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons, ShadTheme;
import 'package:ui_lib/ui_lib.dart' show ContentPageHeroSection, LoadingView;

import '../widgets/venue_content.dart';

/// Member-zone view that loads a venue and renders [VenueContent].
class MemberVenueDetailView extends ConsumerWidget {
  const MemberVenueDetailView({
    required this.venueId,
    super.key,
  });

  final int venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueAsync = ref.watch(clVenueDetailProvider(venueId));

    return venueAsync.when(
      skipLoadingOnReload: true,
      loading: () => const LoadingView(),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Could not load venue: $error'),
          ],
        ),
      ),
      data: (venue) {
        final imageUri = ref.watch(venueImageProvider(venue.id)).valueOrNull;
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The hero draws nothing without an image, so a venue with
              // none gets a plain header (club_client#293).
              if (imageUri != null)
                ContentPageHeroSection(
                  title: venue.name,
                  description: venue.address,
                  imageUri: imageUri,
                  httpHeaders:
                      ref.watch(imageAuthHeadersProvider).valueOrNull ??
                      const {},
                  icon: LucideIcons.mapPin,
                )
              else
                _VenueHeader(name: venue.name, address: venue.address),
              VenueContent(
                description: venue.description,
                mapUri: venue.mapUri,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A venue's name and address, for a venue with no image.
class _VenueHeader extends StatelessWidget {
  const _VenueHeader({required this.name, this.address});

  final String name;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final address = this.address;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(name, style: theme.textTheme.h3),
          if (address != null && address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
                Expanded(
                  child: Text(address, style: theme.textTheme.muted),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
