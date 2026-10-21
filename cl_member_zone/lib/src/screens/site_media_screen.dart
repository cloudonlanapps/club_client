import 'package:cl_club_admin/cl_club_admin.dart' show SiteMediaView;
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen wrapper for [SiteMediaView] (club_core#19), the public website's
/// media slots.
///
/// Owns route-level gating through [RoleGate]: super-admins only, matching
/// the server's preference endpoint.
class SiteMediaScreen extends ConsumerWidget {
  const SiteMediaScreen({required this.onHome, this.onBack, super.key});

  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.superAdmin,
      onHome: onHome,
      onBack: onBack,
      deniedMessage: 'Only super-admins can change the website media.',
      builder: (currentUser) {
        return SiteMediaView(currentUser: currentUser, onBack: onBack);
      },
    );
  }
}
