import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'notification_kinds_evaluation.dart';
import 'notification_kinds_group.dart';
import 'notification_kinds_inquiry.dart';
import 'notification_kinds_programme.dart';
import 'notification_payload.dart';

/// Display-ready presentation of an [AppNotification].
///
/// The server only emits structured facts in [AppNotification.payload]; this
/// class is what the UI shows.
@immutable
class NotificationDisplay {
  const NotificationDisplay({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

typedef NotificationFormatterFn =
    NotificationDisplay Function(
      Map<String, dynamic> data,
    );

/// Typed targets that a notification tap can resolve to.
///
/// Concrete subtypes carry the IDs the host router needs to navigate.
/// `null` (no target) means the notification is informational and should
/// not navigate anywhere on tap.
///
/// Every link also carries [sourceNotificationId] — the id of the
/// [AppNotification] whose tap produced the link. The router threads it
/// through to the destination screen so that, when the linked entity
/// no longer exists, the screen can offer a "Delete notification"
/// affordance instead of leaving the user stranded on a not-found error.
sealed class NotificationDeepLink {
  const NotificationDeepLink({this.sourceNotificationId});
  final int? sourceNotificationId;
}

@immutable
class NotifEventLink extends NotificationDeepLink {
  const NotifEventLink(this.eventId, {super.sourceNotificationId});
  final int eventId;
}

@immutable
class NotifMyEventLink extends NotificationDeepLink {
  const NotifMyEventLink({
    required this.username,
    required this.eventId,
    super.sourceNotificationId,
  });
  final String username;
  final int eventId;
}

@immutable
class NotifGroupLink extends NotificationDeepLink {
  const NotifGroupLink(this.groupId, {super.sourceNotificationId});
  final int groupId;
}

/// Recipient's "my groups" — `/memberzone/my-groups/$username`. Used by
/// member-perspective group notifications (`group.member_added`,
/// `group.member_removed`, `group.archived`, `group.settings_changed`,
/// `group.join_response`) so members never land on the admin-only
/// `GroupProfileView` which would 403 them.
@immutable
class NotifMyGroupsLink extends NotificationDeepLink {
  const NotifMyGroupsLink(this.username, {super.sourceNotificationId});
  final String username;
}

@immutable
class NotifOccurrenceLink extends NotificationDeepLink {
  const NotifOccurrenceLink({
    required this.eventId,
    required this.occurrenceTimeUtc,
    super.sourceNotificationId,
  });
  final int eventId;
  final DateTime occurrenceTimeUtc;
}

/// Admin view of another user's profile — `/memberzone/users/$username`.
/// Used by user-management notifications that target admin recipients
/// (e.g. `user.deleted`).
@immutable
class NotifAdminUserLink extends NotificationDeepLink {
  const NotifAdminUserLink(this.username, {super.sourceNotificationId});
  final String username;
}

/// Admin pending-user review screen — `/memberzone/users/review?username=$username`.
/// Used by `user.registration_pending` (pending action `user_approval`),
/// where the admin's intent is to act on the pending application rather
/// than read the regular profile.
@immutable
class NotifAdminUserReviewLink extends NotificationDeepLink {
  const NotifAdminUserReviewLink(this.username, {super.sourceNotificationId});
  final String username;
}

/// The recipient's own profile — `/memberzone/profile`. Used by
/// notifications that inform the user about a change to their account
/// (e.g. `user.blocked`, `user.role_changed`,
/// `account.password_changed_self`, `profile.changed_by_admin`).
@immutable
class NotifSelfProfileLink extends NotificationDeepLink {
  const NotifSelfProfileLink({super.sourceNotificationId});
}

/// Admin view of a venue — `/memberzone/venues/$venueId`. Used by
/// venue-management notifications targeting admins (`venue.renamed`).
@immutable
class NotifVenueLink extends NotificationDeepLink {
  const NotifVenueLink(this.venueId, {super.sourceNotificationId});
  final int venueId;
}

/// Recipient's "my events" — `/memberzone/my-events/$username`.
/// Used by aggregate notifications that target the member's overview
/// (e.g. `attendance.absence_streak_warning`).
@immutable
class NotifMyEventsHomeLink extends NotificationDeepLink {
  const NotifMyEventsHomeLink(this.username, {super.sourceNotificationId});
  final String username;
}

/// A member's credit view — `/memberzone/credit/$username`. Used by
/// `credit.released` (club_core#32, #101).
@immutable
class NotifCreditLink extends NotificationDeepLink {
  const NotifCreditLink(this.username, {super.sourceNotificationId});
  final String username;
}

/// The admin inquiries inbox — `/memberzone/inquiries`. Used by
/// `inquiry.received`, which the server sends to every admin (club_core#32).
@immutable
class NotifInquiriesLink extends NotificationDeepLink {
  const NotifInquiriesLink({super.sourceNotificationId});
}

/// The member's own published review, read-only —
/// `/memberzone/reviews/mine/$evaluationId`. Used by `evaluation.published`
/// (club_core#174).
@immutable
class NotifMyReviewLink extends NotificationDeepLink {
  const NotifMyReviewLink(this.evaluationId, {super.sourceNotificationId});
  final int evaluationId;
}

/// The member's published reviews — `/memberzone/reviews/mine`. Used by
/// `evaluation.withdrawn`, whose review the member can no longer open
/// (club_core#174).
@immutable
class NotifMyReviewsLink extends NotificationDeepLink {
  const NotifMyReviewsLink({super.sourceNotificationId});
}

/// An evaluation in its owner's editor — `/memberzone/reviews/$evaluationId`.
/// Used by `evaluation.transferred`, which reaches the receiving coach
/// (club_core#174).
@immutable
class NotifEvaluationLink extends NotificationDeepLink {
  const NotifEvaluationLink(this.evaluationId, {super.sourceNotificationId});
  final int evaluationId;
}

/// Context handed to each registry entry when resolving a deep-link.
@immutable
class NotificationLinkContext {
  const NotificationLinkContext({
    required this.data,
    required this.currentUsername,
    required this.sourceNotificationId,
  });

  final Map<String, dynamic> data;
  final String currentUsername;
  final int sourceNotificationId;
}

typedef NotificationLinkResolver =
    NotificationDeepLink? Function(
      NotificationLinkContext ctx,
    );

/// One server-emitted notification type and everything the UI needs to
/// render and act on it.
///
/// The dotted [type] is the source of truth shared with the server. The
/// other three columns own how the client displays that type:
/// [typeLabel] is the muted subtitle, [format] produces the primary
/// title+body+icon, and [deepLink] resolves the navigation target on tap
/// (or null for informational rows like broadcasts).
@immutable
class NotificationKind {
  const NotificationKind({
    required this.type,
    required this.typeLabel,
    required this.format,
    required this.deepLink,
  });

  final String type;

  /// Muted `~Label` subtitle shown below the body in the row. `null`
  /// means "no subtitle" — the row omits the line entirely. Used when
  /// the body already conveys the row's nature (e.g. the registration
  /// row's name + "registered and is awaiting approval" makes a separate
  /// "New registration" label redundant).
  final String? typeLabel;
  final NotificationFormatterFn format;
  final NotificationLinkResolver? deepLink;
}

/// The single registry of every server-emitted notification type and how
/// the client renders / navigates it. One row per dotted type. Adding
/// support for a new server type is one row — here, or in the family's
/// `notification_kinds_<family>.dart` list spread into this one (the types
/// added since the server's 0.5 release, club_core#32). A new deep-link
/// target also needs a [NotificationDeepLink] subtype and its route in the
/// app router.
///
/// Per-family copy is refined in the umbrella's sub-issues (#162-#167);
/// rows added there only touch `typeLabel` / `format` strings, never the
/// dispatch wiring.
final List<NotificationKind> kNotificationKinds = <NotificationKind>[
  // --- Group family ---------------------------------------------------------
  NotificationKind(
    type: 'group.join_request',
    typeLabel: 'Group join request',
    format: (data) {
      final groupName = payloadString(data['groupName']);
      final requester = payloadString(data['requesterUsername']);
      return NotificationDisplay(
        title: groupName.isNotEmpty ? groupName : 'Group join request',
        body: '$requester asked to join $groupName.',
        icon: LucideIcons.userPlus,
      );
    },
    deepLink: _groupLink,
  ),
  NotificationKind(
    type: 'group.join_response',
    typeLabel: 'Group join response',
    format: (data) {
      final groupName = payloadString(data['groupName']);
      final outcome = payloadString(data['outcome']);
      final verb = outcome == 'approved'
          ? 'was approved'
          : outcome == 'rejected'
          ? 'was rejected'
          : 'received a response';
      return NotificationDisplay(
        title: groupName.isNotEmpty ? groupName : 'Group join response',
        body: 'Your request to join $groupName $verb.',
        icon: outcome == 'approved' ? LucideIcons.userCheck : LucideIcons.userX,
      );
    },
    deepLink: _myGroupsLink,
  ),
  NotificationKind(
    type: 'group.archived',
    typeLabel: 'Group archived',
    format: (data) {
      final groupName = payloadString(data['groupName']);
      return NotificationDisplay(
        title: groupName.isNotEmpty ? groupName : 'Group archived',
        body: 'The group $groupName was archived.',
        icon: LucideIcons.archive,
      );
    },
    deepLink: _myGroupsLink,
  ),
  NotificationKind(
    type: 'group.member_removed',
    typeLabel: 'Group member removed',
    format: (data) {
      final groupName = payloadString(data['groupName']);
      return NotificationDisplay(
        title: groupName.isNotEmpty ? groupName : 'Group',
        body: 'You were removed from $groupName.',
        icon: LucideIcons.userMinus,
      );
    },
    deepLink: _myGroupsLink,
  ),
  NotificationKind(
    type: 'group.settings_changed',
    typeLabel: 'Group settings changed',
    format: (data) {
      final groupName = payloadString(data['groupName']);
      return NotificationDisplay(
        title: groupName.isNotEmpty ? groupName : 'Group',
        body: 'Settings changed for $groupName.',
        icon: LucideIcons.settings,
      );
    },
    deepLink: _myGroupsLink,
  ),
  NotificationKind(
    type: 'group.member_added',
    typeLabel: 'Added to group',
    format: (data) {
      final groupName = payloadString(data['groupName']);
      final actor = payloadString(data['addedByUsername']);
      final byClause = actor.isNotEmpty ? ' by @$actor' : '';
      return NotificationDisplay(
        title: groupName.isNotEmpty ? groupName : 'Group',
        body: 'You were added to $groupName$byClause.',
        icon: LucideIcons.userPlus,
      );
    },
    deepLink: _myGroupsLink,
  ),

  // --- Event family ---------------------------------------------------------
  NotificationKind(
    type: 'event.cancelled',
    typeLabel: 'Event cancelled',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      final reason = payloadString(data['reason']);
      final body = reason.isNotEmpty
          ? '$title was cancelled: $reason.'
          : '$title was cancelled.';
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Event cancelled',
        body: body,
        icon: LucideIcons.calendarX,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'event.rescheduled',
    typeLabel: 'Event rescheduled',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Event rescheduled',
        body: '$title was rescheduled.',
        icon: LucideIcons.calendarClock,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'event.venue_changed',
    typeLabel: 'Venue changed',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Venue changed',
        body: 'Venue changed for $title.',
        icon: LucideIcons.mapPin,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'event.coach_changed',
    typeLabel: 'Coach changed',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      final coaches =
          (data['coachNames'] as List?)
              ?.map(payloadString)
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];
      final body = coaches.isEmpty
          ? 'Coach changed for $title.'
          : 'Coach changed for $title: ${coaches.join(', ')}.';
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Coach changed',
        body: body,
        icon: LucideIcons.userCog,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'event.deleted',
    typeLabel: 'Event deleted',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Event deleted',
        body: '$title was deleted.',
        icon: LucideIcons.calendarX,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'event.restored',
    typeLabel: 'Event restored',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Event restored',
        body: '$title is back on the schedule.',
        icon: LucideIcons.calendarCheck,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'event.split',
    typeLabel: 'Event split',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Event split',
        body: '$title was split; check the new schedule.',
        icon: LucideIcons.gitBranch,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'event.conflict_detected',
    typeLabel: 'Scheduling conflict',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      final conflicts = data['conflictingEvents'];
      final n = conflicts is List ? conflicts.length : 0;
      return NotificationDisplay(
        title: 'Scheduling conflict',
        body: n > 0
            ? 'Scheduling conflict for $title with $n other event(s).'
            : 'Scheduling conflict for $title.',
        icon: LucideIcons.triangleAlert,
      );
    },
    deepLink: _adminEventLink,
  ),
  NotificationKind(
    type: 'event.upcoming_reminder',
    typeLabel: 'Upcoming event',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      final leadHours = payloadInt(data['leadHours']);
      final when = leadHours == null
          ? 'soon'
          : leadHours == 1
          ? 'in 1 hour'
          : leadHours < 24
          ? 'in $leadHours hours'
          : leadHours == 24
          ? 'in 24 hours'
          : 'in ${(leadHours / 24).round()} days';
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Upcoming event',
        body: '$title starts $when.',
        icon: LucideIcons.bellRing,
      );
    },
    deepLink: myEventLink,
  ),
  ...kProgrammeNotificationKinds,

  // --- Enrollment family ----------------------------------------------------
  NotificationKind(
    type: 'enrollment.opened',
    typeLabel: 'Enrollment opened',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Enrollment opened',
        body: 'Enrollment is open for $title.',
        icon: LucideIcons.doorOpen,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'enrollment.closed',
    typeLabel: 'Enrollment closed',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Enrollment closed',
        body: 'Enrollment closed for $title.',
        icon: LucideIcons.doorClosed,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'enrollment.rsvp',
    typeLabel: 'RSVP',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      final member = payloadString(data['memberUsername']);
      final outcome = payloadString(data['outcome']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'RSVP',
        body: '$member responded "$outcome" to $title.',
        icon: LucideIcons.messageSquareReply,
      );
    },
    // RSVP notifications go to staff — link to the admin event detail.
    deepLink: _adminEventLink,
  ),
  NotificationKind(
    type: 'enrollment.admin_enrolled',
    typeLabel: 'Enrolled',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      final trial = data['trial'] == true;
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Enrolled',
        body: trial
            ? 'You were enrolled in $title (trial).'
            : 'You were enrolled in $title.',
        icon: LucideIcons.userPlus,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'enrollment.cancelled_admin',
    typeLabel: 'Enrollment cancelled',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      final reason = payloadString(data['reason']);
      final body = reason.isNotEmpty
          ? 'Your enrollment in $title was cancelled: $reason.'
          : 'Your enrollment in $title was cancelled.';
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Enrollment cancelled',
        body: body,
        icon: LucideIcons.userMinus,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'enrollment.cancelled_self',
    typeLabel: 'Enrollment cancelled',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Enrollment cancelled',
        body: 'You withdrew from $title.',
        icon: LucideIcons.userMinus,
      );
    },
    deepLink: myEventLink,
  ),

  NotificationKind(
    type: 'enrollment.trial_ended',
    typeLabel: 'Trial ended',
    format: (data) {
      // A mark used up the member's trial credit and the server removed
      // them (club_core#100): the programme and the trial's dates.
      final title = payloadString(data['eventTitle']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Trial ended',
        body: trialDates(data).isNotEmpty ? trialDates(data) : 'Trial ended',
        icon: LucideIcons.flag,
      );
    },
    deepLink: myEventLink,
  ),

  // --- Credit family --------------------------------------------------------
  NotificationKind(
    type: 'credit.released',
    typeLabel: 'Credit released',
    format: (data) {
      // A programme ended and its bound credit moved to general credit
      // (club_core#32): the programme and the amount.
      final title = payloadString(data['eventTitle']);
      final credits = payloadInt(data['credits']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Credit released',
        body: credits == null ? 'Credit released' : '+$credits',
        icon: LucideIcons.coins,
      );
    },
    deepLink: creditLink,
  ),

  // --- Attendance family ----------------------------------------------------
  NotificationKind(
    type: 'attendance.marked',
    typeLabel: 'Attendance recorded',
    format: (data) {
      final status = payloadString(data['status']);
      return NotificationDisplay(
        title: 'Attendance recorded',
        body: status.isNotEmpty
            ? 'Your attendance was marked as $status.'
            : 'Your attendance was recorded.',
        icon: LucideIcons.clipboardCheck,
      );
    },
    // Member-perspective: the recipient is the member whose attendance was
    // marked. The admin attendance roster (`_occurrenceLink`) is gated to
    // staff and would 403 the member (#179).
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'attendance.correction_requested',
    typeLabel: 'Attendance correction',
    format: (data) {
      final member = payloadString(data['memberUsername']);
      return NotificationDisplay(
        title: 'Attendance correction',
        body: '$member requested an attendance correction.',
        icon: LucideIcons.fileQuestionMark,
      );
    },
    deepLink: _occurrenceLink,
  ),
  NotificationKind(
    type: 'attendance.correction_response',
    typeLabel: 'Attendance correction',
    format: (data) {
      final outcome = payloadString(data['outcome']);
      return NotificationDisplay(
        title: 'Attendance correction',
        body: outcome == 'approved'
            ? 'Your attendance correction was approved.'
            : outcome == 'rejected'
            ? 'Your attendance correction was rejected.'
            : 'Your attendance correction received a response.',
        icon: outcome == 'approved' ? LucideIcons.check : LucideIcons.x,
      );
    },
    // Member-perspective: the recipient is the member who requested the
    // correction. Route to their own event view, not the admin roster (#179).
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'attendance.absence_streak_warning',
    typeLabel: 'Absence streak',
    format: (data) {
      final streak = payloadInt(data['streakLength']) ?? 0;
      return NotificationDisplay(
        title: 'Absence streak',
        body: streak > 0
            ? 'You have been absent for the last $streak sessions.'
            : 'You have been absent for several sessions in a row.',
        icon: LucideIcons.triangleAlert,
      );
    },
    // Scheduler-fired (recipient is the absent member): aggregate view.
    deepLink: _myEventsHomeLink,
  ),
  NotificationKind(
    type: 'attendance.pending_mark_reminder',
    typeLabel: 'Attendance pending',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      final occ = payloadDateText(data['occurrenceTimeUtc']);
      return NotificationDisplay(
        title: 'Attendance pending',
        body: occ.isNotEmpty
            ? 'Attendance not yet marked for $title on $occ.'
            : 'Attendance not yet marked for $title.',
        icon: LucideIcons.clipboardList,
      );
    },
    // Staff-facing roster reminder for an occurrence whose attendance is
    // still unmarked.
    deepLink: _occurrenceLink,
  ),

  // --- Account family -------------------------------------------------------
  NotificationKind(
    type: 'account.password_changed_by_admin',
    typeLabel: 'Password reset by admin',
    format: (data) {
      final actor = payloadString(data['actorUsername']);
      return NotificationDisplay(
        title: 'Password changed',
        body: actor.isNotEmpty
            ? 'An admin (@$actor) changed your password. Use the new password '
                  'to log in next time.'
            : 'An admin changed your password. Use the new password to log in '
                  'next time.',
        icon: LucideIcons.keyRound,
      );
    },
    deepLink: _selfProfileLink,
  ),
  NotificationKind(
    type: 'account.password_changed_self',
    typeLabel: 'Password changed',
    format: (_) => const NotificationDisplay(
      title: 'Password changed',
      body: 'Your password was changed.',
      icon: LucideIcons.keyRound,
    ),
    deepLink: _selfProfileLink,
  ),
  NotificationKind(
    type: 'account.registration_approved',
    typeLabel: 'Account approved',
    format: (_) => const NotificationDisplay(
      title: 'Account approved',
      body: 'Your account was approved — welcome!',
      icon: LucideIcons.userRoundCheck,
    ),
    deepLink: _selfProfileLink,
  ),

  // --- Profile family -------------------------------------------------------
  NotificationKind(
    type: 'profile.changed_by_admin',
    typeLabel: 'Profile updated',
    format: (data) {
      final fields =
          (data['changedFields'] as List?)
              ?.map(payloadString)
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];
      final actor = payloadString(data['actorUsername']);
      final who = actor.isNotEmpty ? 'An admin (@$actor)' : 'An admin';
      return NotificationDisplay(
        title: 'Profile updated',
        body: fields.isEmpty
            ? '$who updated your profile.'
            : '$who updated your profile: ${fields.join(', ')}.',
        icon: LucideIcons.userPen,
      );
    },
    deepLink: _selfProfileLink,
  ),

  // --- User family ----------------------------------------------------------
  NotificationKind(
    type: 'user.registration_pending',
    // Body already names the user; the "New registration" subtitle would
    // be redundant. See #381.
    typeLabel: null,
    format: (data) {
      final username = payloadString(data['username']);
      final first = _titleCase(payloadString(data['firstName']));
      final last = _titleCase(payloadString(data['lastName']));
      final displayName = '$first $last'.trim();
      final who = displayName.isNotEmpty && username.isNotEmpty
          ? '$displayName (@$username)'
          : displayName.isNotEmpty
          ? displayName
          : username.isNotEmpty
          ? '@$username'
          : 'A new user';
      return NotificationDisplay(
        title: 'New registration',
        body: '$who registered and is awaiting approval.',
        icon: LucideIcons.userRoundCheck,
      );
    },
    // Admin-facing: open the dedicated pending-user review screen
    // (`AdminUserReviewView`), not the regular admin profile.
    deepLink: _adminUserReviewLink,
  ),
  NotificationKind(
    type: 'user.blocked',
    typeLabel: 'Account blocked',
    format: (data) {
      final reason = payloadString(data['reason']);
      return NotificationDisplay(
        title: 'Account blocked',
        body: reason.isNotEmpty
            ? 'Your account was blocked: $reason.'
            : 'Your account was blocked.',
        icon: LucideIcons.userX,
      );
    },
    deepLink: _selfProfileLink,
  ),
  NotificationKind(
    type: 'user.unblocked',
    typeLabel: 'Account unblocked',
    format: (_) => const NotificationDisplay(
      title: 'Account unblocked',
      body: 'Your account was unblocked.',
      icon: LucideIcons.userCheck,
    ),
    deepLink: _selfProfileLink,
  ),
  NotificationKind(
    type: 'user.role_changed',
    typeLabel: 'Role updated',
    format: (data) {
      final added =
          (data['added'] as List?)
              ?.map(payloadString)
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];
      final removed =
          (data['removed'] as List?)
              ?.map(payloadString)
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];
      final newRoles =
          (data['newRoles'] as List?)
              ?.map(payloadString)
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];
      final String body;
      if (added.isNotEmpty && removed.isEmpty) {
        body = 'You were granted: ${added.join(', ')}.';
      } else if (removed.isNotEmpty && added.isEmpty) {
        body = 'You no longer have: ${removed.join(', ')}.';
      } else if (added.isNotEmpty && removed.isNotEmpty) {
        body =
            'Your roles changed '
            '(+${added.join(', ')}, −${removed.join(', ')}).';
      } else if (newRoles.isNotEmpty) {
        body = 'Your roles are now: ${newRoles.join(', ')}.';
      } else {
        body = 'Your roles were updated.';
      }
      return NotificationDisplay(
        title: 'Role updated',
        body: body,
        icon: LucideIcons.shieldCheck,
      );
    },
    deepLink: _selfProfileLink,
  ),
  NotificationKind(
    type: 'user.deleted',
    typeLabel: 'User deleted',
    format: (data) {
      final username = payloadString(data['username']);
      return NotificationDisplay(
        title: 'User deleted',
        body: username.isNotEmpty
            ? '@$username was deleted.'
            : 'A user account was deleted.',
        icon: LucideIcons.userMinus,
      );
    },
    deepLink: _adminUserLink,
  ),
  NotificationKind(
    type: 'user.restored',
    typeLabel: 'Account restored',
    format: (_) => const NotificationDisplay(
      title: 'Account restored',
      body: 'Your account was restored.',
      icon: LucideIcons.userPlus,
    ),
    deepLink: _selfProfileLink,
  ),

  // --- Occurrence family ----------------------------------------------------
  NotificationKind(
    type: 'occurrence.rescheduled',
    typeLabel: 'Occurrence rescheduled',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      final occ = payloadDateText(data['occurrenceTimeUtc']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Occurrence rescheduled',
        body: occ.isNotEmpty
            ? '$title on $occ was rescheduled.'
            : '$title — an occurrence was rescheduled.',
        icon: LucideIcons.calendarClock,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'occurrence.cancelled',
    typeLabel: 'Occurrence cancelled',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      final reason = payloadString(data['reason']);
      final occ = payloadDateText(data['occurrenceTimeUtc']);
      final lead = occ.isNotEmpty
          ? '$title on $occ was cancelled'
          : '$title — an occurrence was cancelled';
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Occurrence cancelled',
        body: reason.isNotEmpty ? '$lead: $reason.' : '$lead.',
        icon: LucideIcons.calendarX,
      );
    },
    deepLink: myEventLink,
  ),
  NotificationKind(
    type: 'occurrence.restored',
    typeLabel: 'Occurrence restored',
    format: (data) {
      final title = payloadString(data['eventTitle']);
      final occ = payloadDateText(data['occurrenceTimeUtc']);
      return NotificationDisplay(
        title: title.isNotEmpty ? title : 'Occurrence restored',
        body: occ.isNotEmpty
            ? '$title on $occ is on again.'
            : '$title — an occurrence is on again.',
        icon: LucideIcons.calendarCheck,
      );
    },
    deepLink: myEventLink,
  ),

  // --- Venue family ---------------------------------------------------------
  // venue.renamed is admin-only. The server restricts delivery via its
  // recipient list, so no client-side audience gating is required —
  // non-admins simply never receive the row.
  NotificationKind(
    type: 'venue.renamed',
    typeLabel: 'Venue renamed',
    format: (data) {
      final oldName = payloadString(data['oldName']);
      final newName = payloadString(data['newName']);
      final affected = data['affectedEventIds'];
      final n = affected is List ? affected.length : 0;
      final lead = oldName.isNotEmpty && newName.isNotEmpty
          ? 'Venue renamed: $oldName → $newName'
          : 'Venue renamed';
      return NotificationDisplay(
        title: 'Venue renamed',
        body: n > 0 ? '$lead. Affects $n upcoming event(s).' : '$lead.',
        icon: LucideIcons.mapPin,
      );
    },
    deepLink: _venueLink,
  ),

  // --- Evaluation and inquiry families (club_core#32) -----------------------
  ...kEvaluationNotificationKinds,
  ...kInquiryNotificationKinds,
  ...kGroupEligibilityNotificationKinds,

  // --- Broadcast ------------------------------------------------------------
  // The server stamps notification rows with `broadcast.message` regardless
  // of the inner payload `type` (`broadcast.text`, future variants, …), so
  // both cases resolve to the same announcement copy. Informational, no
  // deep-link.
  const NotificationKind(
    type: 'broadcast.message',
    typeLabel: 'Announcement',
    format: _broadcastFormat,
    deepLink: _noLink,
  ),
  const NotificationKind(
    type: 'broadcast.text',
    typeLabel: 'Announcement',
    format: _broadcastFormat,
    deepLink: _noLink,
  ),
];

