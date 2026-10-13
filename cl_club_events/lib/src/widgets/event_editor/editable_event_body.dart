import 'package:cl_remote_store/cl_remote_store.dart'
    show clVenueDetailProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../events_preview/cl_event_audit_info.dart';
import '../events_preview/cl_event_enrolments_summary.dart';
import '../events_preview/cl_event_gallery.dart';
import '../events_preview/cl_event_pending_requests.dart';
import '../events_preview/cl_event_venue_detail.dart';
import 'event_eligibility_card.dart';
import 'event_flags_card.dart';
import 'event_management_section.dart';
import 'event_overview_card.dart';
import 'event_schedule_section.dart';
import 'organizer_coaches_section.dart';

/// Editable body for an event detail page, shown to whoever may manage the
/// event (an admin or its organizer, `canManageEvent`), mirroring
/// `VenueProfileView`: cover image (avatar-style media upload on the hero),
/// description (markdown), eligibility / organizer (section editors), gallery
/// (media-link tiles), flags (live toggles), and the management actions
/// ([EventManagementSection]).
/// Cover & gallery use the v2 media-link flow; the legacy `galleryUris`
/// field is no longer read. The schedule section depends on the event type
/// ([EventScheduleSection]); the venue stays read-only here.
class EditableEventBody extends ConsumerWidget {
  const EditableEventBody({
    required this.event,
    required this.currentUser,
    this.venue,
    this.onVenueTap,
    this.onManageEnrolments,
    this.onMemberTap,
    this.onPublicProfileTap,
    this.onDeleted,
    super.key,
  });

  final Event event;
  final UserPrivate currentUser;
  final Venue? venue;
  final ValueChanged<int>? onVenueTap;
  final ValueChanged<int>? onManageEnrolments;
  final ValueChanged<String>? onMemberTap;

  /// Opens a coach's public profile by `publicId` (opted-in coaches only).
  final ValueChanged<String>? onPublicProfileTap;

  /// Leaves the page once the event has been deleted (Event Management).
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EventOverviewCard(event: event),
          const SizedBox(height: 16),
          EventScheduleSection(event: event, canEdit: true),
          const SizedBox(height: 16),
          EventEligibilityCard(event: event),
          const SizedBox(height: 16),
          OrganizerCoachesSection(
            event: event,
            onPublicProfileTap: onPublicProfileTap,
          ),
          const SizedBox(height: 16),
          ClEventGallery(eventId: event.id, canEdit: true),
          const SizedBox(height: 16),
          EventFlagsCard(event: event),
          const SizedBox(height: 16),
          ClEventVenueDetail(
            venueId: event.venueId,
            venue:
                venue ??
                ref.watch(clVenueDetailProvider(event.venueId)).valueOrNull,
            onVenueTap: onVenueTap,
          ),
          const SizedBox(height: 16),
          EventManagementSection(
            event: event,
            currentUser: currentUser,
            onDeleted: onDeleted,
          ),
          const SizedBox(height: 16),
          ClEventPendingRequests(
            eventId: event.id,
            currentUser: currentUser,
            onManageEnrolments: onManageEnrolments,
            onMemberTap: onMemberTap,
          ),
          const SizedBox(height: 12),
          ClEventEnrolmentsSummary(
            eventId: event.id,
            currentUser: currentUser,
            onManageEnrolments: onManageEnrolments,
            onMemberTap: onMemberTap,
          ),
          const SizedBox(height: 16),
          ClEventAuditInfo(event: event, currentUser: currentUser),
        ],
      ),
    );
  }
}
