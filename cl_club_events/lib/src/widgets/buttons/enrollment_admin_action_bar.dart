import 'package:cl_member_auth/cl_member_auth.dart' show canManageEnrollments;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Assign More / Invite More / Assign Trial for one event, offered only to
/// an admin or the event's organizer (`canManageEnrollments`, club_core#136)
/// while the event is still open for enrollment (`canEnrollOnEvent`).
class EnrollmentAdminActionBar extends ConsumerWidget {
  const EnrollmentAdminActionBar({
    required this.eventId,
    required this.actingUser,
    required this.onAssign,
    required this.onInvite,
    this.onAssignTrial,
    super.key,
  });

  final int eventId;
  final UserPrivate actingUser;
  final VoidCallback onAssign;
  final VoidCallback onInvite;

  /// Opens the Assign Trial picker (club_core#114). Offered only where the
  /// acting user may assign a trial (`canAssignTrial`: programmes).
  final VoidCallback? onAssignTrial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(clEventDetailProvider(eventId));
    final event = eventAsync.valueOrNull;
    if (event == null) return const SizedBox.shrink();
    if (!canManageEnrollments(event, actingUser) ||
        !canEnrollOnEvent(event, actingUser)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: onAssign,
            leading: const Icon(LucideIcons.userPlus, size: 14),
            child: const Text('Assign More…'),
          ),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: onInvite,
            leading: const Icon(LucideIcons.send, size: 14),
            child: const Text('Invite More…'),
          ),
          if (onAssignTrial != null && canAssignTrial(event, actingUser))
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: onAssignTrial,
              leading: const Icon(LucideIcons.flaskConical, size: 14),
              child: const Text('Assign Trial…'),
            ),
        ],
      ),
    );
  }
}