/// Lookup keyed by dotted type. Built lazily from [kNotificationKinds].
final Map<String, NotificationKind> kNotificationKindByType = {
  for (final k in kNotificationKinds) k.type: k,
};

/// Server-emitted notification types this client recognises by name but
/// has not yet rendered specific copy for. Each entry cites the sub-issue
/// of umbrella #134 that will add a real registry row.
///
/// Until those issues land these types still render — they fall through
/// to the generic line in [formatNotification] just like any unknown type.
const Set<String> kKnownUnimplementedTypes = <String>{};

NotificationDisplay _broadcastFormat(Map<String, dynamic> data) {
  final text = payloadString(data['text']);
  return NotificationDisplay(
    title: 'Announcement',
    body: text.isNotEmpty ? text : 'New announcement.',
    icon: LucideIcons.megaphone,
  );
}

NotificationDeepLink? _groupLink(NotificationLinkContext ctx) {
  final id = payloadInt(ctx.data['groupId']);
  return id == null
      ? null
      : NotifGroupLink(id, sourceNotificationId: ctx.sourceNotificationId);
}

/// Member-perspective group resolver — routes the recipient to their own
/// `/memberzone/my-groups/$username`. Group identity (groupId) is dropped
/// because the destination is a list view: the freshly added/removed
/// group surfaces in the recipient's "Current memberships" section.
NotificationDeepLink? _myGroupsLink(NotificationLinkContext ctx) {
  return NotifMyGroupsLink(
    ctx.currentUsername,
    sourceNotificationId: ctx.sourceNotificationId,
  );
}

