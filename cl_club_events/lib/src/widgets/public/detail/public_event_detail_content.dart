import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/widgets.dart';

import '../../../models/public/detail_labels/event_detail_labels.dart';
import '../../../models/public/public_event_view.dart';
import '../public_event_info_cards.dart';
import 'public_event_description_section.dart';
import 'public_event_eligibility_section.dart';
import 'public_event_facilities_section.dart';
import 'public_event_fee_structure_section.dart';
import 'public_event_fees_section.dart';
import 'public_event_gallery_section.dart';
import 'public_event_highlights_and_coaches.dart';
import 'public_event_membership_section.dart';
import 'public_event_offers_section.dart';
import 'public_event_packages_section.dart';
import 'public_event_timetable_section.dart';
import 'public_event_venue_map_section.dart';

/// A public event's detail page body: every section the event has, in page
/// order — description, dates and venue, eligibility, highlights and
/// coaches, timetable, facilities, fees, packages, offers, membership, venue
/// map and gallery. Camps and one-offs, and programmes, show different sets.
class PublicEventDetailContent extends StatelessWidget {
  const PublicEventDetailContent({
    required this.event,
    required this.labels,
    this.onVenueTap,
    super.key,
  });

  final PublicEventView event;
  final EventDetailLabels labels;

  /// Called with the venue's public id when the venue badge is tapped.
  final ValueChanged<String>? onVenueTap;

  @override
  Widget build(BuildContext context) {
    final hasGallery = event.galleryUris.isNotEmpty;
    final isProgram = event.event.type == EventType.programme;
    final isOneOff = event.event.type == EventType.oneOff;
    // A single session spans the whole window and says nothing a timetable
    // could show, so only a real multi-slot list earns the section.
    final hasTimetable = (event.sessions?.length ?? 0) > 1;
    final hasFacilities =
        event.facilities != null && event.facilities!.isNotEmpty;
    final hasFeeStructure = event.feeStructure != null;
    final hasPackageOffers = event.packageOffers != null;
    final hasOffers = event.offers != null && event.offers!.isNotEmpty;
    final hasMembership = event.clubMembership != null;
    final hasHighlights =
        event.highlights != null && event.highlights!.isNotEmpty;
    final hasEligibility = event.eligibility != null;
    final hasFees = event.fees != null;

    // The map section (programmes only) reads the venue off the event.
    final venue = event.venue;
    final hasVenueMap = isProgram && venue.mapUri != null;

    return Column(
      children: [
        // Description
        if (event.fullDescription != null &&
                event.fullDescription!.isNotEmpty ||
            event.description.isNotEmpty)
          PublicEventDescriptionSection(event: event),

        // Hero info cards (date, timing, venue) — camps/oneoff only
        if (!isProgram)
          PublicEventInfoCards(
            event: event,
            labels: labels.hero,
            onVenueTap: onVenueTap,
          ),

        // Eligibility (camps/oneoff) - only for active events
        if (!isProgram && hasEligibility && event.isActive)
          PublicEventEligibilitySection(
            event: event,
            labels: labels.eligibility,
          ),

        // Highlights + Training/Coach Section (for camps/oneoff)
        if (!isProgram)
          PublicEventHighlightsAndCoaches(
            event: event,
            labels: labels,
            showHighlights: hasHighlights && (!isOneOff || event.isActive),
          ),

        // Session timetable (programs only)
        if (isProgram && hasTimetable)
          PublicEventTimetableSection(
            event: event,
            labels: labels.batchTimings,
          ),

        // Facilities (programs only)
        if (isProgram && hasFacilities)
          PublicEventFacilitiesSection(event: event, labels: labels.facilities),

        // Simple Fees (camps/oneoff) - only for active events
        if (!isProgram && hasFees && event.isActive)
          PublicEventFeesSection(event: event, labels: labels.fees),

        // Fee Structure Table (programs)
        if (isProgram && hasFeeStructure)
          PublicEventFeeStructureSection(
            event: event,
            labels: labels.feeStructure,
          ),

        // Package Offers (programs)
        if (isProgram && hasPackageOffers)
          PublicEventPackagesSection(event: event, labels: labels.packages),

        // Special Offers (programs)
        if (isProgram && hasOffers)
          PublicEventOffersSection(event: event, labels: labels.offers),

        // Membership Benefits (programs)
        if (isProgram && hasMembership)
          PublicEventMembershipSection(event: event),

        // Venue Map (programs only)
        if (hasVenueMap) PublicEventVenueMapSection(venue: venue),

        // Gallery
        if (hasGallery)
          PublicEventGallerySection(event: event, labels: labels.gallery),
      ],
    );
  }
}
