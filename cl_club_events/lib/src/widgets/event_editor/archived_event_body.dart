import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_management_messages.dart';
import '../events_preview/cl_eligibility_preview.dart';
import '../events_preview/cl_event_audit_info.dart';
import '../events_preview/cl_event_coaches.dart';
import '../events_preview/cl_event_flags.dart';
import '../events_preview/cl_event_gallery.dart';
import '../events_preview/cl_event_hero.dart';
import '../events_preview/cl_event_schedule.dart';
import '../events_preview/cl_event_venue_detail.dart';
import 'event_management_section.dart';

/// Body of an archived event's detail page (club_client#36): the event as
/// it was, read-only, with the Event Management card, where an admin
/// unarchives it and a super admin deletes it.
///
/// The enrolment sections are left out: the server lists enrolments of a
/// live event only.
class ArchivedEventBody extends StatelessWidget {
  const ArchivedEventBody({
    required this.event,
    required this.currentUser,
    this.venue,
    this.onVenueTap,
    this.onPublicProfileTap,
    this.onDeleted,
    super.key,
  });

  final Event event;
  final UserPrivate currentUser;
  final Venue? venue;
  final ValueChanged<int>? onVenueTap;

  /// Opens a coach's public profile by `publicId`.
  final ValueChanged<String>? onPublicProfileTap;

  /// Leaves the page once the event has been deleted.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Text(
            EventManagementMessages.archivedNotice,
            style: theme.textTheme.muted,
          ),
          ClEventHeroCard(event: event),
          ClEventSchedule(event: event),
          ClEligibilityPreview(event: event),
          ClEventVenueDetail(
            venueId: event.venueId,
            venue: venue,
            onVenueTap: onVenueTap,
          ),
          ClEventCoaches(event: event, onPublicProfileTap: onPublicProfileTap),
          ClEventFlags(event: event),
          ClEventGallery(eventId: event.id, canEdit: false),
          EventManagementSection(
            event: event,
            currentUser: currentUser,
            onDeleted: onDeleted,
          ),
          ClEventAuditInfo(event: event, currentUser: currentUser),
        ],
      ),
    );
  }
}
