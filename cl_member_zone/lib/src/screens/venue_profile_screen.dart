import 'package:cl_club_venues/cl_club_venues.dart';
import 'package:flutter/material.dart';

/// Thin screen wrapper around [VenueProfileView] for
/// `/memberzone/venues/:id`.
class VenueProfileScreen extends StatelessWidget {
  const VenueProfileScreen({
    required this.venueId,
    required this.onDeleted,
    this.onBack,
    this.onHistory,
    super.key,
  });

  final int venueId;
  final VoidCallback onDeleted;
  final VoidCallback? onBack;
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) {
    return VenueProfileView(
      venueId: venueId,
      onDeleted: onDeleted,
      onBack: onBack,
      onHistory: onHistory,
    );
  }
}
