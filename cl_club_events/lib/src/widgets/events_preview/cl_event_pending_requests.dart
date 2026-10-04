import 'package:cl_member_auth/cl_member_auth.dart' show canManageEnrollments;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEnrollmentsMasterProvider,
        clEventsMasterProvider,
        clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../buttons/enrollment_admin_action_bar.dart';
import '../enrollment_admin_handlers.dart';
import '../enrollment_tile.dart' show EnrollmentTile;

/// Preview of join-requests for an event, shown only to an admin or the
/// event's organizer (`canManageEnrollments`, club_core#136): the requests
/// are there to be approved or rejected, which an assigned coach may not.
///
/// Surfaces only enrollments with `EnrollmentStatus.requested` — the ones
/// that need admin action. The top-right icon opens the full
/// `EventEnrolmentsView`; the Assign / Invite / Assign-Trial buttons
/// trigger the same dialogs used in the manage view.
class ClEventPendingRequests extends ConsumerWidget {
  const ClEventPendingRequests({
    required this.eventId,
    required this.currentUser,
    this.onManageEnrolments,
    this.onMemberTap,
    this.listHeight = 320,
    super.key,
  });

  final int eventId;
  final UserPrivate currentUser;
  final ValueChanged<int>? onManageEnrolments;
  final ValueChanged<String>? onMemberTap;
  final double listHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(clEventsMasterProvider).valueOrNull?[eventId];
    if (event == null || !canManageEnrollments(event, currentUser)) {
      return const SizedBox.shrink();
    }

    final theme = ShadTheme.of(context);
    final pendingAsync = ref
        .watch(clEnrollmentsMasterProvider(eventId))
        .whenData(
          (e) => Map.fromEntries(
            e.entries.where(
              (entry) => entry.value == EnrollmentStatus.requested,
            ),
          ),
        );
    final userMap = ref.watch(clUsersMasterProvider).valueOrNull;
    final excludeUsernames = excludeUsernamesForEvent(eventId, ref);

    String resolveDisplayName(String username) {
      final user = userMap?[username];
      if (user == null) return username;
      final name = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
      return name.isEmpty ? username : name;
    }

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pendingAsync.when(
                    data: (e) => 'Pending requests (${e.length})',
                    loading: () => 'Pending requests',
                    error: (_, _) => 'Pending requests',
                  ),
                  style: theme.textTheme.h4,
                ),
              ),
              if (onManageEnrolments != null)
                IconButton(
                  onPressed: () => onManageEnrolments!(eventId),
                  tooltip: 'Manage enrollments',
                  icon: const Icon(LucideIcons.squareArrowOutUpRight, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          EnrollmentAdminActionBar(
            eventId: eventId,
            actingUser: currentUser,
            onAssign: () => handleAssignEnrollment(
              context,
              ref,
              eventId: eventId,
              excludeUsernames: excludeUsernames,
            ),
            onInvite: () => handleInviteEnrollment(
              context,
              ref,
              eventId: eventId,
              excludeUsernames: excludeUsernames,
            ),
          ),
          const SizedBox(height: 12),
          pendingAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Could not load enrollments: $e',
                style: theme.textTheme.muted,
              ),
            ),
            data: (pending) {
              if (pending.isEmpty) {
                return Text(
                  'No pending requests.',
                  style: theme.textTheme.muted,
                );
              }
              final entries = pending.entries.toList();
              return SizedBox(
                height: listHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final tile = EnrollmentTile(
                        username: entry.key,
                        status: entry.value,
                        eventId: eventId,
                        displayName: resolveDisplayName(entry.key),
                        canManage: true,
                      );
                      if (onMemberTap == null) return tile;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onMemberTap!(entry.key),
                        child: tile,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
