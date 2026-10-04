import 'package:flutter/widgets.dart';

/// The site's copy: one string per ARB key.
///
/// The text is not in this file. It is read at runtime from the host's ARB
/// (`assets/l10n/app_en.arb`) by `siteStringsProvider`, so a site changes its
/// wording by editing its own ARB, and a later language source replaces the
/// provider rather than this class. The getters give the call sites names to
/// hold on to; the host's `test/assets_test.dart` checks them against its
/// ARB, which is what a generated class used to check at compile time.
class SiteStrings {
  SiteStrings(Map<String, String> strings) : _strings = strings;

  /// Reads an ARB document: every non-`@` key with a string value.
  factory SiteStrings.fromArb(Map<String, dynamic> arb) => SiteStrings({
    for (final entry in arb.entries)
      if (!entry.key.startsWith('@') && entry.value is String)
        entry.key: entry.value as String,
  });

  final Map<String, String> _strings;

  /// The strings in scope, from the nearest [SiteStringsScope].
  static SiteStrings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SiteStringsScope>();
    assert(scope != null, 'SiteStrings.of() called outside SiteStringsScope');
    return scope!.strings;
  }

  /// A key the ARB lacks renders as the key itself: visible on the page
  /// rather than a blank, and caught by the key test before it ships.
  String _get(String key) => _strings[key] ?? key;

  String _fill(String key, Map<String, String> args) {
    var text = _get(key);
    for (final entry in args.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }

  /// Every key this class reads.
  static const keys = <String>[
    'navHome',
    'navPrograms',
    'navEvents',
    'navOneOff',
    'navCoaches',
    'navRinks',
    'navAboutUs',
    'navContactUs',
    'navMenu',
    'navMemberApp',
    'landingLearnMore',
    'landingScrollIndicator',
    'landingCarouselCamps',
    'landingCarouselPrograms',
    'landingCarouselEvents',
    'campsHeroBadge',
    'campsHeroTitle',
    'campsHeroDescription',
    'campsLandingBadge',
    'campsLandingTitle',
    'campsLandingDescription',
    'campsLandingButton',
    'campsActiveBadge',
    'campsActiveTitle',
    'campsActiveDescription',
    'campsPastBadge',
    'campsPastTitle',
    'campsPastDescription',
    'campsEmptyTitle',
    'campsEmptyDescription',
    'campsEmptyButton',
    'campsErrorTitle',
    'campsCtaTitle',
    'campsCtaDescription',
    'campsCtaPrimaryButton',
    'campsCtaSecondaryButton',
    'programsHeroBadge',
    'programsHeroTitle',
    'programsHeroDescription',
    'programsLandingBadge',
    'programsLandingTitle',
    'programsLandingDescription',
    'programsLandingButton',
    'programsActiveBadge',
    'programsActiveTitle',
    'programsActiveDescription',
    'programsEmptyTitle',
    'programsEmptyDescription',
    'programsEmptyButton',
    'programsErrorTitle',
    'programsCtaTitle',
    'programsCtaDescription',
    'programsCtaPrimaryButton',
    'programsCtaSecondaryButton',
    'oneOffHeroBadge',
    'oneOffHeroTitle',
    'oneOffHeroDescription',
    'oneOffLandingBadge',
    'oneOffLandingTitle',
    'oneOffLandingDescription',
    'oneOffLandingButton',
    'oneOffPastBadge',
    'oneOffPastTitle',
    'oneOffPastDescription',
    'oneOffEmptyTitle',
    'oneOffEmptyDescription',
    'oneOffEmptyButton',
    'oneOffErrorTitle',
    'oneOffCtaTitle',
    'oneOffCtaDescription',
    'oneOffCtaPrimaryButton',
    'oneOffCtaSecondaryButton',
    'coachesHeroBadge',
    'coachesHeroTitle',
    'coachesHeroDescription',
    'coachesEmptyTitle',
    'coachesEmptyDescription',
    'coachesEmptyButton',
    'coachesErrorTitle',
    'rinksHeroBadge',
    'rinksHeroTitle',
    'rinksHeroDescription',
    'rinksEmptyTitle',
    'rinksEmptyDescription',
    'rinksEmptyButton',
    'rinksErrorTitle',
    'rinksCtaTitle',
    'rinksCtaDescription',
    'rinksCtaPrimaryButton',
    'rinksCtaSecondaryButton',
    'aboutHeroBadge',
    'aboutHeroTitle',
    'aboutHeroDescription',
    'aboutActiveBadge',
    'aboutActiveTitle',
    'aboutActiveDescription',
    'aboutEmptyTitle',
    'aboutEmptyDescription',
    'aboutEmptyButton',
    'aboutErrorTitle',
    'aboutCtaTitle',
    'aboutCtaDescription',
    'aboutCtaPrimaryButton',
    'aboutCtaSecondaryButton',
    'contactHeroBadge',
    'contactHeroTitle',
    'contactHeroDescription',
    'contactEmptyTitle',
    'contactEmptyDescription',
    'contactEmptyButton',
    'contactErrorTitle',
    'contactCtaTitle',
    'contactCtaDescription',
    'contactCtaPrimaryButton',
    'contactCtaSecondaryButton',
    'contactFormTitle',
    'contactFormDescription',
    'contactFormNameLabel',
    'contactFormNamePlaceholder',
    'contactFormEmailLabel',
    'contactFormEmailPlaceholder',
    'contactFormPhoneLabel',
    'contactFormPhonePlaceholder',
    'contactFormSubjectLabel',
    'contactFormSubjectPlaceholder',
    'contactFormSubjectRegistration',
    'contactFormSubjectPrograms',
    'contactFormSubjectFacility',
    'contactFormSubjectSponsorship',
    'contactFormSubjectOther',
    'contactFormMessageLabel',
    'contactFormMessagePlaceholder',
    'contactFormSubmitButton',
    'contactFormSending',
    'contactFormThanksTitle',
    'contactFormThanksBody',
    'contactFormErrorRequired',
    'contactFormErrorEmail',
    'contactFormErrorRateLimited',
    'contactFormErrorGeneric',
    'interestHeroTitle',
    'interestHeroSubtitle',
    'interestFormTitle',
    'interestFormDescription',
    'interestFormMessageLabel',
    'interestFormMessagePlaceholder',
    'interestFormSubmitButton',
    'interestFormThanksTitle',
    'interestFormThanksBody',
    'interestAgeGroupLabel',
    'interestAgeGroupPlaceholder',
    'interestAgeGroupChild',
    'interestAgeGroupTeen',
    'interestAgeGroupAdult',
    'interestProgrammeLabel',
    'interestProgrammePlaceholder',
    'interestProgrammeCamps',
    'interestProgrammeTraining',
    'interestProgrammeEvents',
    'interestProgrammeUnsure',
    'contactInfoTitle',
    'contactInfoAddressLabel',
    'contactInfoPhoneLabel',
    'contactInfoWhatsappLabel',
    'contactInfoEmailLabel',
    'contactInfoFollowUsLabel',
    'contactInfoQrCodeHint',
    'contactMapOpenButton',
    'contactMapFallbackTitle',
    'notFoundCampPageTitle',
    'notFoundCampTitle',
    'notFoundCampDescription',
    'notFoundCampButton',
    'notFoundProgramPageTitle',
    'notFoundProgramTitle',
    'notFoundProgramDescription',
    'notFoundProgramButton',
    'notFoundOneOffPageTitle',
    'notFoundOneOffTitle',
    'notFoundOneOffDescription',
    'notFoundOneOffButton',
    'notFoundVenuePageTitle',
    'notFoundVenueTitle',
    'notFoundVenueDescription',
    'notFoundVenueButton',
    'eventDetailFeeStructureTitle',
    'eventDetailFeeTypeHeader',
    'eventDetailPeriodHeader',
    'eventDetailAmountHeader',
    'eventDetailTotalLabel',
    'eventDetailFacilitiesTitle',
    'eventDetailEligibilityTitle',
    'eventDetailOffersTitle',
    'eventDetailOffersValidUntilPrefix',
    'eventDetailTimeHeader',
    'eventDetailDetailsHeader',
    'eventDetailViewDetails',
    'eventDetailViewGallery',
    'campDetailDatesLabel',
    'campDetailTimingsLabel',
    'campDetailVenueLabel',
    'campDetailEligibilityLabel',
    'campDetailHighlightsActive',
    'campDetailHighlightsPast',
    'campDetailCoachActive',
    'campDetailCoachPast',
    'campDetailFeesTitle',
    'campDetailIncludesLabel',
    'campDetailTimetableTitle',
    'campDetailTimetableSlotHeader',
    'campDetailTimetableActivityHeader',
    'campDetailPackagesTitle',
    'campDetailPackagesSubtitle',
    'campDetailGalleryTitle',
    'campDetailGallerySubtitle',
    'campDetailViewOthersButton',
    'campDetailEmptyTitle',
    'campDetailEmptyDescription',
    'campDetailEmptyButton',
    'campDetailActionButton',
    'campDetailWhatsIncluded',
    'campCtaAvailableTitle',
    'campCtaAvailableDescription',
    'campCtaAvailablePrimaryButton',
    'campCtaClosedTitle',
    'campCtaClosedDescription',
    'campCtaClosedPrimaryButton',
    'campCtaCompletedTitle',
    'campCtaCompletedDescription',
    'campCtaCompletedPrimaryButton',
    'programDetailDatesLabel',
    'programDetailTimingsLabel',
    'programDetailVenueLabel',
    'programDetailEligibilityLabel',
    'programDetailHighlightsActive',
    'programDetailHighlightsPast',
    'programDetailCoachActive',
    'programDetailCoachPast',
    'programDetailFeesTitle',
    'programDetailIncludesLabel',
    'programDetailTimetableTitle',
    'programDetailTimetableSlotHeader',
    'programDetailTimetableActivityHeader',
    'programDetailPackagesTitle',
    'programDetailPackagesSubtitle',
    'programDetailGalleryTitle',
    'programDetailGallerySubtitle',
    'programDetailViewOthersButton',
    'programDetailEmptyTitle',
    'programDetailEmptyDescription',
    'programDetailEmptyButton',
    'programDetailActionButton',
    'programDetailWhatsIncluded',
    'programCtaAvailableTitle',
    'programCtaAvailableDescription',
    'programCtaAvailablePrimaryButton',
    'programCtaClosedTitle',
    'programCtaClosedDescription',
    'programCtaClosedPrimaryButton',
    'programCtaCompletedTitle',
    'programCtaCompletedDescription',
    'programCtaCompletedPrimaryButton',
    'oneOffDetailDatesLabel',
    'oneOffDetailTimingsLabel',
    'oneOffDetailVenueLabel',
    'oneOffDetailEligibilityLabel',
    'oneOffDetailHighlightsActive',
    'oneOffDetailHighlightsPast',
    'oneOffDetailCoachActive',
    'oneOffDetailCoachPast',
    'oneOffDetailFeesTitle',
    'oneOffDetailIncludesLabel',
    'oneOffDetailTimetableTitle',
    'oneOffDetailTimetableSlotHeader',
    'oneOffDetailTimetableActivityHeader',
    'oneOffDetailPackagesTitle',
    'oneOffDetailPackagesSubtitle',
    'oneOffDetailGalleryTitle',
    'oneOffDetailGallerySubtitle',
    'oneOffDetailViewOthersButton',
    'oneOffDetailEmptyTitle',
    'oneOffDetailEmptyDescription',
    'oneOffDetailEmptyButton',
    'oneOffDetailActionButton',
    'oneOffDetailWhatsIncluded',
    'oneOffCtaAvailableTitle',
    'oneOffCtaAvailableDescription',
    'oneOffCtaAvailablePrimaryButton',
    'oneOffCtaClosedTitle',
    'oneOffCtaClosedDescription',
    'oneOffCtaClosedPrimaryButton',
    'oneOffCtaCompletedTitle',
    'oneOffCtaCompletedDescription',
    'oneOffCtaCompletedPrimaryButton',
    'cardLearnMore',
    'cardJoin',
    'cardJoinNow',
    'cardRegisterNow',
    'cardSpotsLeft',
    'cardRegistrationOpen',
    'cardRegistrationClosed',
    'cardPastCamp',
    'cardPast',
    'cardAgeRangePrefix',
    'cardVenueTbd',
    'unableToLoadPage',
    'clubHistoryParagraph1',
    'clubHistoryParagraph2',
    'clubValueMissionTitle',
    'clubValueMissionDescription',
    'clubValueVisionTitle',
    'clubValueVisionDescription',
    'clubValueValuesTitle',
    'clubValueValuesDescription',
  ];

  String get navHome => _get('navHome');
  String get navPrograms => _get('navPrograms');
  String get navEvents => _get('navEvents');
  String get navOneOff => _get('navOneOff');
  String get navCoaches => _get('navCoaches');
  String get navRinks => _get('navRinks');
  String get navAboutUs => _get('navAboutUs');
  String get navContactUs => _get('navContactUs');
  String get navMenu => _get('navMenu');
  String get navMemberApp => _get('navMemberApp');
  String get landingLearnMore => _get('landingLearnMore');
  String get landingScrollIndicator => _get('landingScrollIndicator');
  String get landingCarouselCamps => _get('landingCarouselCamps');
  String get landingCarouselPrograms => _get('landingCarouselPrograms');
  String get landingCarouselEvents => _get('landingCarouselEvents');
  String get campsHeroBadge => _get('campsHeroBadge');
  String get campsHeroTitle => _get('campsHeroTitle');
  String get campsHeroDescription => _get('campsHeroDescription');
  String get campsLandingBadge => _get('campsLandingBadge');
  String get campsLandingTitle => _get('campsLandingTitle');
  String get campsLandingDescription => _get('campsLandingDescription');
  String get campsLandingButton => _get('campsLandingButton');
  String get campsActiveBadge => _get('campsActiveBadge');
  String get campsActiveTitle => _get('campsActiveTitle');
  String get campsActiveDescription => _get('campsActiveDescription');
  String get campsPastBadge => _get('campsPastBadge');
  String get campsPastTitle => _get('campsPastTitle');
  String get campsPastDescription => _get('campsPastDescription');
  String get campsEmptyTitle => _get('campsEmptyTitle');
  String get campsEmptyDescription => _get('campsEmptyDescription');
  String get campsEmptyButton => _get('campsEmptyButton');
  String get campsErrorTitle => _get('campsErrorTitle');
  String get campsCtaTitle => _get('campsCtaTitle');
  String get campsCtaDescription => _get('campsCtaDescription');
  String get campsCtaPrimaryButton => _get('campsCtaPrimaryButton');
  String get campsCtaSecondaryButton => _get('campsCtaSecondaryButton');
  String get programsHeroBadge => _get('programsHeroBadge');
  String get programsHeroTitle => _get('programsHeroTitle');
  String get programsHeroDescription => _get('programsHeroDescription');
  String get programsLandingBadge => _get('programsLandingBadge');
  String get programsLandingTitle => _get('programsLandingTitle');
  String get programsLandingDescription => _get('programsLandingDescription');
  String get programsLandingButton => _get('programsLandingButton');
  String get programsActiveBadge => _get('programsActiveBadge');
  String get programsActiveTitle => _get('programsActiveTitle');
  String get programsActiveDescription => _get('programsActiveDescription');
  String get programsEmptyTitle => _get('programsEmptyTitle');
  String get programsEmptyDescription => _get('programsEmptyDescription');
  String get programsEmptyButton => _get('programsEmptyButton');
  String get programsErrorTitle => _get('programsErrorTitle');
  String get programsCtaTitle => _get('programsCtaTitle');
  String get programsCtaDescription => _get('programsCtaDescription');
  String get programsCtaPrimaryButton => _get('programsCtaPrimaryButton');
  String get programsCtaSecondaryButton => _get('programsCtaSecondaryButton');
  String get oneOffHeroBadge => _get('oneOffHeroBadge');
  String get oneOffHeroTitle => _get('oneOffHeroTitle');
  String get oneOffHeroDescription => _get('oneOffHeroDescription');
  String get oneOffLandingBadge => _get('oneOffLandingBadge');
  String get oneOffLandingTitle => _get('oneOffLandingTitle');
  String get oneOffLandingDescription => _get('oneOffLandingDescription');
  String get oneOffLandingButton => _get('oneOffLandingButton');
  String get oneOffPastBadge => _get('oneOffPastBadge');
  String get oneOffPastTitle => _get('oneOffPastTitle');
  String get oneOffPastDescription => _get('oneOffPastDescription');
  String get oneOffEmptyTitle => _get('oneOffEmptyTitle');
  String get oneOffEmptyDescription => _get('oneOffEmptyDescription');
  String get oneOffEmptyButton => _get('oneOffEmptyButton');
  String get oneOffErrorTitle => _get('oneOffErrorTitle');
  String get oneOffCtaTitle => _get('oneOffCtaTitle');
  String get oneOffCtaDescription => _get('oneOffCtaDescription');
  String get oneOffCtaPrimaryButton => _get('oneOffCtaPrimaryButton');
  String get oneOffCtaSecondaryButton => _get('oneOffCtaSecondaryButton');
  String get coachesHeroBadge => _get('coachesHeroBadge');
  String get coachesHeroTitle => _get('coachesHeroTitle');
  String get coachesHeroDescription => _get('coachesHeroDescription');
  String get coachesEmptyTitle => _get('coachesEmptyTitle');
  String get coachesEmptyDescription => _get('coachesEmptyDescription');
  String get coachesEmptyButton => _get('coachesEmptyButton');
  String get coachesErrorTitle => _get('coachesErrorTitle');
  String get rinksHeroBadge => _get('rinksHeroBadge');
  String get rinksHeroTitle => _get('rinksHeroTitle');
  String get rinksHeroDescription => _get('rinksHeroDescription');
  String get rinksEmptyTitle => _get('rinksEmptyTitle');
  String get rinksEmptyDescription => _get('rinksEmptyDescription');
  String get rinksEmptyButton => _get('rinksEmptyButton');
  String get rinksErrorTitle => _get('rinksErrorTitle');
  String get rinksCtaTitle => _get('rinksCtaTitle');
  String get rinksCtaDescription => _get('rinksCtaDescription');
  String get rinksCtaPrimaryButton => _get('rinksCtaPrimaryButton');
  String get rinksCtaSecondaryButton => _get('rinksCtaSecondaryButton');
  String get aboutHeroBadge => _get('aboutHeroBadge');
  String get aboutHeroTitle => _get('aboutHeroTitle');
  String get aboutHeroDescription => _get('aboutHeroDescription');
  String get aboutActiveBadge => _get('aboutActiveBadge');
  String get aboutActiveTitle => _get('aboutActiveTitle');
  String get aboutActiveDescription => _get('aboutActiveDescription');
  String get aboutEmptyTitle => _get('aboutEmptyTitle');
  String get aboutEmptyDescription => _get('aboutEmptyDescription');
  String get aboutEmptyButton => _get('aboutEmptyButton');
  String get aboutErrorTitle => _get('aboutErrorTitle');
  String get aboutCtaTitle => _get('aboutCtaTitle');
  String get aboutCtaDescription => _get('aboutCtaDescription');
  String get aboutCtaPrimaryButton => _get('aboutCtaPrimaryButton');
  String get aboutCtaSecondaryButton => _get('aboutCtaSecondaryButton');
  String get contactHeroBadge => _get('contactHeroBadge');
  String get contactHeroTitle => _get('contactHeroTitle');
  String get contactHeroDescription => _get('contactHeroDescription');
  String get contactEmptyTitle => _get('contactEmptyTitle');
  String get contactEmptyDescription => _get('contactEmptyDescription');
  String get contactEmptyButton => _get('contactEmptyButton');
  String get contactErrorTitle => _get('contactErrorTitle');
  String get contactCtaTitle => _get('contactCtaTitle');
  String get contactCtaDescription => _get('contactCtaDescription');
  String get contactCtaPrimaryButton => _get('contactCtaPrimaryButton');
  String get contactCtaSecondaryButton => _get('contactCtaSecondaryButton');
  String get contactFormTitle => _get('contactFormTitle');
  String get contactFormDescription => _get('contactFormDescription');
  String get contactFormNameLabel => _get('contactFormNameLabel');
  String get contactFormNamePlaceholder => _get('contactFormNamePlaceholder');
  String get contactFormEmailLabel => _get('contactFormEmailLabel');
  String get contactFormEmailPlaceholder => _get('contactFormEmailPlaceholder');
  String get contactFormPhoneLabel => _get('contactFormPhoneLabel');
  String get contactFormPhonePlaceholder => _get('contactFormPhonePlaceholder');
  String get contactFormSubjectLabel => _get('contactFormSubjectLabel');
  String get contactFormSubjectPlaceholder =>
      _get('contactFormSubjectPlaceholder');
  String get contactFormSubjectRegistration =>
      _get('contactFormSubjectRegistration');
  String get contactFormSubjectPrograms => _get('contactFormSubjectPrograms');
  String get contactFormSubjectFacility => _get('contactFormSubjectFacility');
  String get contactFormSubjectSponsorship =>
      _get('contactFormSubjectSponsorship');
  String get contactFormSubjectOther => _get('contactFormSubjectOther');
  String get contactFormMessageLabel => _get('contactFormMessageLabel');
  String get contactFormMessagePlaceholder =>
      _get('contactFormMessagePlaceholder');
  String get contactFormSubmitButton => _get('contactFormSubmitButton');
  String get contactFormSending => _get('contactFormSending');
  String get contactFormThanksTitle => _get('contactFormThanksTitle');
  String get contactFormThanksBody => _get('contactFormThanksBody');
  String get contactFormErrorRequired => _get('contactFormErrorRequired');
  String get contactFormErrorEmail => _get('contactFormErrorEmail');
  String get contactFormErrorRateLimited => _get('contactFormErrorRateLimited');
  String get contactFormErrorGeneric => _get('contactFormErrorGeneric');
  String get interestHeroTitle => _get('interestHeroTitle');
  String get interestHeroSubtitle => _get('interestHeroSubtitle');
  String get interestFormTitle => _get('interestFormTitle');
  String get interestFormDescription => _get('interestFormDescription');
  String get interestFormMessageLabel => _get('interestFormMessageLabel');
  String get interestFormMessagePlaceholder =>
      _get('interestFormMessagePlaceholder');
  String get interestFormSubmitButton => _get('interestFormSubmitButton');
  String get interestFormThanksTitle => _get('interestFormThanksTitle');
  String get interestFormThanksBody => _get('interestFormThanksBody');
  String get interestAgeGroupLabel => _get('interestAgeGroupLabel');
  String get interestAgeGroupPlaceholder => _get('interestAgeGroupPlaceholder');
  String get interestAgeGroupChild => _get('interestAgeGroupChild');
  String get interestAgeGroupTeen => _get('interestAgeGroupTeen');
  String get interestAgeGroupAdult => _get('interestAgeGroupAdult');
  String get interestProgrammeLabel => _get('interestProgrammeLabel');
  String get interestProgrammePlaceholder =>
      _get('interestProgrammePlaceholder');
  String get interestProgrammeCamps => _get('interestProgrammeCamps');
  String get interestProgrammeTraining => _get('interestProgrammeTraining');
  String get interestProgrammeEvents => _get('interestProgrammeEvents');
  String get interestProgrammeUnsure => _get('interestProgrammeUnsure');
  String get contactInfoTitle => _get('contactInfoTitle');
  String get contactInfoAddressLabel => _get('contactInfoAddressLabel');
  String get contactInfoPhoneLabel => _get('contactInfoPhoneLabel');
  String get contactInfoWhatsappLabel => _get('contactInfoWhatsappLabel');
  String get contactInfoEmailLabel => _get('contactInfoEmailLabel');
  String get contactInfoFollowUsLabel => _get('contactInfoFollowUsLabel');
  String get contactInfoQrCodeHint => _get('contactInfoQrCodeHint');
  String get contactMapOpenButton => _get('contactMapOpenButton');
  String get contactMapFallbackTitle => _get('contactMapFallbackTitle');
  String get notFoundCampPageTitle => _get('notFoundCampPageTitle');
  String get notFoundCampTitle => _get('notFoundCampTitle');
  String get notFoundCampDescription => _get('notFoundCampDescription');
  String get notFoundCampButton => _get('notFoundCampButton');
  String get notFoundProgramPageTitle => _get('notFoundProgramPageTitle');
  String get notFoundProgramTitle => _get('notFoundProgramTitle');
  String get notFoundProgramDescription => _get('notFoundProgramDescription');
  String get notFoundProgramButton => _get('notFoundProgramButton');
  String get notFoundOneOffPageTitle => _get('notFoundOneOffPageTitle');
  String get notFoundOneOffTitle => _get('notFoundOneOffTitle');
  String get notFoundOneOffDescription => _get('notFoundOneOffDescription');
  String get notFoundOneOffButton => _get('notFoundOneOffButton');
  String get notFoundVenuePageTitle => _get('notFoundVenuePageTitle');
  String get notFoundVenueTitle => _get('notFoundVenueTitle');
  String get notFoundVenueDescription => _get('notFoundVenueDescription');
  String get notFoundVenueButton => _get('notFoundVenueButton');
  String get eventDetailFeeStructureTitle =>
      _get('eventDetailFeeStructureTitle');
  String get eventDetailFeeTypeHeader => _get('eventDetailFeeTypeHeader');
  String get eventDetailPeriodHeader => _get('eventDetailPeriodHeader');
  String get eventDetailAmountHeader => _get('eventDetailAmountHeader');
  String get eventDetailTotalLabel => _get('eventDetailTotalLabel');
  String get eventDetailFacilitiesTitle => _get('eventDetailFacilitiesTitle');
  String get eventDetailEligibilityTitle => _get('eventDetailEligibilityTitle');
  String get eventDetailOffersTitle => _get('eventDetailOffersTitle');
  String get eventDetailOffersValidUntilPrefix =>
      _get('eventDetailOffersValidUntilPrefix');
  String get eventDetailTimeHeader => _get('eventDetailTimeHeader');
  String get eventDetailDetailsHeader => _get('eventDetailDetailsHeader');
  String get eventDetailViewDetails => _get('eventDetailViewDetails');
  String get eventDetailViewGallery => _get('eventDetailViewGallery');
  String get campDetailDatesLabel => _get('campDetailDatesLabel');
  String get campDetailTimingsLabel => _get('campDetailTimingsLabel');
  String get campDetailVenueLabel => _get('campDetailVenueLabel');
  String get campDetailEligibilityLabel => _get('campDetailEligibilityLabel');
  String get campDetailHighlightsActive => _get('campDetailHighlightsActive');
  String get campDetailHighlightsPast => _get('campDetailHighlightsPast');
  String get campDetailCoachActive => _get('campDetailCoachActive');
  String get campDetailCoachPast => _get('campDetailCoachPast');
  String get campDetailFeesTitle => _get('campDetailFeesTitle');
  String get campDetailIncludesLabel => _get('campDetailIncludesLabel');
  String get campDetailTimetableTitle => _get('campDetailTimetableTitle');
  String get campDetailTimetableSlotHeader =>
      _get('campDetailTimetableSlotHeader');
  String get campDetailTimetableActivityHeader =>
      _get('campDetailTimetableActivityHeader');
  String get campDetailPackagesTitle => _get('campDetailPackagesTitle');
  String get campDetailPackagesSubtitle => _get('campDetailPackagesSubtitle');
  String get campDetailGalleryTitle => _get('campDetailGalleryTitle');
  String get campDetailGallerySubtitle => _get('campDetailGallerySubtitle');
  String get campDetailViewOthersButton => _get('campDetailViewOthersButton');
  String get campDetailEmptyTitle => _get('campDetailEmptyTitle');
  String get campDetailEmptyDescription => _get('campDetailEmptyDescription');
  String get campDetailEmptyButton => _get('campDetailEmptyButton');
  String get campDetailActionButton => _get('campDetailActionButton');
  String get campDetailWhatsIncluded => _get('campDetailWhatsIncluded');
  String get campCtaAvailableTitle => _get('campCtaAvailableTitle');
  String campCtaAvailableDescription(String deadline) =>
      _fill('campCtaAvailableDescription', {'deadline': deadline});
  String get campCtaAvailablePrimaryButton =>
      _get('campCtaAvailablePrimaryButton');
  String get campCtaClosedTitle => _get('campCtaClosedTitle');
  String get campCtaClosedDescription => _get('campCtaClosedDescription');
  String get campCtaClosedPrimaryButton => _get('campCtaClosedPrimaryButton');
  String get campCtaCompletedTitle => _get('campCtaCompletedTitle');
  String get campCtaCompletedDescription => _get('campCtaCompletedDescription');
  String get campCtaCompletedPrimaryButton =>
      _get('campCtaCompletedPrimaryButton');
  String get programDetailDatesLabel => _get('programDetailDatesLabel');
  String get programDetailTimingsLabel => _get('programDetailTimingsLabel');
  String get programDetailVenueLabel => _get('programDetailVenueLabel');
  String get programDetailEligibilityLabel =>
      _get('programDetailEligibilityLabel');
  String get programDetailHighlightsActive =>
      _get('programDetailHighlightsActive');
  String get programDetailHighlightsPast => _get('programDetailHighlightsPast');
  String get programDetailCoachActive => _get('programDetailCoachActive');
  String get programDetailCoachPast => _get('programDetailCoachPast');
  String get programDetailFeesTitle => _get('programDetailFeesTitle');
  String get programDetailIncludesLabel => _get('programDetailIncludesLabel');
  String get programDetailTimetableTitle => _get('programDetailTimetableTitle');
  String get programDetailTimetableSlotHeader =>
      _get('programDetailTimetableSlotHeader');
  String get programDetailTimetableActivityHeader =>
      _get('programDetailTimetableActivityHeader');
  String get programDetailPackagesTitle => _get('programDetailPackagesTitle');
  String get programDetailPackagesSubtitle =>
      _get('programDetailPackagesSubtitle');
  String get programDetailGalleryTitle => _get('programDetailGalleryTitle');
  String get programDetailGallerySubtitle =>
      _get('programDetailGallerySubtitle');
  String get programDetailViewOthersButton =>
      _get('programDetailViewOthersButton');
  String get programDetailEmptyTitle => _get('programDetailEmptyTitle');
  String get programDetailEmptyDescription =>
      _get('programDetailEmptyDescription');
  String get programDetailEmptyButton => _get('programDetailEmptyButton');
  String get programDetailActionButton => _get('programDetailActionButton');
  String get programDetailWhatsIncluded => _get('programDetailWhatsIncluded');
  String get programCtaAvailableTitle => _get('programCtaAvailableTitle');
  String get programCtaAvailableDescription =>
      _get('programCtaAvailableDescription');
  String get programCtaAvailablePrimaryButton =>
      _get('programCtaAvailablePrimaryButton');
  String get programCtaClosedTitle => _get('programCtaClosedTitle');
  String get programCtaClosedDescription => _get('programCtaClosedDescription');
  String get programCtaClosedPrimaryButton =>
      _get('programCtaClosedPrimaryButton');
  String get programCtaCompletedTitle => _get('programCtaCompletedTitle');
  String get programCtaCompletedDescription =>
      _get('programCtaCompletedDescription');
  String get programCtaCompletedPrimaryButton =>
      _get('programCtaCompletedPrimaryButton');
  String get oneOffDetailDatesLabel => _get('oneOffDetailDatesLabel');
  String get oneOffDetailTimingsLabel => _get('oneOffDetailTimingsLabel');
  String get oneOffDetailVenueLabel => _get('oneOffDetailVenueLabel');
  String get oneOffDetailEligibilityLabel =>
      _get('oneOffDetailEligibilityLabel');
  String get oneOffDetailHighlightsActive =>
      _get('oneOffDetailHighlightsActive');
  String get oneOffDetailHighlightsPast => _get('oneOffDetailHighlightsPast');
  String get oneOffDetailCoachActive => _get('oneOffDetailCoachActive');
  String get oneOffDetailCoachPast => _get('oneOffDetailCoachPast');
  String get oneOffDetailFeesTitle => _get('oneOffDetailFeesTitle');
  String get oneOffDetailIncludesLabel => _get('oneOffDetailIncludesLabel');
  String get oneOffDetailTimetableTitle => _get('oneOffDetailTimetableTitle');
  String get oneOffDetailTimetableSlotHeader =>
      _get('oneOffDetailTimetableSlotHeader');
  String get oneOffDetailTimetableActivityHeader =>
      _get('oneOffDetailTimetableActivityHeader');
  String get oneOffDetailPackagesTitle => _get('oneOffDetailPackagesTitle');
  String get oneOffDetailPackagesSubtitle =>
      _get('oneOffDetailPackagesSubtitle');
  String get oneOffDetailGalleryTitle => _get('oneOffDetailGalleryTitle');
  String get oneOffDetailGallerySubtitle => _get('oneOffDetailGallerySubtitle');
  String get oneOffDetailViewOthersButton =>
      _get('oneOffDetailViewOthersButton');
  String get oneOffDetailEmptyTitle => _get('oneOffDetailEmptyTitle');
  String get oneOffDetailEmptyDescription =>
      _get('oneOffDetailEmptyDescription');
  String get oneOffDetailEmptyButton => _get('oneOffDetailEmptyButton');
  String get oneOffDetailActionButton => _get('oneOffDetailActionButton');
  String get oneOffDetailWhatsIncluded => _get('oneOffDetailWhatsIncluded');
  String get oneOffCtaAvailableTitle => _get('oneOffCtaAvailableTitle');
  String oneOffCtaAvailableDescription(String deadline) =>
      _fill('oneOffCtaAvailableDescription', {'deadline': deadline});
  String get oneOffCtaAvailablePrimaryButton =>
      _get('oneOffCtaAvailablePrimaryButton');
  String get oneOffCtaClosedTitle => _get('oneOffCtaClosedTitle');
  String get oneOffCtaClosedDescription => _get('oneOffCtaClosedDescription');
  String get oneOffCtaClosedPrimaryButton =>
      _get('oneOffCtaClosedPrimaryButton');
  String get oneOffCtaCompletedTitle => _get('oneOffCtaCompletedTitle');
  String get oneOffCtaCompletedDescription =>
      _get('oneOffCtaCompletedDescription');
  String get oneOffCtaCompletedPrimaryButton =>
      _get('oneOffCtaCompletedPrimaryButton');
  String get cardLearnMore => _get('cardLearnMore');
  String get cardJoin => _get('cardJoin');
  String get cardJoinNow => _get('cardJoinNow');
  String get cardRegisterNow => _get('cardRegisterNow');
  String get cardSpotsLeft => _get('cardSpotsLeft');
  String get cardRegistrationOpen => _get('cardRegistrationOpen');
  String get cardRegistrationClosed => _get('cardRegistrationClosed');
  String get cardPastCamp => _get('cardPastCamp');
  String get cardPast => _get('cardPast');
  String get cardAgeRangePrefix => _get('cardAgeRangePrefix');
  String get cardVenueTbd => _get('cardVenueTbd');
  String get unableToLoadPage => _get('unableToLoadPage');
  String get clubHistoryParagraph1 => _get('clubHistoryParagraph1');
  String get clubHistoryParagraph2 => _get('clubHistoryParagraph2');
  String get clubValueMissionTitle => _get('clubValueMissionTitle');
  String get clubValueMissionDescription => _get('clubValueMissionDescription');
  String get clubValueVisionTitle => _get('clubValueVisionTitle');
  String get clubValueVisionDescription => _get('clubValueVisionDescription');
  String get clubValueValuesTitle => _get('clubValueValuesTitle');
  String get clubValueValuesDescription => _get('clubValueValuesDescription');
}

/// Puts a [SiteStrings] in scope for [SiteStrings.of].
class SiteStringsScope extends InheritedWidget {
  const SiteStringsScope({
    required this.strings,
    required super.child,
    super.key,
  });

  final SiteStrings strings;

  @override
  bool updateShouldNotify(SiteStringsScope oldWidget) =>
      !identical(strings, oldWidget.strings);
}