/// The member's own view of the payload's event, or `null` when the
/// payload names none. The default for the event family.
NotificationDeepLink? myEventLink(NotificationLinkContext ctx) {
  final eventId = payloadInt(ctx.data['eventId']);
  return eventId == null
      ? null
      : NotifMyEventLink(
          username: ctx.currentUsername,
          eventId: eventId,
          sourceNotificationId: ctx.sourceNotificationId,
        );
}

NotificationDeepLink? _adminEventLink(NotificationLinkContext ctx) {
  final eventId = payloadInt(ctx.data['eventId']);
  return eventId == null
      ? null
      : NotifEventLink(eventId, sourceNotificationId: ctx.sourceNotificationId);
}

NotificationDeepLink? _occurrenceLink(NotificationLinkContext ctx) {
  final eventId = payloadInt(ctx.data['eventId']);
  final occMs = payloadInt(ctx.data['occurrenceTimeUtc']);
  if (eventId == null || occMs == null) return null;
  return NotifOccurrenceLink(
    eventId: eventId,
    occurrenceTimeUtc: DateTime.fromMillisecondsSinceEpoch(occMs, isUtc: true),
    sourceNotificationId: ctx.sourceNotificationId,
  );
}

NotificationDeepLink? creditLink(NotificationLinkContext ctx) =>
    NotifCreditLink(
      ctx.currentUsername,
      sourceNotificationId: ctx.sourceNotificationId,
    );

