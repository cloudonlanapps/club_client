import 'package:cl_club_venues/cl_club_venues.dart' show EventVenueLine;
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart';

import '../../models/event_display_status.dart';
import '../../providers/event_display_status.dart';
import 'actions/admin_event_actions.dart';
import 'actions/user_event_actions.dart';
import 'event_schedule_lines.dart';

/// List-row card for a single event.
///
/// Caller passes only [eventId], an optional [username], and navigation
/// callbacks. The card resolves the [Event] itself, derives its own
/// caption (enrollment status for the member lens when present;
/// otherwise the temporal status — Ongoing / Coming Soon / Ended /
/// Cancelled / Rescheduled), and mounts the right action resolver.
/// Status wording matches the event-details audit card via
/// [eventDisplayStatusLabel]. An archived event reads [archivedCaption]
/// and offers no actions (club_client#36).
///
/// Data sourcing:
///   * `username == null` → admin lens. Event from `clEventsMasterProvider`.
///     Trailing = [AdminEventActions] when `onEnrollments` is wired.
///   * `username != null` → user lens. Event from
///     `clMyEventsMasterProvider(username)`. Caption prefers the
///     enrollment status. Trailing = [UserEventActions].
class EventCard extends ConsumerWidget {
  const EventCard({
    required this.eventId,
    this.username,
    this.onTap,
    this.onEnrollments,
    this.memberEligible = true,
    super.key,
  });

  /// Caption of an archived (soft-deleted) event.
  static const String archivedCaption = 'Archived';

  final int eventId;

  /// Target user whose perspective this row represents. `null` → admin.
  final String? username;

  final VoidCallback? onTap;

  /// Admin perspective only — navigation to the event's enrollments
  /// screen. `null` hides the action.
  final VoidCallback? onEnrollments;

  /// False when the row stands for one member's place in the event and the
  /// server reports that member's enrolment as no longer eligible: the body
  /// then carries the shared mark (club_client#43).
  final bool memberEligible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = _resolveEvent(ref);
    if (event == null) {
      return EntityCard(
        image: EntityImage.placeholder(),
        title: 'Event #$eventId',
        onTap: onTap,
      );
    }

    final caption = event.isActive ? _captionFor(ref, event) : archivedCaption;
    final coverUrl = ref.watch(eventCoverImageProvider(event.id)).value;
    final headers = ref.watch(imageAuthHeadersProvider).value ?? const {};
    final image = coverUrl != null
        ? EntityImage.network(coverUrl, httpHeaders: headers)
        : EntityImage.placeholder();
    EntityCard card(List<ActionItem> actions) => EntityCard(
      image: image,
      title: event.title,
      caption: caption,
      body: EventBody(event: event, memberEligible: memberEligible),
      trailingActions: actions.isEmpty ? null : actions,
      onTap: onTap,
    );

    if (!event.isActive) return card(const []);
    if (username == null) {
      if (onEnrollments == null) return card(const []);
      return AdminEventActions(
        event: event,
        onEnrollments: onEnrollments,
        builder: (context, actions) => card(actions),
      );
    }
    return UserEventActions(
      username: username!,
      event: event,
      builder: (context, actions) => card(actions),
    );
  }

  Event? _resolveEvent(WidgetRef ref) {
    if (username == null) {
      return ref.watch(clEventsMasterProvider).valueOrNull?[eventId];
    }
    final events = ref.watch(clMyEventsMasterProvider(username!)).valueOrNull;
    return events?.where((e) => e.id == eventId).firstOrNull ??
        ref.watch(clEventsMasterProvider).valueOrNull?[eventId];
  }

  String? _captionFor(WidgetRef ref, Event event) {
    final status = ref.watch(eventDisplayStatusProvider(eventId)).valueOrNull;
    final temporalLabel = status == null
        ? null
        : eventDisplayStatusLabel(status);

    if (username == null) return temporalLabel;

    final enrollment = ref
        .watch(
          clMyEnrollmentProvider(
            (username: username!, eventId: eventId),
          ),
        )
        .valueOrNull;
    return _enrollmentSuffix(enrollment) ?? temporalLabel;
  }

  /// Member-perspective caption text. Returns `null` when no enrollment
  /// record exists or the row is in a terminal state — the caller then
  /// falls back to the temporal status label.
  static String? _enrollmentSuffix(Enrollment? e) {
    if (e == null) return null;
    switch (e.status) {
      case EnrollmentStatus.invited:
        return 'You are invited';
      case EnrollmentStatus.accepted:
        return 'You are accepted';
      case EnrollmentStatus.assigned:
        return 'You are assigned';
      case EnrollmentStatus.assignedTrial:
        return 'Trial — assigned';
      case EnrollmentStatus.requested:
        return 'Awaiting admin approval';
      case EnrollmentStatus.withdrawRequested:
        return 'Withdrawal pending';
      case EnrollmentStatus.rejected:
      case EnrollmentStatus.declined:
      case EnrollmentStatus.withdrawn:
      case EnrollmentStatus.removed:
        return null;
    }
  }
}

class EventBody extends StatelessWidget {
  const EventBody({
    required this.event,
    this.memberEligible = true,
    super.key,
  });

  final Event event;

  /// False adds the shared no-longer-eligible mark beneath the venue.
  final bool memberEligible;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EventScheduleLines(event: event, wrap: true),
        const SizedBox(height: 4),
        EventVenueLine(venueId: event.venueId),
        if (!memberEligible) ...[
          const SizedBox(height: 4),
          const NoLongerEligibleLabel(),
        ],
      ],
    );
  }
}
