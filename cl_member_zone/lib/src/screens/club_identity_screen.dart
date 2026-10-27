import 'package:cl_club_admin/cl_club_admin.dart' show ClubIdentityView;
import 'package:cl_club_applications/cl_club_applications.dart'
    show ApplicationLabelsSection, ApplicationLibrarySection;
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen wrapper for [ClubIdentityView] (club_core#20), the club's name,
/// inquiry email and public contact block.
///
/// Owns route-level gating through [RoleGate]: super-admins only, matching
/// the server's preference endpoint.
class ClubIdentityScreen extends ConsumerWidget {
  const ClubIdentityScreen({required this.onHome, this.onBack, super.key});

  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.superAdmin,
      onHome: onHome,
      onBack: onBack,
      deniedMessage: 'Only super-admins can change the club details.',
      builder: (currentUser) {
        return ClubIdentityView(
          currentUser: currentUser,
          onBack: onBack,
          librarySection: const ApplicationLibrarySection(),
          labelsSection: const ApplicationLabelsSection(),
        );
      },
    );
  }
}
