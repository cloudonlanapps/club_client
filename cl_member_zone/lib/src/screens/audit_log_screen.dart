import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart' show AuditLogScope;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

import '../views/audit_log_view.dart';

/// Screen wrapper for [AuditLogView].
///
/// Owns route-level gating: the global feed requires a super-admin; an
/// entity scope requires an admin. On failure it renders a neutral
/// access-denied [ErrorView]. The host (router) builds the [scope] from the
/// path and supplies back navigation.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({
    required this.scope,
    required this.title,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final AuditLogScope scope;
  final String title;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    if (currentUser == null) {
      return const LoadingView(message: 'Loading…');
    }

    final allowed = scope.isGlobal
        ? currentUser.isSuperAdmin
        : currentUser.isAdmin;
    if (!allowed) {
      return ErrorView(
        tone: ErrorTone.neutral,
        icon: LucideIcons.shieldAlert,
        title: 'Access Denied',
        subtitle: 'You do not have permission to view this history.',
        onHome: onHome,
        onBack: onBack,
      );
    }

    return AuditLogView(
      currentUser: currentUser,
      scope: scope,
      title: title,
      onBack: onBack,
    );
  }
}
