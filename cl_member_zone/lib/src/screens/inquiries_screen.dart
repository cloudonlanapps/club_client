import 'package:cl_club_admin/cl_club_admin.dart' show InquiriesView;
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen wrapper for [InquiriesView] (club_core#21), the admin inbox of the
/// public website's contact and interest forms.
///
/// Owns route-level gating through [RoleGate]: admins only, matching the
/// server.
class InquiriesScreen extends ConsumerWidget {
  const InquiriesScreen({required this.onHome, this.onBack, super.key});

  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.admin,
      onHome: onHome,
      onBack: onBack,
      deniedMessage: 'Only admins can read the inquiries inbox.',
      builder: (currentUser) {
        return InquiriesView(currentUser: currentUser, onBack: onBack);
      },
    );
  }
}