/// A trial's local dates from a `trial_ended` payload ("12 Sep – 23 Sep"),
/// or empty when the payload lacks them.
String trialDates(Map<String, dynamic> data) {
  final from = payloadInt(data['enrolledAtUtc']);
  final until = payloadInt(data['withdrawnAtUtc']);
  if (from == null || until == null) return '';
  String day(int ms) => DateFormat('d MMM').format(
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal(),
  );
  return '${day(from)} – ${day(until)}';
}

NotificationDeepLink? _selfProfileLink(NotificationLinkContext ctx) {
  return NotifSelfProfileLink(
    sourceNotificationId: ctx.sourceNotificationId,
  );
}

NotificationDeepLink? _venueLink(NotificationLinkContext ctx) {
  final id = payloadInt(ctx.data['venueId']);
  return id == null
      ? null
      : NotifVenueLink(id, sourceNotificationId: ctx.sourceNotificationId);
}

NotificationDeepLink? _myEventsHomeLink(NotificationLinkContext ctx) {
  return NotifMyEventsHomeLink(
    ctx.currentUsername,
    sourceNotificationId: ctx.sourceNotificationId,
  );
}

NotificationDeepLink? _adminUserLink(NotificationLinkContext ctx) {
  final username = ctx.data['username'];
  if (username is! String || username.isEmpty) return null;
  return NotifAdminUserLink(
    username,
    sourceNotificationId: ctx.sourceNotificationId,
  );
}

