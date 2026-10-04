/// Event management widgets and providers for the club app.
///
/// Provides calendar views and event detail, enrolment, and attendance views.
/// Built on `club_sdk_2`'s `SecureClient`. Authentication is provided by
/// `cl_member_auth`.
library;

// The public website's events (club_core#53): models, providers and
// widgets over the token-free public reads. Navigation is by callback.
export 'src/extensions/public_event_view_dates.dart'
    show PublicEventCtaState, PublicEventViewDates;
export 'src/extensions/public_event_view_timing.dart'
    show PublicEventViewTiming;
export 'src/models/public/detail_labels/event_detail_batch_timings_labels.dart'
    show EventDetailBatchTimingsLabels;
export 'src/models/public/detail_labels/event_detail_coach_labels.dart'
    show EventDetailCoachLabels;
export 'src/models/public/detail_labels/event_detail_eligibility_labels.dart'
    show EventDetailEligibilityLabels;
export 'src/models/public/detail_labels/event_detail_facilities_labels.dart'
    show EventDetailFacilitiesLabels;
export 'src/models/public/detail_labels/event_detail_fee_structure_labels.dart'
    show EventDetailFeeStructureLabels;
export 'src/models/public/detail_labels/event_detail_fees_labels.dart'
    show EventDetailFeesLabels;
export 'src/models/public/detail_labels/event_detail_gallery_labels.dart'
    show EventDetailGalleryLabels;
export 'src/models/public/detail_labels/event_detail_hero_labels.dart'
    show EventDetailHeroLabels;
export 'src/models/public/detail_labels/event_detail_highlights_labels.dart'
    show EventDetailHighlightsLabels;
export 'src/models/public/detail_labels/event_detail_labels.dart'
    show EventDetailLabels;
export 'src/models/public/detail_labels/event_detail_offers_labels.dart'
    show EventDetailOffersLabels;
export 'src/models/public/detail_labels/event_detail_packages_labels.dart'
    show EventDetailPackagesLabels;
export 'src/models/public/event_highlight.dart' show EventHighlight;
export 'src/models/public/event_time_slot.dart' show EventTimeSlot;
export 'src/models/public/highlight.dart' show Highlight;
export 'src/models/public/highlight_type.dart' show HighlightType;
export 'src/models/public/public_event_card_labels.dart'
    show PublicEventCardLabels;
export 'src/models/public/public_event_split.dart' show PublicEventSplit;
export 'src/models/public/public_event_view.dart' show PublicEventView;
export 'src/providers/public_event_by_id.dart' show publicEventByIdProvider;
export 'src/providers/public_events_by_type.dart'
    show publicEventsByTypeProvider;
export 'src/providers/public_highlights.dart' show publicHighlightsProvider;
export 'src/utils/landing_event_selection.dart'
    show kMaxLandingEvents, selectLandingEvents;
// Views
export 'src/views/event_details_view.dart' show EventDetailsView;
export 'src/views/event_enrolments_view.dart' show EventEnrolmentsView;
export 'src/views/event_occurences_attendance_view.dart'
    show EventOccurencesAttendanceView;
export 'src/views/events_calendar_view.dart' show EventsCalendarView;
export 'src/views/events_camps_new_view.dart' show EventsCampsNewView;
export 'src/views/events_camps_view.dart' show EventsCampsView;
export 'src/views/events_one_off_new_view.dart' show EventsOneOffNewView;
export 'src/views/events_one_off_view.dart' show EventsOneOffView;
export 'src/views/events_programmes_new_view.dart' show EventsProgrammesNewView;
export 'src/views/events_programmes_view.dart' show EventsProgrammesView;
export 'src/views/my_event_details_view.dart' show MyEventDetailsView;
export 'src/views/my_events_all_view.dart' show MyEventsAllView;
export 'src/views/my_events_attendance_view.dart' show MyEventsAttendanceView;
export 'src/views/my_events_calendar_view.dart' show MyEventsCalendarView;
export 'src/views/removed_event_view.dart' show RemovedEventView;
// Cards (umbrella #189)
export 'src/widgets/cards/occurrence_card.dart' show OccurrenceCard;
// Widget needed by app for callback wiring
export 'src/widgets/my_events_section.dart' show MyEventsSection;
// Public website widgets
export 'src/widgets/public/detail/public_event_detail_content.dart'
    show PublicEventDetailContent;
export 'src/widgets/public/public_event_card.dart' show PublicEventCard;
export 'src/widgets/public/public_event_card_grid.dart'
    show PublicEventCardGrid;
export 'src/widgets/public/public_event_card_list.dart'
    show PublicEventCardList;
export 'src/widgets/public/public_event_compact_card.dart'
    show PublicEventCompactCard;
export 'src/widgets/public/public_event_hero_card.dart'
    show PublicEventHeroCard;
export 'src/widgets/public/public_event_info_cards.dart'
    show PublicEventInfoCards;
export 'src/widgets/public/sections/public_events_section.dart'
    show PublicEventsSection;
export 'src/widgets/public/sections/public_events_section_error.dart'
    show PublicEventsSectionError;
