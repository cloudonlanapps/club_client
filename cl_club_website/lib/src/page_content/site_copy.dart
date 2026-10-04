import 'package:cl_club_events/cl_club_events.dart'
    show
        EventDetailBatchTimingsLabels,
        EventDetailCoachLabels,
        EventDetailEligibilityLabels,
        EventDetailFacilitiesLabels,
        EventDetailFeeStructureLabels,
        EventDetailFeesLabels,
        EventDetailGalleryLabels,
        EventDetailHeroLabels,
        EventDetailHighlightsLabels,
        EventDetailLabels,
        EventDetailOffersLabels,
        EventDetailPackagesLabels;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ClubHistoryData, ClubInfo, ClubValueCardData, EventType;
import 'package:flutter/widgets.dart';
import '../l10n/site_strings.dart';

import 'contact/contact_form_labels.dart';
import 'contact/contact_info_labels.dart';
import 'contact/contact_map_labels.dart';
import 'contact/contact_page_labels.dart';
import 'contact/contact_subject_options.dart';
import 'event_detail_page_data.dart';
import 'landing_page_data.dart';
import 'page_common.dart';
import 'page_data.dart';
import 'page_type.dart';

export '../l10n/site_strings.dart' show SiteStrings;

/// The site's own words, assembled into the shapes the pages already take.
///
/// This copy used to arrive as 14 JSON files under `/static/pages/`, fetched
/// from the old server. Almost none of it was ever the club's to edit — button
/// labels, section headers, empty-state text, and CTA blocks that carry routes
/// and icon names, which are code. It changes when the UI changes, not when
/// the club does, so it belongs in the build rather than behind a request.
///
/// Two things stayed out of the JSON's shape on the way in:
///
/// * **Routes and icon names are constants here**, not strings a translator
///   could see. A mistranslated route is a broken link, and neither is text.
/// * **The About page's history and values** are club content, not UI copy.
/// They are bundled defaults for now and move to the server's `clubInfo`
///   in site#18; they live in the ARB so the page is never empty.
class SiteCopy {
  const SiteCopy(this.strings);

  /// The localised strings for the current locale.
  factory SiteCopy.of(BuildContext context) =>
      SiteCopy(SiteStrings.of(context));

  final SiteStrings strings;

  // ══════════════════════════════════════════════════════════════════════════
  // ROUTES AND ICONS — code, not copy
  // ══════════════════════════════════════════════════════════════════════════

  static const routeCamps = '/public/events';
  static const routePrograms = '/public/programs';
  static const routeOneOff = '/public/one-off';
  static const routeRinks = '/public/rinks';
  static const routeContact = '/public/contact-us';
  static const routeSignup = '/auth/signup';

  // ══════════════════════════════════════════════════════════════════════════
  // LANDING
  // ══════════════════════════════════════════════════════════════════════════

