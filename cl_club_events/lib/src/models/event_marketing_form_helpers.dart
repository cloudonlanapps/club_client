import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventBasicMarketingFormFields,
        EventMarketingColumns,
        EventMarketingDetailsFormFields,
        EventMarketingFeesFormFields,
        EventMarketingMembershipFormFields;
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        Event,
        EventMarketing,
        Facility,
        FeeItem,
        PackageOffer,
        PromotionalOffer;

/// SDK → form half of the marketing adapter (club_client#1): the initial
/// values of each marketing form, from the event (the basic block) or its
/// extended block. The form → SDK half is `EventMarketingSections`.

/// [items] as the rows of a one-column list.
List<Map<String, Object?>> marketingBulletRows(List<String>? items) => [
  for (final item in items ?? const <String>[])
    {EventMarketingColumns.textId: item},
];

/// The basic marketing form's values for [event].
Map<String, dynamic> buildEventBasicMarketingFormInitialValues(Event event) => {
  EventBasicMarketingFormFields.shortDescriptionId:
      event.shortDescription ?? '',
  EventBasicMarketingFormFields.stampId: event.stamp ?? '',
  EventBasicMarketingFormFields.highlightsId: marketingBulletRows(
    event.highlights,
  ),
  EventBasicMarketingFormFields.includesId: marketingBulletRows(
    event.includes,
  ),
};

/// The day [utc] falls on where the app runs, as the date fields hold it.
DateTime? marketingLocalDay(DateTime? utc) {
  if (utc == null) return null;
  final local = utc.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// The details form's values for [marketing].
Map<String, dynamic> buildEventMarketingDetailsFormInitialValues(
  EventMarketing marketing,
) => {
  EventMarketingDetailsFormFields.durationTextId: marketing.durationText ?? '',
  EventMarketingDetailsFormFields.scheduleTextId: marketing.scheduleText ?? '',
  EventMarketingDetailsFormFields.eligibilityTextId:
      marketing.eligibilityText ?? '',
  EventMarketingDetailsFormFields.eligibilityNoteId:
      marketing.eligibilityNote ?? '',
  EventMarketingDetailsFormFields.urgencyTextId: marketing.urgencyText ?? '',
  EventMarketingDetailsFormFields.contactNumberId:
      marketing.contactNumber ?? '',
  EventMarketingDetailsFormFields.registrationDeadlineId: marketingLocalDay(
    marketing.registrationDeadlineUtc,
  ),
  EventMarketingDetailsFormFields.openSlotsId: switch (marketing.hasOpenSlots) {
    true => EventMarketingDetailsFormFields.openSlotsOpen,
    false => EventMarketingDetailsFormFields.openSlotsFull,
    null => EventMarketingDetailsFormFields.openSlotsUnset,
  },
};

/// The fees form's values for [marketing].
Map<String, dynamic> buildEventMarketingFeesFormInitialValues(
  EventMarketing marketing,
) => {
  EventMarketingFeesFormFields.feeId: marketing.fee?.toString() ?? '',
  EventMarketingFeesFormFields.feeStructureId: [
    for (final item in marketing.feeStructure ?? const <FeeItem>[])
      {
        EventMarketingColumns.nameId: item.name,
        EventMarketingColumns.amountId: item.amount.toString(),
        EventMarketingColumns.periodId: item.period ?? '',
      },
  ],
};

/// The packages of [marketing] as rows of `EventMarketingColumns.packages`;
/// a package's features are one a line.
List<Map<String, Object?>> eventMarketingPackageRows(
  EventMarketing marketing,
) => [
  for (final package in marketing.packageOffers ?? const <PackageOffer>[])
    {
      EventMarketingColumns.nameId: package.name,
      EventMarketingColumns.amountId: package.price.toString(),
      EventMarketingColumns.descriptionId: package.description ?? '',
      EventMarketingColumns.featuresId: (package.features ?? const <String>[])
          .join(
            '\n',
          ),
    },
];

/// The offers of [marketing] as rows of `EventMarketingColumns.offers`.
List<Map<String, Object?>> eventMarketingOfferRows(EventMarketing marketing) =>
    [
      for (final offer in marketing.offers ?? const <PromotionalOffer>[])
        {
          EventMarketingColumns.titleId: offer.title,
          EventMarketingColumns.descriptionId: offer.description ?? '',
          EventMarketingColumns.validUntilId: marketingLocalDay(
            offer.validUntilUtc,
          ),
        },
    ];

/// The facilities of [marketing] as rows of
/// `EventMarketingColumns.facilities`.
List<Map<String, Object?>> eventMarketingFacilityRows(
  EventMarketing marketing,
) => [
  for (final facility in marketing.facilities ?? const <Facility>[])
    {
      EventMarketingColumns.nameId: facility.name,
      EventMarketingColumns.descriptionId: facility.description ?? '',
      EventMarketingColumns.iconId: facility.iconName ?? '',
    },
];

/// The membership form's values for [marketing].
Map<String, dynamic> buildEventMarketingMembershipFormInitialValues(
  EventMarketing marketing,
) {
  final membership = marketing.clubMembership;
  return {
    EventMarketingMembershipFormFields.titleId: membership?.title ?? '',
    EventMarketingMembershipFormFields.descriptionId:
        membership?.description ?? '',
    EventMarketingMembershipFormFields.benefitsId: marketingBulletRows(
      membership?.benefits,
    ),
  };
}
