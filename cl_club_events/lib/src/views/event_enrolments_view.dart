import 'package:cl_member_auth/cl_member_auth.dart' show canManageEnrollments;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show Enrollment, UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show TitleRow;

import '../models/enrollment_category.dart';
import '../widgets/buttons/enrollment_admin_action_bar.dart';
import '../widgets/enrollment_admin_handlers.dart';
import '../widgets/enrollment_group_section.dart';

/// An event's enrollment list, by category.
///
/// Staff may read it (club_server enrollment R18); only an admin or the
/// event's organizer may change it (`canManageEnrollments`, R10). Anyone
/// else, such as a coach assigned to the event, sees the list without the
/// Assign / Invite bar or the row actions (club_core#136).
class EventEnrolmentsView extends ConsumerWidget {
  const EventEnrolmentsView({
    required this.currentUser,
    required this.eventId,
    this.onBack,
    this.onOpenReview,
    super.key,
  });

  final UserPrivate currentUser;
  final int eventId;
  final VoidCallback? onBack;

  /// Opens an evaluation a coach started with a row's **Add Review**
  /// (club_core#174).
  final ValueChanged<int>? onOpenReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.isCoachOrAdmin,
      'EventEnrolmentsView called for ${currentUser.username}, who is not '
      'staff. Screen gate failed.',
    );
    final theme = ShadTheme.of(context);
    final enrollmentsAsync = ref.watch(clEnrollmentsMasterProvider(eventId));
    // Full records carry the withdrawal reason, which tells an ended trial
    // from an ordinary removal (club_core#98), and whether an enrolled
    // member still meets the event's criteria (club_client#42).
    final records = ref
        .watch(clEnrollmentRecordsMasterProvider(eventId))
        .valueOrNull;
    final withdrawalReasons = {
      for (final entry in (records ?? const <String, Enrollment>{}).entries)
        entry.key: entry.value.withdrawalReason,
    };
    final ineligibleUsernames = {
      for (final entry in (records ?? const <String, Enrollment>{}).entries)
        if (!entry.value.eligible) entry.key,
    };
    final eventMasterAsync = ref.watch(clEventsMasterProvider);
    final userListAsync = ref.watch(clUsersMasterProvider);

    final event = eventMasterAsync.whenOrNull(
      data: (master) => master[eventId],
    );
    final eventTitle = event?.title;
    final canManage = event != null && canManageEnrollments(event, currentUser);

    final excludeUsernames = excludeUsernamesForEvent(eventId, ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleRow(
          title: eventTitle ?? 'Event #$eventId',
          subtitle: 'Enrollment Management',
          onBack: onBack,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: EnrollmentAdminActionBar(
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
            onAssignTrial: () => handleAssignTrialEnrollment(
              context,
              ref,
              eventId: eventId,
              actingUser: currentUser,
              excludeUsernames: excludeUsernames,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: enrollmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Could not load enrollments: $e',
                style: theme.textTheme.muted,
              ),
            ),
            data: (enrollments) {
              if (enrollments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 48,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No enrollments yet',
                        style: theme.textTheme.muted,
                      ),
                      if (canManage) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Use the buttons above to assign or invite users.',
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                );
              }

              final grouped = groupByCategory(enrollments);
              final userList = userListAsync.valueOrNull;

              String resolveDisplayName(String username) {
                final user = userList?[username];
                if (user != null) {
                  return '${user.firstName} ${user.lastName}'.trim();
                }
                return username;
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(clEnrollmentsMasterProvider(eventId));
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final category in EnrollmentCategory.values)
                      if (grouped[category]!.isNotEmpty) ...[
                        EnrollmentGroupSection(
                          // Keyed so a group keeps its own open/closed
                          // state when another group empties and goes.
                          key: ValueKey(category),
                          category: category,
                          enrollments: grouped[category]!,
                          eventId: eventId,
                          displayNameResolver: resolveDisplayName,
                          canManage: canManage,
                          withdrawalReasons: withdrawalReasons,
                          ineligibleUsernames: ineligibleUsernames,
                          currentUser: currentUser,
                          onOpenReview: onOpenReview,
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
