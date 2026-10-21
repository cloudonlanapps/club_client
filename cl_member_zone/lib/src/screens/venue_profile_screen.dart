import 'package:cl_club_venues/cl_club_venues.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin screen wrapper around [VenueProfileView] for
/// `/memberzone/venues/:id`.
class VenueProfileScreen extends ConsumerWidget {
  const VenueProfileScreen({
    required this.venueId,
    required this.onDeleted,
    required this.onHome,
    this.onBack,
    this.onHistory,
    super.key,
  });

  final int venueId;
  final VoidCallback onDeleted;
  final VoidCallback? onBack;
  final VoidCallback? onHistory;

  /// Goes to the dashboard from a refusal. Supplied by the router.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.coachOrAdmin,
      onHome: onHome,
      builder: (_) => VenueProfileView(
        venueId: venueId,
        onDeleted: onDeleted,
        onBack: onBack,
        onHistory: onHistory,
      ),
    );
  }
}
