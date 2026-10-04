import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_remote_store/cl_remote_store.dart' show MediaUrlBuilder;
import 'package:club_sdk_2/club_sdk_2.dart';

/// API base the fixtures' media URLs are built against.
const testApiBase = 'https://api.example.test/v1';

/// The venue every fixture event is held at.
const testVenue = PublicVenue(publicId: 'pv-rink', name: 'Riverside Rink');

/// A public event of [type], starting 4 May 2026 10:00 local.
PublicEvent testPublicEvent({
  String publicId = 'pe-1',
  String title = 'Spring Camp',
  String description = '',
  EventType type = EventType.camp,
  String? rrule,
  DateTime? start,
  Duration length = const Duration(hours: 2),
  List<EventSession>? sessions,
  bool isPast = false,
  bool isFeatured = false,
  DateTime? dobOnOrAfterUtc,
  DateTime? dobOnOrBeforeUtc,
  List<MediaRef> gallery = const [],
  List<PublicProfile> coaches = const [],
  EventMarketingBasic? marketing,
}) {
  final startLocal = start ?? DateTime(2026, 5, 4, 10);
  return PublicEvent(
    publicId: publicId,
    title: title,
    description: description,
    type: type,
    venueId: testVenue.publicId,
    rrule: rrule,
    startTimeUtc: startLocal.toUtc(),
    endTimeUtc: startLocal.add(length).toUtc(),
    sessions: sessions,
    isPast: isPast,
    isFeatured: isFeatured,
    dobOnOrAfterUtc: dobOnOrAfterUtc,
    dobOnOrBeforeUtc: dobOnOrBeforeUtc,
    gallery: gallery,
    venue: testVenue,
    coaches: coaches,
    marketing: marketing,
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
  );
}

/// [event] as the pages see it.
PublicEventView testEventView(PublicEvent event, {EventMarketing? marketing}) =>
    PublicEventView(
      event: event,
      media: const MediaUrlBuilder(testApiBase),
      marketing: marketing,
    );

/// An image gallery item.
MediaRef testPhoto(String uuid) =>
    MediaRef(uuid: uuid, mimeType: 'image/jpeg', filename: '$uuid.jpg');

/// Section labels for the event detail page, each reading as its own name.
const testDetailLabels = EventDetailLabels(
  hero: EventDetailHeroLabels(
    datesLabel: 'DATES',
    timingsLabel: 'TIMINGS',
    venueLabel: 'VENUE',
    eligibilityLabel: 'ELIGIBILITY',
  ),
  highlights: EventDetailHighlightsLabels(
    titleActive: 'What you will learn',
    titlePast: 'What they learned',
  ),
  coach: EventDetailCoachLabels(
    labelActive: 'Your coaches',
    labelPast: 'Coached by',
  ),
  fees: EventDetailFeesLabels(title: 'Camp fee', includesLabel: 'Includes'),
  feeStructure: EventDetailFeeStructureLabels(
    title: 'Fee structure',
    feeTypeHeader: 'Fee',
    periodHeader: 'Period',
    amountHeader: 'Amount',
    totalLabel: 'Total',
  ),
  batchTimings: EventDetailBatchTimingsLabels(
    title: 'Timetable',
    batchHeader: 'Slot',
    timeHeader: 'Time',
    sessionHeader: 'Activity',
    detailsHeader: 'Details',
  ),
  facilities: EventDetailFacilitiesLabels(title: 'Facilities'),
  packages: EventDetailPackagesLabels(title: 'Packages', subtitle: 'Save'),
  offers: EventDetailOffersLabels(
    title: 'Offers',
    validUntilPrefix: 'Valid until ',
  ),
  eligibility: EventDetailEligibilityLabels(title: 'Who can join'),
  gallery: EventDetailGalleryLabels(title: 'Gallery', subtitle: 'Moments'),
);
