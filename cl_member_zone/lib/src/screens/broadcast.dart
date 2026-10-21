import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart' show BroadcastScope;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../views/broadcast_view.dart';

/// The one Broadcast screen, at `/memberzone/broadcast`, for every audience
/// (club_client#252). The router builds [scope] from the route's filter
/// (none: all members; `?group=`, `?event=`, `?member=`) and the message
/// icon of the dashboard, a group, an event or a member's profile opens it.
/// Admin only.
class BroadcastScreen extends ConsumerWidget {
  const BroadcastScreen({
    required this.scope,
    required this.onClose,
    required this.onHome,
    super.key,
  });

  /// The audience the screen sends to and lists.
  final BroadcastScope scope;

  final VoidCallback onClose;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.admin,
      onHome: onHome,
      onBack: onClose,
      builder: (user) =>
          BroadcastView(currentUser: user, scope: scope, onClose: onClose),
    );
  }
}
