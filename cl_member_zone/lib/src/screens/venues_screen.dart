import 'package:cl_club_venues/cl_club_venues.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show Venue;
import 'package:flutter/material.dart';

/// Thin screen wrapper around [VenueListView] for `/memberzone/venues`.
class VenuesScreen extends StatelessWidget {
  const VenuesScreen({
    required this.onVenueTap,
    required this.onCreateVenue,
    this.onBack,
    super.key,
  });

  final ValueChanged<Venue> onVenueTap;
  final VoidCallback onCreateVenue;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return VenueListView(
      onVenueTap: onVenueTap,
      onCreateVenue: onCreateVenue,
      onBack: onBack,
    );
  }
}
