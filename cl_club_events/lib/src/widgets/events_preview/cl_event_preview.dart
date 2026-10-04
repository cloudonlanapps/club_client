import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';

import 'cl_eligibility_preview.dart';
import 'cl_event_audit_info.dart';
import 'cl_event_coaches.dart';
import 'cl_event_enrolments_summary.dart';
import 'cl_event_flags.dart';
import 'cl_event_gallery.dart';
import 'cl_event_hero.dart';
import 'cl_event_pending_requests.dart';
import 'cl_event_schedule.dart';
import 'cl_event_venue_detail.dart';

/// Minimal read-only preview of an [Event].
///
/// The legacy preview surfaced aux-info content (highlights, fees,
/// packages, offers, facilities, fee structure, membership benefits,
/// schedule) — all of which the server no longer stores. Until the new
/// event editor is implemented, the preview shows the structured
/// eligibility, the optional cover image, and the gallery.
class ClEventPreview extends StatelessWidget {
  const ClEventPreview({
    required this.event,
    this.currentUser,
    this.venue,
    this.onVenueTap,
    this.onManageEnrolments,
    this.onMemberTap,
    this.onPublicProfileTap,
    super.key,
  });

  final Event event;
  final UserPrivate? currentUser;
  final Venue? venue;
  final ValueChanged<int>? onVenueTap;
  final ValueChanged<int>? onManageEnrolments;
  final ValueChanged<String>? onMemberTap;

  /// Called with a coach's `publicId` when their (surfaced) name is tapped,
  /// so the host can open the public profile route.
  final ValueChanged<String>? onPublicProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClEventHeroCard(event: event),
          const SizedBox(height: 16),
          ClEventSchedule(event: event),
          const SizedBox(height: 12),
          ClEligibilityPreview(event: event),
          const SizedBox(height: 12),
          ClEventVenueDetail(
            venueId: event.venueId,
            venue: venue,
            onVenueTap: onVenueTap,
          ),
          const SizedBox(height: 12),
          ClEventCoaches(event: event, onPublicProfileTap: onPublicProfileTap),
          const SizedBox(height: 12),
          ClEventFlags(event: event),
          if (currentUser != null) ...[
            const SizedBox(height: 16),
            ClEventPendingRequests(
              eventId: event.id,
              currentUser: currentUser!,
              onManageEnrolments: onManageEnrolments,
              onMemberTap: onMemberTap,
            ),
            const SizedBox(height: 12),
            ClEventEnrolmentsSummary(
              eventId: event.id,
              currentUser: currentUser!,
              onManageEnrolments: onManageEnrolments,
              onMemberTap: onMemberTap,
            ),
          ],
          const SizedBox(height: 16),
          ClEventGallery(
            eventId: event.id,
            canEdit: currentUser?.isCoachOrAdmin ?? false,
          ),
          const SizedBox(height: 16),
          ClEventAuditInfo(event: event, currentUser: currentUser),
        ],
      ),
    );
  }
}
