import 'package:shadcn_ui/shadcn_ui.dart' show DateFormat;

import '../constants/evaluation_view_strings.dart';

/// The review period between the forms' local dates and the server's UTC
/// instants: a day is stored as its UTC midnight, whatever the time zone,
/// so it reads back as the same day.
abstract final class EvaluationPeriodDates {
  /// How a period day reads.
  static const String dayPattern = 'd MMM yyyy';

  /// Joins the two ends of a period.
  static const String rangeSeparator = ' – ';

  /// The UTC instant storing local [date]'s day.
  static DateTime? toUtc(DateTime? date) =>
      date == null ? null : DateTime.utc(date.year, date.month, date.day);

  /// The local date of the day stored at [utc].
  static DateTime? toLocalDate(DateTime? utc) =>
      utc == null ? null : DateTime(utc.year, utc.month, utc.day);

  /// The day stored at [utc], as read: "1 May 2026".
  static String day(DateTime utc) =>
      DateFormat(dayPattern).format(toLocalDate(utc)!);

  /// The period from [startUtc] to [endUtc] as read, or `null` when unset.
  static String? range(DateTime? startUtc, DateTime? endUtc) =>
      startUtc == null || endUtc == null
      ? null
      : '${day(startUtc)}$rangeSeparator${day(endUtc)}';

  /// A local instant's day as read (a published date).
  static String localDay(DateTime utc) =>
      DateFormat(dayPattern).format(utc.toLocal());

  /// How a moment reads in Review Info, as the profile's Account Info.
  static const String momentPattern = 'd MMM yyyy, HH:mm';

  /// The period from [startUtc] to [endUtc] as the Review Period section
  /// states it — "1 May 2026 to 31 May 2026" — or `null` when unset.
  static String? statement(DateTime? startUtc, DateTime? endUtc) =>
      startUtc == null || endUtc == null
      ? null
      : '${day(startUtc)}${EvaluationViewStrings.periodTo}${day(endUtc)}';

  /// A moment [utc] in local time, as Review Info reads it.
  static String moment(DateTime utc) =>
      DateFormat(momentPattern).format(utc.toLocal());
}
