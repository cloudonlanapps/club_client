import 'package:cl_club_venues/cl_club_venues.dart';
import 'package:flutter/material.dart';

/// Thin screen wrapper around [VenueCreateView] for
/// `/memberzone/venues/new`.
class VenueCreateScreen extends StatelessWidget {
  const VenueCreateScreen({
    required this.onCreated,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onCreated;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return VenueCreateView(onCreated: onCreated, onCancel: onCancel);
  }
}
