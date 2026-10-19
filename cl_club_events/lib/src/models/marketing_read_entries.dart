import 'package:cl_club_forms/cl_club_forms.dart' show marketingDateText;
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        Event,
        EventMarketing,
        Facility,
        FeeItem,
        PackageOffer,
        PromotionalOffer;
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'event_marketing_form_helpers.dart' show marketingLocalDay;
import 'marketing_read_entry.dart';

/// What each card of the Marketing page shows while it is not being edited
/// (club_client#1).
abstract final class MarketingReadEntries {
  /// Joins the items of a list, one a line.
  static String? lines(Iterable<String>? items) {
    final all = items?.toList() ?? const <String>[];
    return all.isEmpty ? null : all.join('\n');
  }

  /// An amount in rupees.
  static String rupees(int amount) => '₹$amount';

  /// The basic block of [event].
  static List<MarketingReadEntry> basic(Event event) => [
    (
      icon: LucideIcons.text,
      label: 'Short description',
      value: event.shortDescription,
    ),
    (icon: LucideIcons.stamp, label: 'Stamp', value: event.stamp),
    (
      icon: LucideIcons.sparkles,
      label: 'Highlights',
      value: lines(event.highlights),
    ),
    (icon: LucideIcons.check, label: 'Includes', value: lines(event.includes)),
  ];

  /// The details of [marketing].
  static List<MarketingReadEntry> details(EventMarketing marketing) {
    final deadline = marketingLocalDay(marketing.registrationDeadlineUtc);
    return [
      (
        icon: LucideIcons.clock,
        label: 'Duration',
        value: marketing.durationText,
      ),
      (
        icon: LucideIcons.calendarClock,
        label: 'Schedule',
        value: marketing.scheduleText,
      ),
      (
        icon: LucideIcons.userCheck,
        label: 'Eligibility',
        value: marketing.eligibilityText,
      ),
      (
        icon: LucideIcons.info,
        label: 'Eligibility note',
        value: marketing.eligibilityNote,
      ),
      (
        icon: LucideIcons.calendarX,
        label: 'Registration deadline',
        value: deadline == null ? null : marketingDateText(deadline),
      ),
      (
        icon: LucideIcons.users,
        label: 'Places',
        value: switch (marketing.hasOpenSlots) {
          true => 'Places open',
          false => 'Full',
          null => null,
        },
      ),
      (
        icon: LucideIcons.alarmClock,
        label: 'Urgency',
        value: marketing.urgencyText,
      ),
      (
        icon: LucideIcons.phone,
        label: 'Contact number',
        value: marketing.contactNumber,
      ),
    ];
  }

  /// The fees of [marketing].
  static List<MarketingReadEntry> fees(EventMarketing marketing) {
    final fee = marketing.fee;
    return [
      (
        icon: LucideIcons.indianRupee,
        label: 'Fee',
        value: fee == null ? null : rupees(fee),
      ),
      (
        icon: LucideIcons.receipt,
        label: 'Fee structure',
        value: lines([
          for (final item in marketing.feeStructure ?? const <FeeItem>[])
            [
              item.name,
              rupees(item.amount),
              if (item.period != null) item.period!,
            ].join(' · '),
        ]),
      ),
    ];
  }

  /// The packages of [marketing].
  static List<MarketingReadEntry> packages(EventMarketing marketing) => [
    (
      icon: LucideIcons.package,
      label: 'Packages',
      value: lines([
        for (final package in marketing.packageOffers ?? const <PackageOffer>[])
          '${package.name} · ${rupees(package.price)}',
      ]),
    ),
  ];

  /// The offers of [marketing].
  static List<MarketingReadEntry> offers(EventMarketing marketing) => [
    (
      icon: LucideIcons.tag,
      label: 'Offers',
      value: lines([
        for (final offer in marketing.offers ?? const <PromotionalOffer>[])
          switch (marketingLocalDay(offer.validUntilUtc)) {
            final until? =>
              '${offer.title} · until ${marketingDateText(until)}',
            null => offer.title,
          },
      ]),
    ),
  ];

  /// The club membership of [marketing].
  static List<MarketingReadEntry> membership(EventMarketing marketing) {
    final membership = marketing.clubMembership;
    return [
      (icon: LucideIcons.idCard, label: 'Title', value: membership?.title),
      (
        icon: LucideIcons.text,
        label: 'Description',
        value: membership?.description,
      ),
      (
        icon: LucideIcons.gift,
        label: 'Benefits',
        value: lines(membership?.benefits),
      ),
    ];
  }

  /// The facilities of [marketing].
  static List<MarketingReadEntry> facilities(EventMarketing marketing) => [
    (
      icon: LucideIcons.building,
      label: 'Facilities',
      value: lines([
        for (final facility in marketing.facilities ?? const <Facility>[])
          facility.name,
      ]),
    ),
  ];
}
