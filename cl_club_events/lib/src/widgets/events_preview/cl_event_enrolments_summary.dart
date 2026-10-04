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

import '../../models/enrollment_category.dart';
import '../enrollment_tile.dart' show EnrollmentTile;

/// Admin/coach-only summary of *active* enrolments for an event.
///
/// Mirrors `ClEventPendingRequests` but filters the master to the
/// `active` category (`assigned`, `accepted`, `assignedTrial`). Shows
/// the first [previewLimit] rows with a "+N more" hint when truncated;
/// the heading icon opens the full `EventEnrolmentsView` via
/// [onManageEnrolments]. Staff may read it; the row actions show only to
/// an admin or the event's organizer (`canManageEnrollments`,
/// club_core#136).
class ClEventEnrolmentsSummary extends ConsumerWidget {
  const ClEventEnrolmentsSummary({
    required this.eventId,
    required this.currentUser,
    this.onManageEnrolments,
    this.onMemberTap,
    this.previewLimit = 5,
    super.key,
  });

  final int eventId;
  final UserPrivate currentUser;
  final ValueChanged<int>? onManageEnrolments;
  final ValueChanged<String>? onMemberTap;
  final int previewLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!currentUser.isCoachOrAdmin) return const SizedBox.shrink();

    final theme = ShadTheme.of(context);
    final event = ref.watch(clEventsMasterProvider).valueOrNull?[eventId];
    final canManage = event != null && canManageEnrollments(event, currentUser);
    final activeAsync = ref
        .watch(clEnrollmentsMasterProvider(eventId))
        .whenData(
          (e) => Map.fromEntries(
            e.entries.where(
              (entry) => categoryFor(entry.value) == EnrollmentCategory.active,
            ),
          ),
        );
    final userMap = ref.watch(clUsersMasterProvider).valueOrNull;

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
                  activeAsync.when(
                    data: (e) => 'Enrolments (${e.length})',
                    loading: () => 'Enrolments',
                    error: (_, _) => 'Enrolments',
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
          activeAsync.when(
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
            data: (active) {
              if (active.isEmpty) {
                return Text(
                  'No enrolments yet.',
                  style: theme.textTheme.muted,
                );
              }
              final entries = active.entries.toList();
              final visible = entries.take(previewLimit).toList();
              final hidden = entries.length - visible.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final entry in visible)
                          if (onMemberTap == null)
                            EnrollmentTile(
                              username: entry.key,
                              status: entry.value,
                              eventId: eventId,
                              displayName: resolveDisplayName(entry.key),
                              canManage: canManage,
                            )
                          else
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onMemberTap!(entry.key),
                              child: EnrollmentTile(
                                username: entry.key,
                                status: entry.value,
                                eventId: eventId,
                                displayName: resolveDisplayName(entry.key),
                                canManage: canManage,
                              ),
                            ),
                      ],
                    ),
                  ),
                  if (hidden > 0) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onManageEnrolments != null
                          ? () => onManageEnrolments!(eventId)
                          : null,
                      child: Text(
                        '+$hidden more — tap to see all',
                        style: theme.textTheme.muted.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