NotificationDeepLink? _adminUserReviewLink(NotificationLinkContext ctx) {
  final username = ctx.data['username'];
  if (username is! String || username.isEmpty) return null;
  return NotifAdminUserReviewLink(
    username,
    sourceNotificationId: ctx.sourceNotificationId,
  );
}

NotificationDeepLink? _noLink(NotificationLinkContext ctx) => null;

/// Title-case a single name token: trim, then upper-case the first
/// character and lower-case the rest. Empty input stays empty. Multi-
/// word names should be passed token-by-token; this helper does not
/// split on whitespace.
String _titleCase(String s) {
  final t = s.trim();
  if (t.isEmpty) return '';
  return t[0].toUpperCase() + t.substring(1).toLowerCase();
}

/// Translate the server's `{v, type, data}` payload envelope into a human
/// sentence. Looks up [kNotificationKindByType] by [AppNotification.type];
/// unknown or [kKnownUnimplementedTypes] types fall back to a generic line
/// that includes the raw type string so unhandled events stay visible
/// during development.
NotificationDisplay formatNotification(AppNotification n) {
  final kind = kNotificationKindByType[n.type];
  if (kind != null) return kind.format(_dataOf(n));
  return NotificationDisplay(
    title: 'Notification',
    body: 'You have a new notification (${n.type}).',
    icon: LucideIcons.bell,
  );
}

/// Pick a navigation target for a notification.
///
/// [currentUsername] is the logged-in user's username; event-family
/// notifications open the member's "my event" view by default.
NotificationDeepLink? resolveDeepLink(
  AppNotification n, {
  required String currentUsername,
}) {
  final kind = kNotificationKindByType[n.type];
  final resolver = kind?.deepLink;
  if (resolver == null) return null;
  return resolver(
    NotificationLinkContext(
      data: _dataOf(n),
      currentUsername: currentUsername,
      sourceNotificationId: n.id,
    ),
  );
}

/// Human-readable label for a notification's dotted [AppNotification.type].
///
/// Drives the muted `~Label` subtitle in the notification row. Unknown
/// types fall back to a title-cased rendering of the dotted string so new
/// server events stay visible during development.
String notificationTypeLabel(String dotted) {
  final kind = kNotificationKindByType[dotted];
  if (kind != null) return kind.typeLabel ?? '';
  final cleaned = dotted.replaceAll('.', ' ').replaceAll('_', ' ');
  if (cleaned.isEmpty) return 'Notification';
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

Map<String, dynamic> _dataOf(AppNotification n) {
  final raw = n.payload['data'];
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const <String, dynamic>{};
}
