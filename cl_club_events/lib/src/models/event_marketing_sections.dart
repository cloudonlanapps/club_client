import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventBasicMarketingFormFields,
        EventMarketingColumns,
        EventMarketingDetailsFormFields,
        EventMarketingFeesFormFields,
        EventMarketingMembershipFormFields,
        EventMarketingRowsFormFields;
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        ClubMembership,
        Event,
        EventMarketing,
        Facility,
        FeeItem,
        PackageOffer,
        PromotionalOffer;

import 'marketing_section.dart';

/// Form → SDK half of the marketing adapter (club_client#1): what each
/// marketing form's values change in the event or its extended block.
///
/// Each takes what is stored and returns it with the form's section
/// replaced, the rest left as it was. The cards save the result; the
/// preview draws it before anything is saved. A blank text or an empty
/// list is stored as none.
abstract final class EventMarketingSections {
  /// [text], or null when it is blank.
  static String? orNone(Object? text) {
    final value = (text as String?)?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  /// [items], or null when there are none.
  static List<T>? listOrNone<T>(List<T> items) => items.isEmpty ? null : items;

  /// The rows a form returned under [id].
  static List<Map<String, Object?>> rowsOf(
    Map<String, dynamic> values,
    String id,
  ) => (values[id] as List<Map<String, Object?>>?) ?? const [];

  /// The end of the [day] picked, where the app runs, as a UTC instant: a
  /// deadline or an offer holds through its last day.
  static DateTime? endOfDayUtc(Object? day) {
    if (day is! DateTime) return null;
    return DateTime(day.year, day.month, day.day, 23, 59, 59).toUtc();
  }

  /// [event] with the basic marketing form's [values].
  static Event withBasic(Event event, Map<String, dynamic> values) =>
      event.copyWith(
        shortDescription: () =>
            orNone(values[EventBasicMarketingFormFields.shortDescriptionId]),
        stamp: () => orNone(values[EventBasicMarketingFormFields.stampId]),
        highlights: () => listOrNone(
          (values[EventBasicMarketingFormFields.highlightsId]
                  as List<String>?) ??
              const <String>[],
        ),
        includes: () => listOrNone(
          (values[EventBasicMarketingFormFields.includesId] as List<String>?) ??
              const <String>[],
        ),
      );

  /// [marketing] with the details form's [values].
  static EventMarketing withDetails(
    EventMarketing marketing,
    Map<String, dynamic> values,
  ) => marketing.copyWith(
    durationText: () =>
        orNone(values[EventMarketingDetailsFormFields.durationTextId]),
    scheduleText: () =>
        orNone(values[EventMarketingDetailsFormFields.scheduleTextId]),
    eligibilityText: () =>
        orNone(values[EventMarketingDetailsFormFields.eligibilityTextId]),
    eligibilityNote: () =>
        orNone(values[EventMarketingDetailsFormFields.eligibilityNoteId]),
    urgencyText: () =>
        orNone(values[EventMarketingDetailsFormFields.urgencyTextId]),
    contactNumber: () =>
        orNone(values[EventMarketingDetailsFormFields.contactNumberId]),
    registrationDeadlineUtc: () => endOfDayUtc(
      values[EventMarketingDetailsFormFields.registrationDeadlineId],
    ),
    hasOpenSlots: () =>
        switch (values[EventMarketingDetailsFormFields.openSlotsId]) {
          EventMarketingDetailsFormFields.openSlotsOpen => true,
          EventMarketingDetailsFormFields.openSlotsFull => false,
          _ => null,
        },
  );

  /// [marketing] with the fees form's [values]. A row whose amount does not
  /// read as a number is left out.
  static EventMarketing withFees(
    EventMarketing marketing,
    Map<String, dynamic> values,
  ) => marketing.copyWith(
    fee: () => int.tryParse(
      values[EventMarketingFeesFormFields.feeId] as String? ?? '',
    ),
    feeStructure: () => listOrNone([
      for (final row in rowsOf(
        values,
        EventMarketingFeesFormFields.feeStructureId,
      ))
        if (int.tryParse(row[EventMarketingColumns.amountId] as String? ?? '')
            case final amount?)
          FeeItem(
            name: row[EventMarketingColumns.nameId]! as String,
            amount: amount,
            period: orNone(row[EventMarketingColumns.periodId]),
          ),
    ]),
  );

  /// [marketing] with the packages of a rows form's [values]; a package's
  /// features are one a line.
  static EventMarketing withPackages(
    EventMarketing marketing,
    Map<String, dynamic> values,
  ) => marketing.copyWith(
    packageOffers: () => listOrNone([
      for (final row in rowsOf(values, EventMarketingRowsFormFields.rowsId))
        if (int.tryParse(row[EventMarketingColumns.amountId] as String? ?? '')
            case final price?)
          PackageOffer(
            name: row[EventMarketingColumns.nameId]! as String,
            price: price,
            description: orNone(row[EventMarketingColumns.descriptionId]),
            features: listOrNone([
              for (final line
                  in (row[EventMarketingColumns.featuresId] as String? ?? '')
                      .split('\n'))
                if (line.trim().isNotEmpty) line.trim(),
            ]),
          ),
    ]),
  );

  /// [marketing] with the offers of a rows form's [values].
  static EventMarketing withOffers(
    EventMarketing marketing,
    Map<String, dynamic> values,
  ) => marketing.copyWith(
    offers: () => listOrNone([
      for (final row in rowsOf(values, EventMarketingRowsFormFields.rowsId))
        PromotionalOffer(
          title: row[EventMarketingColumns.titleId]! as String,
          description: orNone(row[EventMarketingColumns.descriptionId]),
          validUntilUtc: endOfDayUtc(row[EventMarketingColumns.validUntilId]),
        ),
    ]),
  );

  /// [marketing] with the facilities of a rows form's [values].
  static EventMarketing withFacilities(
    EventMarketing marketing,
    Map<String, dynamic> values,
  ) => marketing.copyWith(
    facilities: () => listOrNone([
      for (final row in rowsOf(values, EventMarketingRowsFormFields.rowsId))
        Facility(
          name: row[EventMarketingColumns.nameId]! as String,
          description: orNone(row[EventMarketingColumns.descriptionId]),
          iconName: orNone(row[EventMarketingColumns.iconId]),
        ),
    ]),
  );

  /// [marketing] with the membership form's [values]: none without a title.
  static EventMarketing withMembership(
    EventMarketing marketing,
    Map<String, dynamic> values,
  ) {
    final title = orNone(values[EventMarketingMembershipFormFields.titleId]);
    return marketing.copyWith(
      clubMembership: () => title == null
          ? null
          : ClubMembership(
              title: title,
              description: orNone(
                values[EventMarketingMembershipFormFields.descriptionId],
              ),
              benefits: listOrNone(
                (values[EventMarketingMembershipFormFields.benefitsId]
                        as List<String>?) ??
                    const <String>[],
              ),
            ),
    );
  }

  /// [marketing] with [section] given the [values] of its form; the basic
  /// section is not on the block, so it leaves [marketing] as it is.
  static EventMarketing withSection(
    EventMarketing marketing,
    MarketingSection section,
    Map<String, dynamic> values,
  ) => switch (section) {
    MarketingSection.basic => marketing,
    MarketingSection.details => withDetails(marketing, values),
    MarketingSection.fees => withFees(marketing, values),
    MarketingSection.packages => withPackages(marketing, values),
    MarketingSection.offers => withOffers(marketing, values),
    MarketingSection.membership => withMembership(marketing, values),
    MarketingSection.facilities => withFacilities(marketing, values),
  };
}
