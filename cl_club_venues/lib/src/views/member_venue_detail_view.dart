import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clVenueDetailProvider, venueImageProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
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
      data: (venue) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContentPageHeroSection(
              title: venue.name,
              description: venue.address,
              imageUri: ref.watch(venueImageProvider(venue.id)).valueOrNull,
              httpHeaders:
                  ref.watch(imageAuthHeadersProvider).valueOrNull ?? const {},
              icon: LucideIcons.mapPin,
            ),
            VenueContent(
              description: venue.description,
              mapUri: venue.mapUri,
            ),
          ],
        ),
      ),
    );
  }
}
