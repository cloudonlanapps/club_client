import 'package:shadcn_ui/shadcn_ui.dart' show DateFormat;

import 'form_age.dart';

/// The one place the age-band sentence is written. The event editor, the
/// event preview, the group Eligibility section and the group card all read
/// it from here.
class AgeEligibilityText {
  const AgeEligibilityText._();

  /// Marks a member the server reports as no longer meeting the criteria.
  static const String noLongerEligible = 'No longer eligible';

  /// How a calendar date is written: "16 Jun 2007".
  static const String datePattern = 'd MMM yyyy';

  /// The main line: "Open to members aged 5 to 18", "aged 5 and over",
  /// "aged up to 18". `null` when the band has no bound.
  static String? sentence({FormAge? minAge, FormAge? maxAge}) {
    if (minAge == null && maxAge == null) return null;
    if (minAge != null && maxAge != null) {
      return 'Open to members aged ${age(minAge)} to ${age(maxAge)}';
    }
    if (minAge != null) return 'Open to members aged ${age(minAge)} and over';
    return 'Open to members aged up to ${age(maxAge!)}';
  }

  /// The line beneath: the dates of birth the server reports for the band
  /// and the day they are counted on, e.g. "Born 16 Jun 2007 – 14 Jun 2022,
  /// counted on 15 Jun 2026." `null` when the server reports no date.
  static String? window({
    DateTime? dobOnOrAfter,
    DateTime? dobOnOrBefore,
    DateTime? referenceDay,
  }) {
    final String born;
    if (dobOnOrAfter != null && dobOnOrBefore != null) {
      born = 'Born ${date(dobOnOrAfter)} – ${date(dobOnOrBefore)}';
    } else if (dobOnOrAfter != null) {
      born = 'Born on or after ${date(dobOnOrAfter)}';
    } else if (dobOnOrBefore != null) {
      born = 'Born on or before ${date(dobOnOrBefore)}';
    } else {
      return null;
    }
    if (referenceDay == null) return '$born.';
    return '$born, counted on ${date(referenceDay)}.';
  }

  /// An age in words: "5" for whole years, else every non-zero part, e.g.
  /// "5 years 6 months".
  static String age(FormAge age) {
    if (age.isWholeYears) return '${age.years}';
    return [
      if (age.years > 0) count(age.years, 'year'),
      if (age.months > 0) count(age.months, 'month'),
      if (age.days > 0) count(age.days, 'day'),
    ].join(' ');
  }

  /// "1 month", "2 months".
  static String count(int n, String unit) =>
      n == 1 ? '$n $unit' : '$n ${unit}s';

  /// A calendar date the server carries as UTC midnight, written as that
  /// calendar day whatever the device's time zone.
  static String date(DateTime day) =>
      DateFormat(datePattern).format(day.toUtc());
}