  LandingPageData get landing => LandingPageData(
    hero: LandingHeroData(
      learnMoreButton: strings.landingLearnMore,
      scrollIndicatorText: strings.landingScrollIndicator,
      carouselTexts: [
        strings.landingCarouselCamps,
        strings.landingCarouselPrograms,
        strings.landingCarouselEvents,
      ],
    ),
    nav: NavLabelsData(
      home: strings.navHome,
      programs: strings.navPrograms,
      events: strings.navEvents,
      oneOff: strings.navOneOff,
      coaches: strings.navCoaches,
      rinks: strings.navRinks,
      aboutUs: strings.navAboutUs,
      contactUs: strings.navContactUs,
      menu: strings.navMenu,
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // CONTENT PAGES
  // ══════════════════════════════════════════════════════════════════════════

  PageData pageData(PageType pageType) {
    switch (pageType) {
      case PageType.learningCamps:
        return PageData(
          hero: PageHeroData(
            badge: strings.campsHeroBadge,
            title: strings.campsHeroTitle,
            description: strings.campsHeroDescription,
          ),
          landingSection: PageSectionHeaderData(
            badge: strings.campsLandingBadge,
            title: strings.campsLandingTitle,
            description: strings.campsLandingDescription,
            buttonText: strings.campsLandingButton,
          ),
          activeSection: PageSectionHeaderData(
            badge: strings.campsActiveBadge,
            title: strings.campsActiveTitle,
            description: strings.campsActiveDescription,
          ),
          pastSection: PageSectionHeaderData(
            badge: strings.campsPastBadge,
            title: strings.campsPastTitle,
            description: strings.campsPastDescription,
          ),
          emptyState: PageEmptyStateData(
            iconName: 'sparkles',
            title: strings.campsEmptyTitle,
            description: strings.campsEmptyDescription,
            buttonText: strings.campsEmptyButton,
          ),
          errorTitle: strings.campsErrorTitle,
          cta: PageCtaData(
            title: strings.campsCtaTitle,
            description: strings.campsCtaDescription,
            primaryButtonText: strings.campsCtaPrimaryButton,
            primaryButtonIcon: 'mail',
            primaryRoute: routeContact,
            secondaryButtonText: strings.campsCtaSecondaryButton,
            secondaryButtonIcon: 'graduationCap',
            secondaryRoute: routePrograms,
          ),
          cardLabels: _cardLabels,
        );

      case PageType.trainingSessions:
        return PageData(
          hero: PageHeroData(
            badge: strings.programsHeroBadge,
            title: strings.programsHeroTitle,
            description: strings.programsHeroDescription,
          ),
          landingSection: PageSectionHeaderData(
            badge: strings.programsLandingBadge,
            title: strings.programsLandingTitle,
            description: strings.programsLandingDescription,
            buttonText: strings.programsLandingButton,
          ),
          activeSection: PageSectionHeaderData(
            badge: strings.programsActiveBadge,
            title: strings.programsActiveTitle,
            description: strings.programsActiveDescription,
          ),
          emptyState: PageEmptyStateData(
            iconName: 'sparkles',
            title: strings.programsEmptyTitle,
            description: strings.programsEmptyDescription,
            buttonText: strings.programsEmptyButton,
          ),
          errorTitle: strings.programsErrorTitle,
          cta: PageCtaData(
            title: strings.programsCtaTitle,
            description: strings.programsCtaDescription,
            primaryButtonText: strings.programsCtaPrimaryButton,
            primaryRoute: routeSignup,
            secondaryButtonText: strings.programsCtaSecondaryButton,
            secondaryRoute: routeContact,
          ),
          cardLabels: _cardLabels,
        );

      case PageType.clubEvents:
        return PageData(
          hero: PageHeroData(
            badge: strings.oneOffHeroBadge,
            title: strings.oneOffHeroTitle,
            description: strings.oneOffHeroDescription,
          ),
          landingSection: PageSectionHeaderData(
            badge: strings.oneOffLandingBadge,
            title: strings.oneOffLandingTitle,
            description: strings.oneOffLandingDescription,
            buttonText: strings.oneOffLandingButton,
          ),
          pastSection: PageSectionHeaderData(
            badge: strings.oneOffPastBadge,
            title: strings.oneOffPastTitle,
            description: strings.oneOffPastDescription,
          ),
          emptyState: PageEmptyStateData(
            iconName: 'sparkles',
            title: strings.oneOffEmptyTitle,
            description: strings.oneOffEmptyDescription,
            buttonText: strings.oneOffEmptyButton,
          ),
          errorTitle: strings.oneOffErrorTitle,
          cta: PageCtaData(
            title: strings.oneOffCtaTitle,
            description: strings.oneOffCtaDescription,
            primaryButtonText: strings.oneOffCtaPrimaryButton,
            primaryButtonIcon: 'mail',
            primaryRoute: routeContact,
            secondaryButtonText: strings.oneOffCtaSecondaryButton,
            secondaryButtonIcon: 'mapPin',
            secondaryRoute: routeRinks,
          ),
          cardLabels: _cardLabels,
        );

      case PageType.iceMasters:
        return PageData(
          hero: PageHeroData(
            badge: strings.coachesHeroBadge,
            title: strings.coachesHeroTitle,
            description: strings.coachesHeroDescription,
          ),
          emptyState: PageEmptyStateData(
            iconName: 'users',
            title: strings.coachesEmptyTitle,
            description: strings.coachesEmptyDescription,
            buttonText: strings.coachesEmptyButton,
          ),
          errorTitle: strings.coachesErrorTitle,
          cardLabels: _cardLabels,
        );

      case PageType.theRinks:
        return PageData(
          hero: PageHeroData(
            badge: strings.rinksHeroBadge,
            title: strings.rinksHeroTitle,
            description: strings.rinksHeroDescription,
          ),
          emptyState: PageEmptyStateData(
            iconName: 'warehouse',
            title: strings.rinksEmptyTitle,
            description: strings.rinksEmptyDescription,
            buttonText: strings.rinksEmptyButton,
          ),
          errorTitle: strings.rinksErrorTitle,
          cta: PageCtaData(
            title: strings.rinksCtaTitle,
            description: strings.rinksCtaDescription,
            primaryButtonText: strings.rinksCtaPrimaryButton,
            primaryButtonIcon: 'mail',
            primaryRoute: routeContact,
            secondaryButtonText: strings.rinksCtaSecondaryButton,
            secondaryButtonIcon: 'graduationCap',
            secondaryRoute: routePrograms,
          ),
          cardLabels: _cardLabels,
        );

      case PageType.theClub:
        return PageData(
          hero: PageHeroData(
            badge: strings.aboutHeroBadge,
            title: strings.aboutHeroTitle,
            description: strings.aboutHeroDescription,
          ),
          activeSection: PageSectionHeaderData(
            badge: strings.aboutActiveBadge,
            title: strings.aboutActiveTitle,
            description: strings.aboutActiveDescription,
          ),
          emptyState: PageEmptyStateData(
            iconName: 'heart',
            title: strings.aboutEmptyTitle,
            description: strings.aboutEmptyDescription,
            buttonText: strings.aboutEmptyButton,
          ),
          errorTitle: strings.aboutErrorTitle,
          cta: PageCtaData(
            title: strings.aboutCtaTitle,
            description: strings.aboutCtaDescription,
            primaryButtonText: strings.aboutCtaPrimaryButton,
            primaryRoute: routeSignup,
            secondaryButtonText: strings.aboutCtaSecondaryButton,
            secondaryRoute: routeContact,
          ),
          cardLabels: _cardLabels,
        );

      case PageType.contactUs:
        return PageData(
          hero: PageHeroData(
            badge: strings.contactHeroBadge,
            title: strings.contactHeroTitle,
            description: strings.contactHeroDescription,
          ),
          emptyState: PageEmptyStateData(
            iconName: 'mail',
            title: strings.contactEmptyTitle,
            description: strings.contactEmptyDescription,
            buttonText: strings.contactEmptyButton,
          ),
          errorTitle: strings.contactErrorTitle,
          cta: PageCtaData(
            title: strings.contactCtaTitle,
            description: strings.contactCtaDescription,
            primaryButtonText: strings.contactCtaPrimaryButton,
            primaryRoute: routeSignup,
            secondaryButtonText: strings.contactCtaSecondaryButton,
            secondaryRoute: routePrograms,
          ),
          cardLabels: _cardLabels,
        );
    }
  }

  Map<String, String> get _cardLabels => {
    'viewDetails': strings.eventDetailViewDetails,
    'learnMore': strings.cardLearnMore,
    'join': strings.cardJoin,
    'joinNow': strings.cardJoinNow,
    'registerNow': strings.cardRegisterNow,
    'viewGallery': strings.eventDetailViewGallery,
    'spotsLeft': strings.cardSpotsLeft,
    'registrationOpen': strings.cardRegistrationOpen,
    'registrationClosed': strings.cardRegistrationClosed,
    'whatsIncluded': strings.campDetailWhatsIncluded,
    'pastCamp': strings.cardPastCamp,
    'past': strings.cardPast,
    'ageRangePrefix': strings.cardAgeRangePrefix,
    'venueTbd': strings.cardVenueTbd,
  };

  // ══════════════════════════════════════════════════════════════════════════
  // CONTACT PAGE LABELS
  // ══════════════════════════════════════════════════════════════════════════

  ContactPageLabels get contactLabels => ContactPageLabels(
    form: ContactFormLabels(
      title: strings.contactFormTitle,
      description: strings.contactFormDescription,
      nameLabel: strings.contactFormNameLabel,
      namePlaceholder: strings.contactFormNamePlaceholder,
      emailLabel: strings.contactFormEmailLabel,
      emailPlaceholder: strings.contactFormEmailPlaceholder,
      phoneLabel: strings.contactFormPhoneLabel,
      phonePlaceholder: strings.contactFormPhonePlaceholder,
      subjectLabel: strings.contactFormSubjectLabel,
      subjectPlaceholder: strings.contactFormSubjectPlaceholder,
      subjectOptions: ContactSubjectOptions(
        registration: strings.contactFormSubjectRegistration,
        programs: strings.contactFormSubjectPrograms,
        facility: strings.contactFormSubjectFacility,
        sponsorship: strings.contactFormSubjectSponsorship,
        other: strings.contactFormSubjectOther,
      ),
      messageLabel: strings.contactFormMessageLabel,
      messagePlaceholder: strings.contactFormMessagePlaceholder,
      submitButton: strings.contactFormSubmitButton,
    ),
    info: ContactInfoLabels(
      title: strings.contactInfoTitle,
      addressLabel: strings.contactInfoAddressLabel,
      phoneLabel: strings.contactInfoPhoneLabel,
      emailLabel: strings.contactInfoEmailLabel,
      followUsLabel: strings.contactInfoFollowUsLabel,
      qrCodeHint: strings.contactInfoQrCodeHint,
    ),
    map: ContactMapLabels(
      openInMapsButton: strings.contactMapOpenButton,
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // CLUB CONTENT
  // ══════════════════════════════════════════════════════════════════════════

  /// The About page's history and values.
  ///
  /// The club's own words rather than UI copy, so unlike everything else here
  /// they are only bundled until site#18 reads them from the server's
  /// `clubInfo`. They live in the ARB so the page is never empty in the
  /// meantime, and so a translation has somewhere to go.
  ClubInfo get clubInfo => ClubInfo(
    history: ClubHistoryData(
      paragraphs: [
        strings.clubHistoryParagraph1,
        strings.clubHistoryParagraph2,
      ],
    ),
    values: [
      ClubValueCardData(
        iconName: 'target',
        title: strings.clubValueMissionTitle,
        description: strings.clubValueMissionDescription,
      ),
      ClubValueCardData(
        iconName: 'eye',
        title: strings.clubValueVisionTitle,
        description: strings.clubValueVisionDescription,
      ),
      ClubValueCardData(
        iconName: 'heart',
        title: strings.clubValueValuesTitle,
        description: strings.clubValueValuesDescription,
      ),
    ],
  );

  // ══════════════════════════════════════════════════════════════════════════
  // NOT FOUND
  // ══════════════════════════════════════════════════════════════════════════

  /// Labels for the not-found page a detail route falls back to.
  ///
  /// Returns null for a key the site has no copy for, which is what the
  /// page's own generic fallback is there for.
  NotFoundLabels? notFound(String key) {
    switch (key) {
      case 'camp':
      case 'event':
        return NotFoundLabels(
          pageTitle: strings.notFoundCampPageTitle,
          title: strings.notFoundCampTitle,
          description: strings.notFoundCampDescription,
          buttonText: strings.notFoundCampButton,
          buttonRoute: routeCamps,
        );
      case 'program':
        return NotFoundLabels(
          pageTitle: strings.notFoundProgramPageTitle,
          title: strings.notFoundProgramTitle,
          description: strings.notFoundProgramDescription,
          buttonText: strings.notFoundProgramButton,
          buttonRoute: routePrograms,
        );
      case 'oneoff':
        return NotFoundLabels(
          pageTitle: strings.notFoundOneOffPageTitle,
          title: strings.notFoundOneOffTitle,
          description: strings.notFoundOneOffDescription,
          buttonText: strings.notFoundOneOffButton,
          buttonRoute: routeOneOff,
        );
      case 'venue':
        return NotFoundLabels(
          pageTitle: strings.notFoundVenuePageTitle,
          title: strings.notFoundVenueTitle,
          description: strings.notFoundVenueDescription,
          buttonText: strings.notFoundVenueButton,
          buttonRoute: routeRinks,
          iconName: 'mapPinOff',
        );
      default:
        return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EVENT DETAIL
  // ══════════════════════════════════════════════════════════════════════════

  /// The detail page's hero, labels and CTA for one event.
  ///
  /// The three event types share a page and differ only in wording, so this
  /// is one shape filled from three sets of strings. The old server assembled
  /// the same thing and sent it down with every event, as `detailLabels`.
  ///
  /// The hero is the event's own — its stamp, title and tagline — and is
  /// passed in rather than looked up. [ctaState] is 'available', 'closed' or
  /// 'completed'; [deadline] is the already-formatted registration deadline,
  /// which only the 'available' wording uses.
  EventDetailPageData eventDetail(
    EventType type, {
    required String title,
    required String ctaState,
    required String deadline,
    String? badge,
    String? description,
  }) {
    return EventDetailPageData(
      pageData: PageData(
        hero: PageHeroData(
          badge: badge,
          title: title,
          description: description,
        ),
        emptyState: _detailEmptyState(type),
        cta: _detailCta(type, ctaState, deadline),
        cardLabels: _detailCardLabels(type),
      ),
      labels: _detailLabels(type),
    );
  }

  PageEmptyStateData _detailEmptyState(EventType type) => switch (type) {
    EventType.camp => PageEmptyStateData(
      iconName: 'calendar',
      title: strings.campDetailEmptyTitle,
      description: strings.campDetailEmptyDescription,
      buttonText: strings.campDetailEmptyButton,
    ),
    EventType.programme => PageEmptyStateData(
      iconName: 'calendar',
      title: strings.programDetailEmptyTitle,
      description: strings.programDetailEmptyDescription,
      buttonText: strings.programDetailEmptyButton,
    ),
    EventType.oneOff => PageEmptyStateData(
      iconName: 'calendar',
      title: strings.oneOffDetailEmptyTitle,
      description: strings.oneOffDetailEmptyDescription,
      buttonText: strings.oneOffDetailEmptyButton,
    ),
  };

  Map<String, String> _detailCardLabels(EventType type) => {
    ..._cardLabels,
    'actionButton': switch (type) {
      EventType.camp => strings.campDetailActionButton,
      EventType.programme => strings.programDetailActionButton,
      EventType.oneOff => strings.oneOffDetailActionButton,
    },
    'whatsIncluded': switch (type) {
      EventType.camp => strings.campDetailWhatsIncluded,
      EventType.programme => strings.programDetailWhatsIncluded,
      EventType.oneOff => strings.oneOffDetailWhatsIncluded,
    },
  };

  PageCtaData _detailCta(EventType type, String ctaState, String deadline) {
    final listRoute = switch (type) {
      EventType.camp => routeCamps,
      EventType.programme => routePrograms,
      EventType.oneOff => routeOneOff,
    };
    final viewOthers = switch (type) {
      EventType.camp => strings.campDetailViewOthersButton,
      EventType.programme => strings.programDetailViewOthersButton,
      EventType.oneOff => strings.oneOffDetailViewOthersButton,
    };

    switch (ctaState) {
      case 'closed':
        return PageCtaData(
          title: switch (type) {
            EventType.camp => strings.campCtaClosedTitle,
            EventType.programme => strings.programCtaClosedTitle,
            EventType.oneOff => strings.oneOffCtaClosedTitle,
          },
          description: switch (type) {
            EventType.camp => strings.campCtaClosedDescription,
            EventType.programme => strings.programCtaClosedDescription,
            EventType.oneOff => strings.oneOffCtaClosedDescription,
          },
          primaryButtonText: switch (type) {
            EventType.camp => strings.campCtaClosedPrimaryButton,
            EventType.programme => strings.programCtaClosedPrimaryButton,
            EventType.oneOff => strings.oneOffCtaClosedPrimaryButton,
          },
          primaryRoute: routeContact,
          secondaryButtonText: viewOthers,
          secondaryRoute: listRoute,
        );

      case 'completed':
        // No secondary button: the primary one already points at the list.
        return PageCtaData(
          title: switch (type) {
            EventType.camp => strings.campCtaCompletedTitle,
            EventType.programme => strings.programCtaCompletedTitle,
            EventType.oneOff => strings.oneOffCtaCompletedTitle,
          },
          description: switch (type) {
            EventType.camp => strings.campCtaCompletedDescription,
            EventType.programme => strings.programCtaCompletedDescription,
            EventType.oneOff => strings.oneOffCtaCompletedDescription,
          },
          primaryButtonText: switch (type) {
            EventType.camp => strings.campCtaCompletedPrimaryButton,
            EventType.programme => strings.programCtaCompletedPrimaryButton,
            EventType.oneOff => strings.oneOffCtaCompletedPrimaryButton,
          },
          primaryRoute: listRoute,
        );

      default:
        return PageCtaData(
          title: switch (type) {
            EventType.camp => strings.campCtaAvailableTitle,
            EventType.programme => strings.programCtaAvailableTitle,
            EventType.oneOff => strings.oneOffCtaAvailableTitle,
          },
          description: switch (type) {
            EventType.camp => strings.campCtaAvailableDescription(deadline),
            // The programme wording names no deadline.
            EventType.programme => strings.programCtaAvailableDescription,
            EventType.oneOff => strings.oneOffCtaAvailableDescription(deadline),
          },
          primaryButtonText: switch (type) {
            EventType.camp => strings.campCtaAvailablePrimaryButton,
            EventType.programme => strings.programCtaAvailablePrimaryButton,
            EventType.oneOff => strings.oneOffCtaAvailablePrimaryButton,
          },
          primaryRoute: routeSignup,
          secondaryButtonText: viewOthers,
          secondaryRoute: listRoute,
        );
    }
  }

  EventDetailLabels _detailLabels(EventType type) {
    return EventDetailLabels(
      hero: EventDetailHeroLabels(
        datesLabel: switch (type) {
          EventType.camp => strings.campDetailDatesLabel,
          EventType.programme => strings.programDetailDatesLabel,
          EventType.oneOff => strings.oneOffDetailDatesLabel,
        },
        timingsLabel: switch (type) {
          EventType.camp => strings.campDetailTimingsLabel,
          EventType.programme => strings.programDetailTimingsLabel,
          EventType.oneOff => strings.oneOffDetailTimingsLabel,
        },
        venueLabel: switch (type) {
          EventType.camp => strings.campDetailVenueLabel,
          EventType.programme => strings.programDetailVenueLabel,
          EventType.oneOff => strings.oneOffDetailVenueLabel,
        },
        eligibilityLabel: switch (type) {
          EventType.camp => strings.campDetailEligibilityLabel,
          EventType.programme => strings.programDetailEligibilityLabel,
          EventType.oneOff => strings.oneOffDetailEligibilityLabel,
        },
      ),
      highlights: EventDetailHighlightsLabels(
        titleActive: switch (type) {
          EventType.camp => strings.campDetailHighlightsActive,
          EventType.programme => strings.programDetailHighlightsActive,
          EventType.oneOff => strings.oneOffDetailHighlightsActive,
        },
        titlePast: switch (type) {
          EventType.camp => strings.campDetailHighlightsPast,
          EventType.programme => strings.programDetailHighlightsPast,
          EventType.oneOff => strings.oneOffDetailHighlightsPast,
        },
      ),
      coach: EventDetailCoachLabels(
        labelActive: switch (type) {
          EventType.camp => strings.campDetailCoachActive,
          EventType.programme => strings.programDetailCoachActive,
          EventType.oneOff => strings.oneOffDetailCoachActive,
        },
        labelPast: switch (type) {
          EventType.camp => strings.campDetailCoachPast,
          EventType.programme => strings.programDetailCoachPast,
          EventType.oneOff => strings.oneOffDetailCoachPast,
        },
      ),
      fees: EventDetailFeesLabels(
        title: switch (type) {
          EventType.camp => strings.campDetailFeesTitle,
          EventType.programme => strings.programDetailFeesTitle,
          EventType.oneOff => strings.oneOffDetailFeesTitle,
        },
        includesLabel: switch (type) {
          EventType.camp => strings.campDetailIncludesLabel,
          EventType.programme => strings.programDetailIncludesLabel,
          EventType.oneOff => strings.oneOffDetailIncludesLabel,
        },
      ),
      feeStructure: EventDetailFeeStructureLabels(
        title: strings.eventDetailFeeStructureTitle,
        feeTypeHeader: strings.eventDetailFeeTypeHeader,
        periodHeader: strings.eventDetailPeriodHeader,
        amountHeader: strings.eventDetailAmountHeader,
        totalLabel: strings.eventDetailTotalLabel,
      ),
      batchTimings: EventDetailBatchTimingsLabels(
        title: switch (type) {
          EventType.camp => strings.campDetailTimetableTitle,
          EventType.programme => strings.programDetailTimetableTitle,
          EventType.oneOff => strings.oneOffDetailTimetableTitle,
        },
        batchHeader: switch (type) {
          EventType.camp => strings.campDetailTimetableSlotHeader,
          EventType.programme => strings.programDetailTimetableSlotHeader,
          EventType.oneOff => strings.oneOffDetailTimetableSlotHeader,
        },
        timeHeader: strings.eventDetailTimeHeader,
        sessionHeader: switch (type) {
          EventType.camp => strings.campDetailTimetableActivityHeader,
          EventType.programme => strings.programDetailTimetableActivityHeader,
          EventType.oneOff => strings.oneOffDetailTimetableActivityHeader,
        },
        detailsHeader: strings.eventDetailDetailsHeader,
      ),
      facilities: EventDetailFacilitiesLabels(
        title: strings.eventDetailFacilitiesTitle,
      ),
      packages: EventDetailPackagesLabels(
        title: switch (type) {
          EventType.camp => strings.campDetailPackagesTitle,
          EventType.programme => strings.programDetailPackagesTitle,
          EventType.oneOff => strings.oneOffDetailPackagesTitle,
        },
        subtitle: switch (type) {
          EventType.camp => strings.campDetailPackagesSubtitle,
          EventType.programme => strings.programDetailPackagesSubtitle,
          EventType.oneOff => strings.oneOffDetailPackagesSubtitle,
        },
      ),
      offers: EventDetailOffersLabels(
        title: strings.eventDetailOffersTitle,
        validUntilPrefix: strings.eventDetailOffersValidUntilPrefix,
      ),
      eligibility: EventDetailEligibilityLabels(
        title: strings.eventDetailEligibilityTitle,
      ),
      gallery: EventDetailGalleryLabels(
        title: switch (type) {
          EventType.camp => strings.campDetailGalleryTitle,
          EventType.programme => strings.programDetailGalleryTitle,
          EventType.oneOff => strings.oneOffDetailGalleryTitle,
        },
        subtitle: switch (type) {
          EventType.camp => strings.campDetailGallerySubtitle,
          EventType.programme => strings.programDetailGallerySubtitle,
          EventType.oneOff => strings.oneOffDetailGallerySubtitle,
        },
      ),
    );
  }
}
