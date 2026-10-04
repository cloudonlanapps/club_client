import 'package:cl_club_admin/cl_club_admin.dart' show InquiriesView;
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

/// Screen wrapper for [InquiriesView] (club_core#21), the admin inbox of the
/// public website's contact and interest forms.
///
/// Owns route-level gating: admins only, matching the server. Anyone else
/// gets a neutral access-denied [ErrorView].
class InquiriesScreen extends ConsumerWidget {
  const InquiriesScreen({required this.onHome, this.onBack, super.key});

  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    if (currentUser == null) {
      return const LoadingView(message: 'Loading…');
    }
    if (!currentUser.isAdmin) {
      return ErrorView(
        tone: ErrorTone.neutral,
        icon: LucideIcons.shieldAlert,
        title: 'Access Denied',
        subtitle: 'Only admins can read the inquiries inbox.',
        onHome: onHome,
        onBack: onBack,
      );
    }
    return InquiriesView(currentUser: currentUser, onBack: onBack);
  }
}
