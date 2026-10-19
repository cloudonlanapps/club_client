import 'detail_labels/event_detail_batch_timings_labels.dart';
import 'detail_labels/event_detail_coach_labels.dart';
import 'detail_labels/event_detail_eligibility_labels.dart';
import 'detail_labels/event_detail_facilities_labels.dart';
import 'detail_labels/event_detail_fee_structure_labels.dart';
import 'detail_labels/event_detail_fees_labels.dart';
import 'detail_labels/event_detail_gallery_labels.dart';
import 'detail_labels/event_detail_hero_labels.dart';
import 'detail_labels/event_detail_highlights_labels.dart';
import 'detail_labels/event_detail_labels.dart';
import 'detail_labels/event_detail_offers_labels.dart';
import 'detail_labels/event_detail_packages_labels.dart';

/// The section labels of an event page for a host with no site copy of its
/// own (the member app's marketing preview), in plain English. The website
/// passes its own, from its copy.
const EventDetailLabels defaultEventDetailLabels = EventDetailLabels(
  hero: EventDetailHeroLabels(
    datesLabel: 'Dates',
    timingsLabel: 'Timings',
    venueLabel: 'Venue',
    eligibilityLabel: 'Eligibility',
  ),
  highlights: EventDetailHighlightsLabels(
    titleActive: 'Highlights',
    titlePast: 'Highlights',
  ),
  coach: EventDetailCoachLabels(labelActive: 'Coach', labelPast: 'Coach'),
  fees: EventDetailFeesLabels(title: 'Fees', includesLabel: 'Includes:'),
  feeStructure: EventDetailFeeStructureLabels(
    title: 'Fee Structure',
    feeTypeHeader: 'Fee Type',
    periodHeader: 'Period',
    amountHeader: 'Amount',
    totalLabel: 'Total',
  ),
  batchTimings: EventDetailBatchTimingsLabels(
    title: 'Batch Timings',
    batchHeader: 'BATCH',
    timeHeader: 'TIME',
    sessionHeader: 'SESSION',
    detailsHeader: 'DETAILS',
  ),
  facilities: EventDetailFacilitiesLabels(title: 'Additional Facilities'),
  packages: EventDetailPackagesLabels(
    title: 'Save More with Packages',
    subtitle: 'Choose a longer commitment and save big!',
  ),
  offers: EventDetailOffersLabels(
    title: 'Special Offers',
    validUntilPrefix: 'Valid until: ',
  ),
  eligibility: EventDetailEligibilityLabels(title: 'Eligibility'),
  gallery: EventDetailGalleryLabels(
    title: 'Gallery',
    subtitle: 'Photos and documents',
  ),
);
