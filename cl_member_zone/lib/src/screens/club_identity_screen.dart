import 'package:cl_club_admin/cl_club_admin.dart' show ClubIdentityView;
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

/// Screen wrapper for [ClubIdentityView] (club_core#20), the club's name,
/// inquiry email and public contact block.
///
/// Owns route-level gating: super-admins only, matching the server's
/// preference endpoint. Anyone else gets a neutral access-denied
/// [ErrorView].
class ClubIdentityScreen extends ConsumerWidget {
  const ClubIdentityScreen({required this.onHome, this.onBack, super.key});

  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    if (currentUser == null) {
      return const LoadingView(message: 'Loading…');
    }
    if (!currentUser.isSuperAdmin) {
      return ErrorView(
        tone: ErrorTone.neutral,
        icon: LucideIcons.shieldAlert,
        title: 'Access Denied',
        subtitle: 'Only super-admins can change the club details.',
        onHome: onHome,
        onBack: onBack,
      );
    }
    return ClubIdentityView(currentUser: currentUser, onBack: onBack);
  }
}
