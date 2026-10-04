import 'package:meta/meta.dart';

import 'event_detail_batch_timings_labels.dart';
import 'event_detail_coach_labels.dart';
import 'event_detail_eligibility_labels.dart';
import 'event_detail_facilities_labels.dart';
import 'event_detail_fee_structure_labels.dart';
import 'event_detail_fees_labels.dart';
import 'event_detail_gallery_labels.dart';
import 'event_detail_hero_labels.dart';
import 'event_detail_highlights_labels.dart';
import 'event_detail_offers_labels.dart';
import 'event_detail_packages_labels.dart';

/// Section labels of the public event detail content, one shape per
/// section. The host fills them from its own copy.
@immutable
class EventDetailLabels {
  const EventDetailLabels({
    required this.hero,
    required this.highlights,
    required this.coach,
    required this.fees,
    required this.feeStructure,
    required this.batchTimings,
    required this.facilities,
    required this.packages,
    required this.offers,
    required this.eligibility,
    required this.gallery,
  });

  /// Labels for hero info cards (dates, timings, venue, eligibility).
  final EventDetailHeroLabels hero;

  final EventDetailHighlightsLabels highlights;
  final EventDetailCoachLabels coach;
  final EventDetailFeesLabels fees;
  final EventDetailFeeStructureLabels feeStructure;
  final EventDetailBatchTimingsLabels batchTimings;
  final EventDetailFacilitiesLabels facilities;
  final EventDetailPackagesLabels packages;
  final EventDetailOffersLabels offers;
  final EventDetailEligibilityLabels eligibility;
  final EventDetailGalleryLabels gallery;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailLabels &&
        other.hero == hero &&
        other.highlights == highlights &&
        other.coach == coach &&
        other.fees == fees &&
        other.feeStructure == feeStructure &&
        other.batchTimings == batchTimings &&
        other.facilities == facilities &&
        other.packages == packages &&
        other.offers == offers &&
        other.eligibility == eligibility &&
        other.gallery == gallery;
  }

  @override
  int get hashCode {
    return Object.hash(
      hero,
      highlights,
      coach,
      fees,
      feeStructure,
      batchTimings,
      facilities,
      packages,
      offers,
      eligibility,
      gallery,
    );
  }
}
