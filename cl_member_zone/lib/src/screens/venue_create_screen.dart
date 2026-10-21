import 'package:cl_club_venues/cl_club_venues.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin screen wrapper around [VenueCreateView] for
/// `/memberzone/venues/new`.
class VenueCreateScreen extends ConsumerWidget {
  const VenueCreateScreen({
    required this.onCreated,
    required this.onCancel,
    required this.onHome,
    super.key,
  });

  final VoidCallback onCreated;
  final VoidCallback onCancel;

  /// Goes to the dashboard from a refusal. Supplied by the router.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.admin,
      onHome: onHome,
      builder: (_) => VenueCreateView(onCreated: onCreated, onCancel: onCancel),
    );
  }
}
