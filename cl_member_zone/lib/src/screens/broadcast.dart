import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView;

import '../theme/layout_constants.dart';
import '../widgets/panels/broadcast_panel_body.dart';

/// Full-width Broadcast screen reachable from the admin dashboard's
/// Announcement quick action. Hosts [BroadcastPanelBody] in its screen
/// presentation (all broadcasts, scrollable, Close button next to Send).
class BroadcastScreen extends ConsumerWidget {
  const BroadcastScreen({
    required this.onClose,
    required this.onHome,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final isAdmin = user.roles.isAdmin || user.isSuperAdmin;
    if (!isAdmin) {
      return ErrorView(
        tone: ErrorTone.neutral,
        icon: LucideIcons.shieldAlert,
        title: 'Access Denied',
        subtitle: 'You do not have permission to view this page.',
        onHome: onHome,
      );
    }

    return Padding(
      padding: LayoutConstants.contentPadding,
      child: BroadcastPanelBody(onClose: onClose),
    );
  }
}
