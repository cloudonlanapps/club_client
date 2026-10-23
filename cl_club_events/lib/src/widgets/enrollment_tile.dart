import 'package:cl_remote_store/cl_remote_store.dart' show evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionGroup, isMobileWidth;

import '../models/enrollment_category.dart';
import '../models/withdrawal_reasons.dart';
import '../utils/enrollment_status_label.dart';
import 'cards/actions/admin_enrollment_actions.dart';
import 'cards/actions/enrollment_review_action.dart';
import 'enrollment_member_lines.dart';

/// One member on an event's enrollment list: who, their status when not
/// active, and the admin's actions (resolved by [AdminEnrollmentActions],
/// which greys out what credit forbids, club_core#96, #105). A trial that
/// ended because its credit ran out shows a flag in place of the removed
/// badge (club_core#98). The actions show only when [canManage]: an
/// assigned coach reads the list but may not change it (club_core#136).
/// A coach [currentUser] also gets **Add Review** while evaluations are on,
/// whether or not they manage the list (club_core#174). A member who no
/// longer meets the event's criteria ([eligible] false) is marked beneath
/// their username (club_client#42).
class EnrollmentTile extends ConsumerWidget {
  const EnrollmentTile({
    required this.username,
    required this.status,
    required this.eventId,
    required this.displayName,
    required this.canManage,
    this.withdrawalReason,
    this.currentUser,
    this.onOpenReview,
    this.eligible = true,
    super.key,
  });

  final String username;
  final EnrollmentStatus status;
  final int eventId;
  final String displayName;

  /// Whether the viewer may manage enrollment on this event
  /// (`canManageEnrollments`); false renders the row without actions.
  final bool canManage;

  /// The enrollment's withdrawal reason, when known.
  final String? withdrawalReason;

  /// The viewer; a coach gets **Add Review** (club_core#174). Null offers
  /// no review action.
  final UserPrivate? currentUser;

  /// Opens an evaluation started from this row.
  final ValueChanged<int>? onOpenReview;

  /// The enrollment's `eligible`, as the server reports it.
  final bool eligible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final viewer = currentUser;
    final review =
        viewer != null &&
            viewer.roles.isCoach &&
            ref.watch(evaluationsProvider) == true
        ? enrollmentReviewAction(
            context: context,
            coach: viewer,
            username: username,
            eventId: eventId,
            onOpenReview: onOpenReview,
          )
        : null;
    final category = categoryFor(status);
    final trialEnded =
        status == EnrollmentStatus.removed &&
        isTrialCreditExhausted(withdrawalReason);

    // The trial-ended flag, or the status of a member who is not active.
    final narrow = isMobileWidth(context);
    // On a phone one action shows and the rest are in the overflow menu, as
    // on an EntityCard's phone row: two buttons with their reasons are
    // wider than the screen (club_client#296).
    final inlineLimit = narrow ? 1 : 2;
    final marker = trialEnded
        ? Semantics(
            label: 'Trial ended',
            child: Icon(
              LucideIcons.flag,
              size: 14,
              color: theme.colorScheme.mutedForeground,
            ),
          )
        : category != EnrollmentCategory.active
        ? EnrollmentStatusBadge(status: status)
        : null;
    final actions = canManage
        ? AdminEnrollmentActions(
            eventId: eventId,
            username: username,
            status: status,
            displayName: displayName,
            builder: (context, actions) => ActionGroup(
              actions: [...actions, ?review],
              inlineLimit: inlineLimit,
            ),
          )
        : review != null
        ? ActionGroup(actions: [review], inlineLimit: inlineLimit)
        : null;
    final member = [
      EnrollmentAvatar(
        displayName: displayName,
        showActiveDot: category == EnrollmentCategory.active,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: EnrollmentMemberLines(
          displayName: displayName,
          username: username,
          eligible: eligible,
        ),
      ),
      if (marker != null) ...[const SizedBox(width: 8), marker],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.border),
        ),
      ),
      // On a phone the actions do not fit beside the member: they go on a
      // line of their own, as an EntityCard's do (club_client#296).
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Row(children: member),
                if (actions != null)
                  Align(alignment: Alignment.centerRight, child: actions),
              ],
            )
          : Row(
              children: [
                ...member,
                if (actions != null) ...[const SizedBox(width: 8), actions],
              ],
            ),
    );
  }
}

class EnrollmentAvatar extends StatelessWidget {
  const EnrollmentAvatar({
    required this.displayName,
    required this.showActiveDot,
    super.key,
  });

  final String displayName;
  final bool showActiveDot;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.muted,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          color: theme.colorScheme.mutedForeground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (!showActiveDot) return avatar;

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.background,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnrollmentStatusBadge extends StatelessWidget {
  const EnrollmentStatusBadge({required this.status, super.key});

  final EnrollmentStatus status;

  Color statusColor(ShadColorScheme scheme) {
    return switch (status) {
      EnrollmentStatus.assigned ||
      EnrollmentStatus.accepted ||
      EnrollmentStatus.assignedTrial => Colors.green,
      EnrollmentStatus.invited ||
      EnrollmentStatus.requested ||
      EnrollmentStatus.withdrawRequested => Colors.orange,
      EnrollmentStatus.withdrawn ||
      EnrollmentStatus.removed ||
      EnrollmentStatus.rejected ||
      EnrollmentStatus.declined => scheme.mutedForeground,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = statusColor(theme.colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        enrollmentStatusLabel(status),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
