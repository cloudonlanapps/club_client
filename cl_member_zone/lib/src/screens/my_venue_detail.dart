import 'package:cl_club_venues/cl_club_venues.dart' show MemberVenueDetailView;
import 'package:flutter/material.dart';

/// Screen wrapping [MemberVenueDetailView] for the member zone.
class MyVenueDetailScreen extends StatelessWidget {
  const MyVenueDetailScreen({
    required this.venueId,
    super.key,
  });

  final int venueId;

  @override
  Widget build(BuildContext context) {
    return MemberVenueDetailView(venueId: venueId);
  }
}
