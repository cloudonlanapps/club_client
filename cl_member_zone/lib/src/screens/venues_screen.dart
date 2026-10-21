import 'package:cl_club_venues/cl_club_venues.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:club_sdk_2/club_sdk_2.dart' show Venue;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin screen wrapper around [VenueListView] for `/memberzone/venues`.
class VenuesScreen extends ConsumerWidget {
  const VenuesScreen({
    required this.onVenueTap,
    required this.onCreateVenue,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final ValueChanged<Venue> onVenueTap;
  final VoidCallback onCreateVenue;
  final VoidCallback? onBack;

  /// Goes to the dashboard from a refusal. Supplied by the router.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.coachOrAdmin,
      onHome: onHome,
      builder: (_) => VenueListView(
        onVenueTap: onVenueTap,
        onCreateVenue: onCreateVenue,
        onBack: onBack,
      ),
    );
  }
}
