import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:cl_remote_store/cl_remote_store.dart' show AuditLogScope;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../views/audit_log_view.dart';

/// Screen wrapper for [AuditLogView].
///
/// Owns route-level gating through [RoleGate]: the global feed requires a
/// super-admin; an entity scope requires an admin. The host (router) builds
/// the [scope] from the path and supplies back navigation.
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
    return RoleGate(
      allow: scope.isGlobal ? RoleGate.superAdmin : RoleGate.admin,
      onHome: onHome,
      onBack: onBack,
      deniedMessage: 'You do not have permission to view this history.',
      builder: (currentUser) => AuditLogView(
        currentUser: currentUser,
        scope: scope,
        title: title,
        onBack: onBack,
      ),
    );
  }
}
